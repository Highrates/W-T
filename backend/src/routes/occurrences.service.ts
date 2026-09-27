import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AuditAction,
  JoinMode,
  OccurrenceStatus,
  ParticipationStatus,
  Prisma,
  RouteOccurrence,
  RoutePoint,
  RouteSource,
} from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { PostgisLocationService } from '../common/geo/postgis-location.service';
import { CitiesService } from '../cities/cities.service';
import { PrismaService } from '../database/prisma.service';
import { GeoService } from '../geo/geo.service';
import { MediaPurpose } from '../media/dto/presign.dto';
import { MediaService } from '../media/media.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PeopleStatsService } from '../people/people-stats.service';
import { ParticipationService } from '../participation/participation.service';
import { ALL_FILTER_IDS } from './feed-filters';
import {
  FeedFilterCriteria,
  parseFeedFilterCriteria,
  prismaFeedFilters,
  sqlFeedFilters,
} from './feed-filter-criteria';
import {
  CreateOccurrenceDto,
  JoinModeDto,
  RouteSourceDto,
} from './dto/create-occurrence.dto';
import { FeedQueryDto, MapQueryDto } from './dto/feed-query.dto';
import {
  OccurrenceLifecycleAction,
  UpdateOccurrenceDto,
} from './dto/update-occurrence.dto';
import { AdminOccurrencesQueryDto } from './dto/admin-occurrences-query.dto';
import { toFeedCard, toMapPin, toRoutePoint } from './occurrence.mapper';

type ParticipantPreview = {
  id: string;
  name: string | null;
  avatarUrl: string | null;
};

type OccurrenceRow = RouteOccurrence & {
  city: { slug: string; name: string };
  organizer: {
    id: string;
    name: string | null;
    avatarUrl: string | null;
    phoneVerified: boolean;
    emailVerified: boolean;
  };
  points: RoutePoint[];
};

