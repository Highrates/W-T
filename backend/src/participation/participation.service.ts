import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  JoinMode,
  OccurrenceStatus,
  ParticipationStatus,
} from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import { MediaService } from '../media/media.service';
import { NotificationsService } from '../notifications/notifications.service';
import { UpdateParticipationDto } from './dto/update-participation.dto';
import {
  initialParticipationStatus,
  JoinStatusDto,
  resolveJoinStatus,
} from './participation.mapper';

type ParticipantPreview = {
  id: string;
  name: string | null;
  avatarUrl: string | null;
};

type LockedOccurrence = {
  id: string;
  organizer_id: string;
  title: string;
  join_mode: JoinMode;
  max_participants: number;
  participant_count: number;
  status: OccurrenceStatus;
};

@Injectable()
export class ParticipationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly media: MediaService,
    private readonly notifications: NotificationsService,
  ) {}

  async join(userId: string, occurrenceId: string): Promise<{ joinStatus: JoinStatusDto }> {
    const { occurrence, participation, shouldNotify } =
      await this.prisma.$transaction(async (tx) => {
        const locked = await this.lockOccurrence(tx, occurrenceId);

        if (locked.organizer_id === userId) {
          throw new BadRequestException('Organizer cannot join own event');
        }

        const existing = await tx.participation.findUnique({
          where: {
            occurrenceId_userId: { occurrenceId, userId },
          },
        });

        if (
          existing &&
          (existing.status === ParticipationStatus.PENDING ||
            existing.status === ParticipationStatus.ACCEPTED)
        ) {
          return {
            occurrence: locked,
            participation: existing,
            shouldNotify: false,
          };
        }

        const status = initialParticipationStatus(locked.join_mode);
        const incrementsCount = status === ParticipationStatus.ACCEPTED;

        if (incrementsCount) {
          await this.incrementParticipantCount(tx, occurrenceId);
        }

        const participation = existing
          ? await tx.participation.update({
              where: { id: existing.id },
              data: { status },
            })
          : await tx.participation.create({
              data: { occurrenceId, userId, status },
            });

        const refreshed = await this.lockOccurrence(tx, occurrenceId);

        return {
          occurrence: refreshed,
          participation,
          shouldNotify: true,
        };
      });

    if (shouldNotify) {
      await this.notifyOrganizerOnJoin(
        {
          id: occurrence.id,
          organizerId: occurrence.organizer_id,
          title: occurrence.title,
          joinMode: occurrence.join_mode,
        },
        participation.status,
      );
    }

    return {
      joinStatus: resolveJoinStatus(
        this.toOccurrencePick(occurrence),
        participation,
        userId,
      ),
    };
  }

  async leave(userId: string, occurrenceId: string): Promise<{ ok: true }> {
    await this.prisma.$transaction(async (tx) => {
      await this.lockOccurrence(tx, occurrenceId);

      const participation = await tx.participation.findUnique({
        where: { occurrenceId_userId: { occurrenceId, userId } },
      });

      if (!participation) {
        throw new NotFoundException('Participation not found');
      }

      if (
        participation.status !== ParticipationStatus.PENDING &&
        participation.status !== ParticipationStatus.ACCEPTED
      ) {
        throw new BadRequestException('Participation already inactive');
      }

      await tx.participation.update({
        where: { id: participation.id },
        data: { status: ParticipationStatus.CANCELLED },
      });

      if (participation.status === ParticipationStatus.ACCEPTED) {
        await this.decrementParticipantCount(tx, occurrenceId);
      }
    });

    return { ok: true };
  }

  async listForOccurrence(organizerId: string, occurrenceId: string) {
    const occurrence = await this.prisma.routeOccurrence.findUnique({
      where: { id: occurrenceId },
      select: { organizerId: true },
    });

    if (!occurrence) {
      throw new NotFoundException('Occurrence not found');
    }

    if (occurrence.organizerId !== organizerId) {
      throw new ForbiddenException('Only organizer can view participations');
    }

    const items = await this.prisma.participation.findMany({
      where: {
        occurrenceId,
        status: {
          in: [ParticipationStatus.PENDING, ParticipationStatus.ACCEPTED],
        },
      },
      orderBy: { createdAt: 'asc' },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            avatarUrl: true,
            bio: true,
            phoneVerified: true,
            emailVerified: true,
          },
        },
      },
    });

    const mapped = await Promise.all(
      items.map(async (item) => ({
        id: item.id,
        status: item.status.toLowerCase(),
        createdAt: item.createdAt.toISOString(),
        user: {
          id: item.user.id,
          name: item.user.name,
          avatarUrl: await this.media.signOptionalRef(item.user.avatarUrl),
          bio: item.user.bio,
          isVerified: item.user.phoneVerified || item.user.emailVerified,
        },
      })),
    );

    return { items: mapped };
  }

  async updateStatus(
    organizerId: string,
    participationId: string,
    dto: UpdateParticipationDto,
  ) {
    const nextStatus =
      dto.status === 'accepted'
        ? ParticipationStatus.ACCEPTED
        : ParticipationStatus.REJECTED;

    const participation = await this.prisma.$transaction(async (tx) => {
      const row = await tx.participation.findUnique({
        where: { id: participationId },
        include: {
          occurrence: {
            select: {
              id: true,
              organizerId: true,
              title: true,
            },
          },
          user: { select: { id: true } },
        },
      });

      if (!row) {
        throw new NotFoundException('Participation not found');
      }

      if (row.occurrence.organizerId !== organizerId) {
        throw new ForbiddenException('Only organizer can update participation');
      }

      if (row.status !== ParticipationStatus.PENDING) {
        throw new BadRequestException('Only pending participations can be updated');
      }

      await this.lockOccurrence(tx, row.occurrenceId);

      if (nextStatus === ParticipationStatus.ACCEPTED) {
        await this.incrementParticipantCount(tx, row.occurrenceId);
      }

      await tx.participation.update({
        where: { id: participationId },
        data: { status: nextStatus },
      });

      return row;
    });

    const title = participation.occurrence.title;
    if (nextStatus === ParticipationStatus.ACCEPTED) {
      await this.notifications.notifyUser(participation.user.id, {
        title: 'Заявка принята',
        body: `Организатор принял вас на «${title}»`,
        data: { occurrenceId: participation.occurrenceId },
      });
    } else {
      await this.notifications.notifyUser(participation.user.id, {
        title: 'Заявка отклонена',
        body: `Организатор отклонил заявку на «${title}»`,
        data: { occurrenceId: participation.occurrenceId },
      });
    }

    return {
      id: participationId,
      status: nextStatus.toLowerCase(),
    };
  }

  async loadContextForViewer(
    occurrenceIds: string[],
    viewerId?: string,
  ): Promise<{
    viewerByOccurrence: Map<string, { status: ParticipationStatus }>;
    participantsByOccurrence: Map<string, ParticipantPreview[]>;
  }> {
    const viewerByOccurrence = new Map<string, { status: ParticipationStatus }>();
    const participantsByOccurrence = new Map<string, ParticipantPreview[]>();

    if (occurrenceIds.length === 0) {
      return { viewerByOccurrence, participantsByOccurrence };
    }

    const accepted = await this.prisma.participation.findMany({
      where: {
        occurrenceId: { in: occurrenceIds },
        status: ParticipationStatus.ACCEPTED,
      },
      include: {
        user: {
          select: { id: true, name: true, avatarUrl: true },
        },
      },
      orderBy: { createdAt: 'asc' },
    });

    for (const row of accepted) {
      const list = participantsByOccurrence.get(row.occurrenceId) ?? [];
      list.push(row.user);
      participantsByOccurrence.set(row.occurrenceId, list);
    }

    if (viewerId) {
      const mine = await this.prisma.participation.findMany({
        where: {
          occurrenceId: { in: occurrenceIds },
          userId: viewerId,
        },
        select: { occurrenceId: true, status: true },
      });

      for (const row of mine) {
        viewerByOccurrence.set(row.occurrenceId, { status: row.status });
      }
    }

    return { viewerByOccurrence, participantsByOccurrence };
  }

  async getMyParticipations(userId: string, upcoming = true) {
    const now = new Date();
    const items = await this.prisma.participation.findMany({
      where: {
        userId,
        status: {
          in: [ParticipationStatus.PENDING, ParticipationStatus.ACCEPTED],
        },
        occurrence: upcoming
          ? {
              status: OccurrenceStatus.PUBLISHED,
              OR: [{ startsAt: null }, { startsAt: { gte: now } }],
            }
          : {
              OR: [
                { status: { not: OccurrenceStatus.PUBLISHED } },
                { startsAt: { lt: now } },
              ],
            },
      },
      orderBy: { createdAt: 'desc' },
      include: {
        occurrence: {
          include: {
            city: { select: { slug: true, name: true } },
          },
        },
      },
    });

    const mapped = await Promise.all(
      items.map(async (item) => ({
        participationId: item.id,
        status: item.status.toLowerCase(),
        event: {
          id: item.occurrence.id,
          title: item.occurrence.title,
          coverUrl: await this.media.signOptionalRef(
            item.occurrence.coverUrls[0] ?? null,
          ),
          cityId: item.occurrence.city.slug,
          startsAt: item.occurrence.startsAt?.toISOString() ?? null,
          goingLabel: `${item.occurrence.participantCount}/${item.occurrence.maxParticipants} идут`,
        },
      })),
    );

    return { items: mapped };
  }

  private async lockOccurrence(
    tx: Parameters<Parameters<PrismaService['$transaction']>[0]>[0],
    occurrenceId: string,
  ): Promise<LockedOccurrence> {
    const rows = await tx.$queryRaw<LockedOccurrence[]>`
      SELECT
        id,
        organizer_id,
        title,
        join_mode,
        max_participants,
        participant_count,
        status
      FROM route_occurrences
      WHERE id = ${occurrenceId}::uuid
      FOR UPDATE
    `;

    const occurrence = rows[0];
    if (!occurrence || occurrence.status !== OccurrenceStatus.PUBLISHED) {
      throw new NotFoundException('Occurrence not found');
    }

    return occurrence;
  }

  private async incrementParticipantCount(
    tx: Parameters<Parameters<PrismaService['$transaction']>[0]>[0],
    occurrenceId: string,
  ): Promise<void> {
    const updated = await tx.$queryRaw<Array<{ participant_count: number }>>`
      UPDATE route_occurrences
      SET participant_count = participant_count + 1
      WHERE id = ${occurrenceId}::uuid
        AND participant_count < max_participants
      RETURNING participant_count
    `;

    if (updated.length === 0) {
      throw new BadRequestException('Event is full');
    }
  }

  private async decrementParticipantCount(
    tx: Parameters<Parameters<PrismaService['$transaction']>[0]>[0],
    occurrenceId: string,
  ): Promise<void> {
    const updated = await tx.$queryRaw<Array<{ participant_count: number }>>`
      UPDATE route_occurrences
      SET participant_count = participant_count - 1
      WHERE id = ${occurrenceId}::uuid
        AND participant_count > 0
      RETURNING participant_count
    `;

    if (updated.length === 0) {
      throw new BadRequestException('Invalid participant count');
    }
  }

  private toOccurrencePick(occurrence: LockedOccurrence) {
    return {
      organizerId: occurrence.organizer_id,
      maxParticipants: occurrence.max_participants,
      participantCount: occurrence.participant_count,
      joinMode: occurrence.join_mode,
    };
  }

  private async notifyOrganizerOnJoin(
    occurrence: { id: string; organizerId: string; title: string; joinMode: JoinMode },
    status: ParticipationStatus,
  ) {
    const body =
      status === ParticipationStatus.PENDING
        ? 'Новая заявка на участие'
        : 'Новый участник присоединился';

    await this.notifications.notifyUser(occurrence.organizerId, {
      title: occurrence.title,
      body,
      data: { occurrenceId: occurrence.id },
    });
  }
}
