import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { JoinMode, OccurrenceStatus } from '@prisma/client';
import { PostgisLocationService } from '../common/geo/postgis-location.service';
import { PrismaService } from '../database/prisma.service';
import { PeopleStatsService } from '../people/people-stats.service';
import { JoinModeDto } from '../routes/dto/create-occurrence.dto';
import { toFeedCard, toRoutePoint } from '../routes/occurrence.mapper';
import { SpawnOccurrenceDto } from './dto/spawn-occurrence.dto';

@Injectable()
export class TemplatesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly postgis: PostgisLocationService,
    private readonly peopleStats: PeopleStatsService,
  ) {}

  async createFromOccurrence(userId: string, occurrenceId: string) {
    const occurrence = await this.prisma.routeOccurrence.findUnique({
      where: { id: occurrenceId },
      include: { points: { orderBy: { sortOrder: 'asc' } } },
    });

    if (!occurrence) {
      throw new NotFoundException('Occurrence not found');
    }

    if (occurrence.organizerId !== userId) {
      throw new ForbiddenException('Only organizer can save template');
    }

    const template = await this.prisma.routeTemplate.create({
      data: {
        organizerId: userId,
        title: occurrence.title,
        description: occurrence.description,
        cityId: occurrence.cityId,
        formatIds: occurrence.formatIds,
        themeIds: occurrence.themeIds,
        joinMode: occurrence.joinMode,
        maxParticipants: occurrence.maxParticipants,
        isOneOnOne: occurrence.isOneOnOne,
        coverUrls: occurrence.coverUrls,
        points: {
          create: occurrence.points.map((point) => ({
            sortOrder: point.sortOrder,
            title: point.title,
            latitude: point.latitude,
            longitude: point.longitude,
            address: point.address,
            detail: point.detail,
            description: point.description,
            photoUrls: point.photoUrls,
            poiId: point.poiId,
            isStart: point.isStart,
            isFinish: point.isFinish,
          })),
        },
      },
      include: { points: { orderBy: { sortOrder: 'asc' } } },
    });

    return {
      id: template.id,
      title: template.title,
      pointCount: template.points.length,
      createdAt: template.createdAt.toISOString(),
    };
  }

  async listMine(userId: string) {
    const templates = await this.prisma.routeTemplate.findMany({
      where: { organizerId: userId },
      orderBy: { updatedAt: 'desc' },
      include: {
        city: { select: { slug: true, name: true } },
        _count: { select: { points: true } },
      },
    });

    return {
      items: templates.map((template) => ({
        id: template.id,
        title: template.title,
        cityId: template.city.slug,
        formatIds: template.formatIds,
        themeIds: template.themeIds,
        coverUrls: template.coverUrls,
        pointCount: template._count.points,
        updatedAt: template.updatedAt.toISOString(),
      })),
    };
  }

  async spawnOccurrence(
    userId: string,
    templateId: string,
    dto: SpawnOccurrenceDto,
  ) {
    const template = await this.prisma.routeTemplate.findUnique({
      where: { id: templateId },
      include: {
        points: { orderBy: { sortOrder: 'asc' } },
        city: { select: { slug: true, name: true } },
      },
    });

    if (!template) {
      throw new NotFoundException('Template not found');
    }

    if (template.organizerId !== userId) {
      throw new ForbiddenException('Only organizer can use template');
    }

    const startPoint =
      template.points.find((p) => p.isStart) ?? template.points[0];

    if (!startPoint) {
      throw new NotFoundException('Template has no points');
    }

    const joinMode =
      dto.joinMode === JoinModeDto.APPROVAL
        ? JoinMode.APPROVAL
        : dto.joinMode === JoinModeDto.AUTO
          ? JoinMode.AUTO
          : template.joinMode;
    const maxParticipants = dto.maxParticipants ?? template.maxParticipants;

    const occurrence = await this.prisma.$transaction(async (tx) => {
      const created = await tx.routeOccurrence.create({
        data: {
          templateId: template.id,
          organizerId: userId,
          cityId: template.cityId,
          title: dto.title?.trim() || template.title,
          description: template.description,
          formatIds: template.formatIds,
          themeIds: template.themeIds,
          joinMode,
          maxParticipants,
          isOneOnOne: template.isOneOnOne,
          coverUrls: template.coverUrls,
          startsAt: new Date(dto.scheduledAt),
          hideExactTime: dto.hideExactTime ?? false,
          status: OccurrenceStatus.PUBLISHED,
          startLatitude: startPoint.latitude,
          startLongitude: startPoint.longitude,
          source: 'FROM_TEMPLATE',
          points: {
            create: template.points.map((point) => ({
              sortOrder: point.sortOrder,
              title: point.title,
              latitude: point.latitude,
              longitude: point.longitude,
              address: point.address,
              detail: point.detail,
              description: point.description,
              photoUrls: point.photoUrls,
              poiId: point.poiId,
              isStart: point.isStart,
              isFinish: point.isFinish,
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
        where: { id: template.cityId },
        data: { occurrenceCount: { increment: 1 } },
      });

      return created;
    });

    void this.peopleStats.refresh();

    return {
      id: occurrence.id,
      event: toFeedCard(occurrence, userId),
      points: occurrence.points.map(toRoutePoint),
    };
  }
}