@Injectable()
export class OccurrencesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cities: CitiesService,
    private readonly geo: GeoService,
    private readonly participation: ParticipationService,
    private readonly media: MediaService,
    private readonly notifications: NotificationsService,
    private readonly audit: AuditService,
    private readonly postgis: PostgisLocationService,
    private readonly peopleStats: PeopleStatsService,
  ) {}

  async publish(userId: string, dto: CreateOccurrenceDto) {
    await this.validatePublish(userId, dto);

    const sortedPoints = [...dto.points].sort(
      (a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0),
    );

    const startPoint =
      sortedPoints.find((p) => p.isStart) ?? sortedPoints[0];
    const finishPoint =
      sortedPoints.find((p) => p.isFinish) ??
      sortedPoints[sortedPoints.length - 1];

    if (!startPoint || !finishPoint) {
      throw new BadRequestException('Start and finish points are required');
    }

    const enrichedPoints = await this.enrichPoints(sortedPoints);
    const city = await this.cities.resolveCityId(
      dto.cityId,
      startPoint.latitude,
      startPoint.longitude,
    );

    const maxParticipants = dto.isOneOnOne ? 2 : dto.maxParticipants;

    const occurrence = await this.prisma.$transaction(async (tx) => {
      const created = await tx.routeOccurrence.create({
        data: {
          organizerId: userId,
          templateId: dto.templateId,
          cityId: city.id,
          title: dto.title.trim(),
          description: dto.description.trim(),
          formatIds: dto.formatIds,
          themeIds: dto.themeIds,
          joinMode: mapJoinMode(dto.joinMode),
          maxParticipants,
          isOneOnOne: dto.isOneOnOne ?? false,
          coverUrls: this.media.normalizeToKeys(dto.coverUrls ?? []),
          startsAt: dto.scheduledAt ? new Date(dto.scheduledAt) : null,
          hideExactTime: dto.hideExactTime ?? false,
          status: OccurrenceStatus.PUBLISHED,
          startLatitude: startPoint.latitude,
          startLongitude: startPoint.longitude,
          source: mapRouteSource(dto.source),
          sourceOccurrenceId: dto.sourceOccurrenceId,
          points: {
            create: enrichedPoints.map((point, index) => ({
              sortOrder: point.sortOrder ?? index,
              title: point.title.trim(),
              latitude: point.latitude,
              longitude: point.longitude,
              address: point.address,
              detail: point.detail,
              description: point.description,
              photoUrls: this.media.normalizeToKeys(point.photoUrls ?? []),
              poiId: point.poiId,
              isStart: point.isStart ?? false,
              isFinish: point.isFinish ?? false,
            })),
          },
        },
        include: {
          city: { select: { slug: true, name: true } },
          organizer: {
            select: {
              id: true,
              name: true,
              avatarUrl: true,
              phoneVerified: true,
              emailVerified: true,
            },
          },
          points: { orderBy: { sortOrder: 'asc' } },
        },
      });

      await this.postgis.syncOccurrenceLocations(tx, created);

      await tx.city.update({
        where: { id: city.id },
        data: { occurrenceCount: { increment: 1 } },
      });

      return created;
    });

    const cardContext = await this.participation.loadContextForViewer(
      [occurrence.id],
      userId,
    );

    void this.peopleStats.refresh();

    const signed = await this.media.signOccurrenceRow(occurrence);
    const participants = await this.signParticipants(
      cardContext.participantsByOccurrence.get(signed.id),
    );

    return {
      id: signed.id,
      event: toFeedCard(signed, userId, {
        viewerParticipation: cardContext.viewerByOccurrence.get(signed.id),
        participants,
      }),
      points: signed.points.map(toRoutePoint),
    };
  }

  async getDetail(id: string, viewerId?: string) {
    const occurrence = await this.findPublishedOrOwn(id, viewerId);
    const cardContext = await this.participation.loadContextForViewer(
      [occurrence.id],
      viewerId,
    );

    const signed = await this.media.signOccurrenceRow(occurrence);
    const participants = await this.signParticipants(
      cardContext.participantsByOccurrence.get(signed.id),
    );

    return {
      event: toFeedCard(signed, viewerId, {
        viewerParticipation: cardContext.viewerByOccurrence.get(signed.id),
        participants,
      }),
      points: signed.points.map(toRoutePoint),
    };
  }

  async getFeed(query: FeedQueryDto, viewerId?: string) {
    const limit = query.limit ?? 20;
    const filters = parseFeedFilterCriteria(parseFilters(query.filters));
    const rows = await this.queryOccurrences({
      citySlug: query.cityId,
      nearLat: query.nearLat,
      nearLng: query.nearLng,
      radiusKm: query.radiusKm,
      cursor: query.cursor,
      filters,
      limit: limit + 1,
    });

    const page = rows.slice(0, limit);
    const nextCursor = rows.length > limit ? page[page.length - 1]?.id : null;

    const cardContext = await this.participation.loadContextForViewer(
      page.map((row) => row.id),
      viewerId,
    );

    const signedPage = await Promise.all(
      page.map((row) => this.media.signOccurrenceRow(row)),
    );

    const items = await Promise.all(
      signedPage.map(async (row) => {
        const participants = await this.signParticipants(
          cardContext.participantsByOccurrence.get(row.id),
        );
        return toFeedCard(row, viewerId, {
          viewerParticipation: cardContext.viewerByOccurrence.get(row.id),
          participants,
        });
      }),
    );

    return {
      items,
      nextCursor,
    };
  }

  async getMapPins(query: MapQueryDto) {
    const filters = parseFeedFilterCriteria(parseFilters(query.filters));

    if (query.bbox) {
      const parts = query.bbox.split(',').map(Number);
      if (parts.length !== 4 || parts.some(Number.isNaN)) {
        throw new BadRequestException(
          'bbox must be west,south,east,north',
        );
      }
      const [west, south, east, north] = parts;
      const rows = await this.queryOccurrencesInBbox(
        west,
        south,
        east,
        north,
        query.cityId,
        filters,
      );
      const signed = await Promise.all(
        rows.map((row) => this.media.signOccurrenceRow(row)),
      );

      return {
        pins: signed.map(toMapPin),
      };
    }

    const rows = await this.queryOccurrences({
      citySlug: query.cityId,
      nearLat: query.nearLat,
      nearLng: query.nearLng,
      radiusKm: query.radiusKm ?? 15,
      filters,
      limit: 200,
    });

    const signed = await Promise.all(
      rows.map((row) => this.media.signOccurrenceRow(row)),
    );

    return {
      pins: signed.map(toMapPin),
    };
  }

  async updateOccurrence(
    organizerId: string,
    occurrenceId: string,
    dto: UpdateOccurrenceDto,
  ) {
    const occurrence = await this.getOrganizerOccurrence(organizerId, occurrenceId);
    this.assertEditableStatus(occurrence.status);

    if (dto.coverUrls !== undefined) {
      await this.media.assertUrlsOwned(
        organizerId,
        dto.coverUrls,
        MediaPurpose.COVER,
      );
    }

    if (
      dto.maxParticipants != null &&
      dto.maxParticipants < occurrence.participantCount
    ) {
      throw new BadRequestException(
        'maxParticipants cannot be less than current participant count',
      );
    }

    const updated = await this.prisma.routeOccurrence.update({
      where: { id: occurrenceId },
      data: {
        ...(dto.title !== undefined ? { title: dto.title.trim() } : {}),
        ...(dto.description !== undefined
          ? { description: dto.description.trim() }
          : {}),
        ...(dto.scheduledAt !== undefined
          ? {
              startsAt: dto.scheduledAt ? new Date(dto.scheduledAt) : null,
            }
          : {}),
        ...(dto.hideExactTime !== undefined
          ? { hideExactTime: dto.hideExactTime }
          : {}),
        ...(dto.coverUrls !== undefined
          ? { coverUrls: this.media.normalizeToKeys(dto.coverUrls) }
          : {}),
        ...(dto.maxParticipants !== undefined
          ? { maxParticipants: dto.maxParticipants }
          : {}),
      },
      include: {
        city: { select: { slug: true, name: true } },
        organizer: {
          select: {
            id: true,
            name: true,
            avatarUrl: true,
            phoneVerified: true,
            emailVerified: true,
          },
        },
        points: { orderBy: { sortOrder: 'asc' } },
      },
    });

    const signed = await this.media.signOccurrenceRow(updated);
    return {
      event: toFeedCard(signed, organizerId, {}),
      points: signed.points.map(toRoutePoint),
    };
  }

  async applyLifecycle(
    organizerId: string,
    occurrenceId: string,
    action: OccurrenceLifecycleAction,
  ) {
    const occurrence = await this.getOrganizerOccurrence(organizerId, occurrenceId);
    return this.applyLifecycleToOccurrence(occurrence, action, {
      cancelledBy: 'organizer',
    });
  }

  async applyAdminLifecycle(
    actorId: string,
    occurrenceId: string,
    action: OccurrenceLifecycleAction,
  ) {
    const occurrence = await this.findOccurrenceOrThrow(occurrenceId);
    const result = await this.applyLifecycleToOccurrence(occurrence, action, {
      cancelledBy: 'moderator',
    });

    const auditAction = this.lifecycleAuditAction(action);
    if (auditAction) {
      await this.audit.log({
        actorId,
        action: auditAction,
        targetType: 'occurrence',
        targetId: occurrenceId,
        metadata: {
          action,
          previousStatus: occurrence.status,
        },
      });
    }

    return result;
  }

  async listForAdmin(query: AdminOccurrencesQueryDto) {
    const limit = query.limit ?? 20;
    const search = query.q?.trim();

    const where: Prisma.RouteOccurrenceWhereInput = {
      ...(query.status ? { status: query.status } : {}),
      ...(query.organizerId ? { organizerId: query.organizerId } : {}),
      ...(query.cityId
        ? {
            OR: [{ cityId: query.cityId }, { city: { slug: query.cityId } }],
          }
        : {}),
      ...(search
        ? {
            OR: [
              { title: { contains: search, mode: 'insensitive' } },
              { description: { contains: search, mode: 'insensitive' } },
              { organizer: { name: { contains: search, mode: 'insensitive' } } },
            ],
          }
        : {}),
    };

    const rows = await this.prisma.routeOccurrence.findMany({
      where,
      orderBy: [{ publishedAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      ...(query.cursor
        ? {
            cursor: { id: query.cursor },
            skip: 1,
          }
        : {}),
      include: {
        city: { select: { id: true, slug: true, name: true } },
        organizer: { select: { id: true, name: true, email: true } },
        _count: {
          select: {
            points: true,
            reports: true,
            participations: true,
          },
        },
      },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;

    const items = await Promise.all(
      page.map(async (row) => ({
        id: row.id,
        title: row.title,
        status: row.status.toLowerCase(),
        startsAt: row.startsAt?.toISOString() ?? null,
        publishedAt: row.publishedAt.toISOString(),
        coverUrl: await this.media.signOptionalRef(row.coverUrls[0] ?? null),
        city: row.city,
        organizer: row.organizer,
        participantCount: row.participantCount,
        maxParticipants: row.maxParticipants,
        isOneOnOne: row.isOneOnOne,
        formatIds: row.formatIds,
        themeIds: row.themeIds,
        counts: {
          points: row._count.points,
          reports: row._count.reports,
          participations: row._count.participations,
        },
      })),
    );

    return {
      items,
      nextCursor: hasMore ? page[page.length - 1]?.id ?? null : null,
    };
  }

  async getAdminDetail(occurrenceId: string) {
    const row = await this.prisma.routeOccurrence.findUnique({
      where: { id: occurrenceId },
      include: {
        city: { select: { id: true, slug: true, name: true } },
        organizer: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            isBlocked: true,
          },
        },
        points: { orderBy: { sortOrder: 'asc' } },
        reports: {
          orderBy: { createdAt: 'desc' },
          take: 20,
          include: {
            reporter: { select: { id: true, name: true } },
            targetUser: { select: { id: true, name: true } },
          },
        },
        _count: {
          select: {
            points: true,
            reports: true,
            participations: true,
          },
        },
      },
    });

    if (!row) {
      throw new NotFoundException('Occurrence not found');
    }

    const coverUrls = await this.media.signReadUrls(row.coverUrls);
    const points = await Promise.all(
      row.points.map(async (point) => ({
        id: point.id,
        sortOrder: point.sortOrder,
        title: point.title,
        latitude: point.latitude,
        longitude: point.longitude,
        address: point.address,
        detail: point.detail,
        description: point.description,
        isStart: point.isStart,
        isFinish: point.isFinish,
        photoUrls: await this.media.signReadUrls(point.photoUrls),
      })),
    );

    return {
      id: row.id,
      title: row.title,
      description: row.description,
      status: row.status.toLowerCase(),
      joinMode: row.joinMode.toLowerCase(),
      startsAt: row.startsAt?.toISOString() ?? null,
      hideExactTime: row.hideExactTime,
      publishedAt: row.publishedAt.toISOString(),
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
      coverUrls,
      city: row.city,
      organizer: row.organizer,
      participantCount: row.participantCount,
      maxParticipants: row.maxParticipants,
      isOneOnOne: row.isOneOnOne,
      formatIds: row.formatIds,
      themeIds: row.themeIds,
      startLatitude: row.startLatitude,
      startLongitude: row.startLongitude,
      points,
      reports: row.reports.map((report) => ({
        id: report.id,
        status: report.status.toLowerCase(),
        reason: report.reason.toLowerCase(),
        comment: report.comment,
        createdAt: report.createdAt.toISOString(),
        reporter: report.reporter,
        targetUser: report.targetUser,
      })),
      counts: {
        points: row._count.points,
        reports: row._count.reports,
        participations: row._count.participations,
      },
    };
  }

  private async applyLifecycleToOccurrence(
    occurrence: RouteOccurrence,
    action: OccurrenceLifecycleAction,
    options: { cancelledBy: 'organizer' | 'moderator' },
  ) {
    switch (action) {
      case OccurrenceLifecycleAction.CANCEL:
        return this.cancelOccurrence(occurrence, options);
      case OccurrenceLifecycleAction.HIDE:
        return this.setOccurrenceStatus(occurrence, OccurrenceStatus.HIDDEN);
      case OccurrenceLifecycleAction.REPUBLISH:
        if (occurrence.status !== OccurrenceStatus.HIDDEN) {
          throw new BadRequestException('Only hidden events can be republished');
        }
        return this.setOccurrenceStatus(occurrence, OccurrenceStatus.PUBLISHED);
      default:
        throw new BadRequestException('Unknown lifecycle action');
    }
  }

  private lifecycleAuditAction(
    action: OccurrenceLifecycleAction,
  ): AuditAction | null {
    switch (action) {
      case OccurrenceLifecycleAction.CANCEL:
        return AuditAction.OCCURRENCE_CANCELLED;
      case OccurrenceLifecycleAction.HIDE:
        return AuditAction.OCCURRENCE_HIDDEN;
      case OccurrenceLifecycleAction.REPUBLISH:
        return AuditAction.OCCURRENCE_UNHIDDEN;
      default:
        return null;
    }
  }

  private async findOccurrenceOrThrow(occurrenceId: string) {
    const occurrence = await this.prisma.routeOccurrence.findUnique({
      where: { id: occurrenceId },
    });

    if (!occurrence) {
      throw new NotFoundException('Occurrence not found');
    }

    return occurrence;
  }

  private async signParticipants(
    participants?: ParticipantPreview[],
  ): Promise<ParticipantPreview[] | undefined> {
    if (!participants) return participants;

    return Promise.all(
      participants.map(async (participant) => ({
        ...participant,
        avatarUrl: await this.media.signOptionalRef(participant.avatarUrl),
      })),
    );
  }

  private async validatePublish(userId: string, dto: CreateOccurrenceDto) {
    if (dto.formatIds.length === 0) {
      throw new BadRequestException('At least one format is required');
    }

    for (const id of [...dto.formatIds, ...dto.themeIds]) {
      if (!ALL_FILTER_IDS.has(id)) {
        throw new BadRequestException(`Unknown filter id: ${id}`);
      }
    }

    const hasStart = dto.points.some((p) => p.isStart);
    const hasFinish = dto.points.some((p) => p.isFinish);
    if (!hasStart || !hasFinish) {
      throw new BadRequestException(
        'Points must include start and finish markers',
      );
    }

    if (dto.isOneOnOne && dto.maxParticipants !== 2) {
      throw new BadRequestException('1×1 events must have maxParticipants = 2');
    }

    await this.media.assertUrlsOwned(
      userId,
      dto.coverUrls ?? [],
      MediaPurpose.COVER,
    );
    for (const point of dto.points) {
      await this.media.assertUrlsOwned(
        userId,
        point.photoUrls ?? [],
        MediaPurpose.POINT,
      );
    }
  }

  private async enrichPoints(
    points: CreateOccurrenceDto['points'],
  ): Promise<CreateOccurrenceDto['points']> {
    return Promise.all(
      points.map(async (point) => {
        if (point.address?.trim()) return point;

        try {
          const geo = await this.geo.reverseGeocode(
            point.latitude,
            point.longitude,
          );
          return {
            ...point,
            address: geo.address ?? point.address,
            title: point.title.trim() || geo.title,
          };
        } catch {
          return point;
        }
      }),
    );
  }

  private async findPublishedOrOwn(
    id: string,
    viewerId?: string,
  ): Promise<OccurrenceRow> {
    const occurrence = await this.prisma.routeOccurrence.findUnique({
      where: { id },
      include: {
        city: { select: { slug: true, name: true } },
        organizer: {
          select: {
            id: true,
            name: true,
            avatarUrl: true,
            phoneVerified: true,
            emailVerified: true,
          },
        },
        points: { orderBy: { sortOrder: 'asc' } },
      },
    });

    if (!occurrence) {
      throw new NotFoundException('Occurrence not found');
    }

    const isOwner = viewerId === occurrence.organizerId;
    if (occurrence.status !== OccurrenceStatus.PUBLISHED && !isOwner) {
      throw new NotFoundException('Occurrence not found');
    }

    return occurrence;
  }

  private async getOrganizerOccurrence(organizerId: string, occurrenceId: string) {
    const occurrence = await this.prisma.routeOccurrence.findUnique({
      where: { id: occurrenceId },
    });

    if (!occurrence) {
      throw new NotFoundException('Occurrence not found');
    }

    if (occurrence.organizerId !== organizerId) {
      throw new ForbiddenException('Only organizer can modify this event');
    }

    return occurrence;
  }

  private assertEditableStatus(status: OccurrenceStatus) {
    if (
      status === OccurrenceStatus.CANCELLED ||
      status === OccurrenceStatus.COMPLETED
    ) {
      throw new BadRequestException('Event cannot be edited in current status');
    }
  }

  private async cancelOccurrence(
    occurrence: RouteOccurrence,
    options: { cancelledBy: 'organizer' | 'moderator' },
  ): Promise<{ id: string; status: string }> {
    if (occurrence.status === OccurrenceStatus.CANCELLED) {
      return { id: occurrence.id, status: 'cancelled' };
    }

    const participants = await this.prisma.$transaction(async (tx) => {
      const active = await tx.participation.findMany({
        where: {
          occurrenceId: occurrence.id,
          status: {
            in: [ParticipationStatus.PENDING, ParticipationStatus.ACCEPTED],
          },
        },
        select: { userId: true },
      });

      await tx.routeOccurrence.update({
        where: { id: occurrence.id },
        data: { status: OccurrenceStatus.CANCELLED },
      });

      await tx.participation.updateMany({
        where: {
          occurrenceId: occurrence.id,
          status: {
            in: [ParticipationStatus.PENDING, ParticipationStatus.ACCEPTED],
          },
        },
        data: { status: ParticipationStatus.CANCELLED },
      });

      return active;
    });

    const cancelledBy =
      options.cancelledBy === 'moderator' ? 'модератором' : 'организатором';

    await Promise.allSettled(
      participants.map((row) =>
        this.notifications.notifyUser(row.userId, {
          title: 'Событие отменено',
          body: `«${occurrence.title}» отменено ${cancelledBy}`,
          data: { occurrenceId: occurrence.id },
        }),
      ),
    );

    return { id: occurrence.id, status: 'cancelled' };
  }

  private async setOccurrenceStatus(
    occurrence: RouteOccurrence,
    status: OccurrenceStatus,
  ): Promise<{ id: string; status: string }> {
    if (occurrence.status === OccurrenceStatus.CANCELLED) {
      throw new BadRequestException('Cancelled events cannot change visibility');
    }

    await this.prisma.routeOccurrence.update({
      where: { id: occurrence.id },
      data: { status },
    });

    return { id: occurrence.id, status: status.toLowerCase() };
  }

  private async queryOccurrences(params: {
    citySlug?: string;
    nearLat?: number;
    nearLng?: number;
    radiusKm?: number;
    cursor?: string;
    limit?: number;
    filters?: FeedFilterCriteria;
  }): Promise<OccurrenceRow[]> {
    const limit = params.limit ?? 20;
    const filters = params.filters ?? {
      formatIds: [],
      themeIds: [],
    };
    const filterSql = sqlFeedFilters(filters);
    const useRadius =
      params.nearLat != null &&
      params.nearLng != null &&
      params.radiusKm != null;

    if (useRadius) {
      const radiusM = params.radiusKm! * 1000;
      const ids = await this.prisma.$queryRaw<Array<{ id: string }>>`
        SELECT o.id
        FROM route_occurrences o
        INNER JOIN cities c ON c.id = o.city_id
        WHERE o.status = 'PUBLISHED'
        ${params.citySlug ? Prisma.sql`AND c.slug = ${params.citySlug}` : Prisma.empty}
        ${filterSql}
        AND ${this.postgis.withinRadius(
          Prisma.sql`o.location`,
          params.nearLng!,
          params.nearLat!,
          radiusM,
        )}
        ${params.cursor ? Prisma.sql`AND o.published_at < (SELECT published_at FROM route_occurrences WHERE id = ${params.cursor}::uuid)` : Prisma.empty}
        ORDER BY o.published_at DESC
        LIMIT ${limit}
      `;

      return this.loadOccurrencesByIds(ids.map((row) => row.id));
    }

    const where: Prisma.RouteOccurrenceWhereInput = {
      status: OccurrenceStatus.PUBLISHED,
      ...prismaFeedFilters(filters),
      ...(params.citySlug
        ? { city: { slug: params.citySlug } }
        : undefined),
      ...(params.cursor
        ? {
            publishedAt: {
              lt: (
                await this.prisma.routeOccurrence.findUnique({
                  where: { id: params.cursor },
                  select: { publishedAt: true },
                })
              )?.publishedAt,
            },
          }
        : undefined),
    };

    return this.prisma.routeOccurrence.findMany({
      where,
      orderBy: { publishedAt: 'desc' },
      take: limit,
      include: {
        city: { select: { slug: true, name: true } },
        organizer: {
          select: {
            id: true,
            name: true,
            avatarUrl: true,
            phoneVerified: true,
            emailVerified: true,
          },
        },
        points: { orderBy: { sortOrder: 'asc' } },
      },
    });
  }

  private async queryOccurrencesInBbox(
    west: number,
    south: number,
    east: number,
    north: number,
    citySlug?: string,
    filters?: FeedFilterCriteria,
  ): Promise<OccurrenceRow[]> {
    const filterSql = sqlFeedFilters(
      filters ?? { formatIds: [], themeIds: [] },
    );
    const ids = await this.prisma.$queryRaw<Array<{ id: string }>>`
      SELECT o.id
      FROM route_occurrences o
      INNER JOIN cities c ON c.id = o.city_id
      WHERE o.status = 'PUBLISHED'
      ${citySlug ? Prisma.sql`AND c.slug = ${citySlug}` : Prisma.empty}
      ${filterSql}
      AND o.location && ST_MakeEnvelope(${west}, ${south}, ${east}, ${north}, 4326)
      ORDER BY o.published_at DESC
      LIMIT 200
    `;

    return this.loadOccurrencesByIds(ids.map((row) => row.id));
  }

  private async loadOccurrencesByIds(ids: string[]): Promise<OccurrenceRow[]> {
    if (ids.length === 0) return [];

    const rows = await this.prisma.routeOccurrence.findMany({
      where: { id: { in: ids } },
      include: {
        city: { select: { slug: true, name: true } },
        organizer: {
          select: {
            id: true,
            name: true,
            avatarUrl: true,
            phoneVerified: true,
            emailVerified: true,
          },
        },
        points: { orderBy: { sortOrder: 'asc' } },
      },
    });

    const byId = new Map(rows.map((row) => [row.id, row]));
    return ids
      .map((id) => byId.get(id))
      .filter((row): row is OccurrenceRow => row != null);
  }
}

function parseFilters(raw?: string): Set<string> {
  if (!raw?.trim()) return new Set();
  return new Set(
    raw
      .split(',')
      .map((part) => part.trim())
      .filter(Boolean),
  );
}

function mapJoinMode(mode: JoinModeDto): JoinMode {
  return mode === JoinModeDto.APPROVAL ? JoinMode.APPROVAL : JoinMode.AUTO;
}

function mapRouteSource(source?: RouteSourceDto): RouteSource {
  switch (source) {
    case RouteSourceDto.FROM_PREVIOUS:
      return RouteSource.FROM_PREVIOUS;
    case RouteSourceDto.FROM_TEMPLATE:
      return RouteSource.FROM_TEMPLATE;
    default:
      return RouteSource.BLANK;
  }
}
