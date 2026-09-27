import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditAction, OccurrenceStatus, Prisma, UserRole } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { AuthUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import { MediaPurpose } from '../media/dto/presign.dto';
import { MediaService } from '../media/media.service';
import { FILTER_LABELS } from '../routes/feed-filters';
import { toProfileEventPreview } from '../routes/occurrence.mapper';
import { AdminUpdateUserDto } from './dto/admin-update-user.dto';
import { AdminUsersQueryDto } from './dto/admin-users-query.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly media: MediaService,
    private readonly audit: AuditService,
  ) {}

  async getMe(userId: string) {
    const user = await this.findUserOrThrow(userId);
    return this.signProfile(this.toProfile(user, true));
  }

  async updateMe(userId: string, dto: UpdateUserDto) {
    if (dto.cityId) {
      const city = await this.prisma.city.findUnique({
        where: { id: dto.cityId },
      });
      if (!city) {
        throw new NotFoundException('City not found');
      }
    }

    await this.prisma.$transaction(async (tx) => {
      const data: {
        name?: string;
        bio?: string;
        cityId?: string | null;
        avatarUrl?: string | null;
      } = {};

      if (dto.name !== undefined) data.name = dto.name;
      if (dto.bio !== undefined) data.bio = dto.bio;
      if (dto.cityId !== undefined) data.cityId = dto.cityId;

      if (dto.avatarUrl !== undefined) {
        if (dto.avatarUrl == null || dto.avatarUrl.trim() === '') {
          data.avatarUrl = null;
        } else {
          await this.media.assertUrlsOwned(
            userId,
            [dto.avatarUrl],
            MediaPurpose.AVATAR,
          );
          data.avatarUrl = this.media.normalizeToKeys([dto.avatarUrl])[0];
        }
      }

      if (Object.keys(data).length > 0) {
        await tx.user.update({ where: { id: userId }, data });
      }

      if (dto.interestFilterIds !== undefined) {
        await tx.userInterest.deleteMany({ where: { userId } });
        if (dto.interestFilterIds.length > 0) {
          await tx.userInterest.createMany({
            data: dto.interestFilterIds.map((filterId) => ({
              userId,
              filterId,
            })),
          });
        }
      }
    });

    return this.getMe(userId);
  }

  async getPublicProfile(userId: string) {
    const user = await this.findUserOrThrow(userId);
    if (user.isBlocked) {
      throw new NotFoundException('User not found');
    }

    const now = new Date();
    const organized = await this.prisma.routeOccurrence.findMany({
      where: {
        organizerId: userId,
        status: OccurrenceStatus.PUBLISHED,
      },
      orderBy: { startsAt: 'asc' },
    });

    const upcoming = await Promise.all(
      organized
        .filter((o) => !o.startsAt || o.startsAt >= now)
        .map((o) =>
          this.media.signProfileEventPreview(toProfileEventPreview(o, false)),
        ),
    );

    const past = await Promise.all(
      organized
        .filter((o) => o.startsAt && o.startsAt < now)
        .map((o) =>
          this.media.signProfileEventPreview(toProfileEventPreview(o, true)),
        ),
    );

    const profile = await this.signProfile(this.toProfile(user, false));
    const interestTags = user.interests.map(
      (item) => FILTER_LABELS[item.filterId] ?? item.filterId,
    );

    return {
      ...profile,
      isVerified: user.phoneVerified || user.emailVerified,
      isOrganizer: organized.length > 0,
      interestTags,
      upcomingEvents: upcoming,
      pastEvents: past.length > 0 ? past : [],
    };
  }

  async listForAdmin(query: AdminUsersQueryDto) {
    const limit = query.limit ?? 20;
    const search = query.q?.trim();

    const where: Prisma.UserWhereInput = {
      ...(query.role ? { role: query.role } : {}),
      ...(query.isBlocked !== undefined ? { isBlocked: query.isBlocked } : {}),
      ...(search
        ? {
            OR: [
              { phone: { contains: search, mode: 'insensitive' } },
              { email: { contains: search, mode: 'insensitive' } },
              { name: { contains: search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const rows = await this.prisma.user.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      ...(query.cursor
        ? {
            cursor: { id: query.cursor },
            skip: 1,
          }
        : {}),
      include: {
        city: { select: { slug: true, name: true } },
        _count: {
          select: {
            organizedEvents: true,
            reportsReceived: true,
            reportsFiled: true,
          },
        },
      },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;

    return {
      items: page.map((user) => this.toAdminListItem(user)),
      nextCursor: hasMore ? page[page.length - 1]?.id ?? null : null,
    };
  }

  async getAdminDetail(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        city: { select: { id: true, slug: true, name: true } },
        interests: { select: { filterId: true } },
        _count: {
          select: {
            organizedEvents: true,
            participations: true,
            reportsReceived: true,
            reportsFiled: true,
            deviceTokens: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const [avatarUrl, organizedEvents, reportsReceived, reportsFiled] =
      await Promise.all([
        this.media.signOptionalRef(user.avatarUrl),
        this.prisma.routeOccurrence.findMany({
          where: { organizerId: userId },
          orderBy: [{ publishedAt: 'desc' }, { id: 'desc' }],
          take: 30,
          include: {
            city: { select: { slug: true, name: true } },
            _count: { select: { reports: true, points: true } },
          },
        }),
        this.prisma.report.findMany({
          where: { targetUserId: userId },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: 30,
          include: {
            reporter: { select: { id: true, name: true } },
            occurrence: { select: { id: true, title: true } },
          },
        }),
        this.prisma.report.findMany({
          where: { reporterId: userId },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: 30,
          include: {
            targetUser: { select: { id: true, name: true } },
            occurrence: { select: { id: true, title: true } },
          },
        }),
      ]);

    const events = await Promise.all(
      organizedEvents.map(async (event) => ({
        id: event.id,
        title: event.title,
        status: event.status.toLowerCase(),
        startsAt: event.startsAt?.toISOString() ?? null,
        publishedAt: event.publishedAt.toISOString(),
        coverUrl: await this.media.signOptionalRef(event.coverUrls[0] ?? null),
        city: event.city,
        participantCount: event.participantCount,
        maxParticipants: event.maxParticipants,
        counts: {
          reports: event._count.reports,
          points: event._count.points,
        },
      })),
    );

    return {
      id: user.id,
      phone: user.phone,
      email: user.email,
      phoneVerified: user.phoneVerified,
      emailVerified: user.emailVerified,
      name: user.name,
      avatarUrl,
      bio: user.bio,
      role: user.role.toLowerCase(),
      isBlocked: user.isBlocked,
      city: user.city,
      interestFilterIds: user.interests.map((item) => item.filterId),
      interestTags: user.interests.map(
        (item) => FILTER_LABELS[item.filterId] ?? item.filterId,
      ),
      lastActiveAt: user.lastActiveAt?.toISOString() ?? null,
      createdAt: user.createdAt.toISOString(),
      updatedAt: user.updatedAt.toISOString(),
      counts: {
        organizedEvents: user._count.organizedEvents,
        participations: user._count.participations,
        reportsReceived: user._count.reportsReceived,
        reportsFiled: user._count.reportsFiled,
        deviceTokens: user._count.deviceTokens,
      },
      organizedEvents: events,
      reportsReceived: reportsReceived.map((report) => ({
        id: report.id,
        status: report.status.toLowerCase(),
        reason: report.reason.toLowerCase(),
        comment: report.comment,
        moderatorNote: report.moderatorNote,
        actionsApplied: report.actionsApplied,
        createdAt: report.createdAt.toISOString(),
        reporter: report.reporter,
        occurrence: report.occurrence,
      })),
      reportsFiled: reportsFiled.map((report) => ({
        id: report.id,
        status: report.status.toLowerCase(),
        reason: report.reason.toLowerCase(),
        comment: report.comment,
        moderatorNote: report.moderatorNote,
        actionsApplied: report.actionsApplied,
        createdAt: report.createdAt.toISOString(),
        targetUser: report.targetUser,
        occurrence: report.occurrence,
      })),
    };
  }

  async updateForAdmin(
    admin: AuthUser,
    userId: string,
    dto: AdminUpdateUserDto,
  ) {
    if (dto.role !== undefined && admin.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Only ADMIN can change user roles');
    }

    if (admin.id === userId && dto.isBlocked === true) {
      throw new BadRequestException('Cannot block your own account');
    }

    if (
      dto.role !== undefined &&
      admin.id === userId &&
      dto.role !== UserRole.ADMIN
    ) {
      throw new BadRequestException('Cannot demote your own admin role');
    }

    const data: Prisma.UserUpdateInput = {};
    if (dto.isBlocked !== undefined) data.isBlocked = dto.isBlocked;
    if (dto.role !== undefined) data.role = dto.role;

    if (Object.keys(data).length === 0) {
      throw new BadRequestException('No fields to update');
    }

    const before = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!before) {
      throw new NotFoundException('User not found');
    }

    await this.prisma.user.update({
      where: { id: userId },
      data,
    });

    if (dto.isBlocked !== undefined && dto.isBlocked !== before.isBlocked) {
      if (dto.isBlocked) {
        await this.revokeRefreshTokens(userId);
      }
      await this.audit.log({
        actorId: admin.id,
        action: dto.isBlocked
          ? AuditAction.USER_BLOCKED
          : AuditAction.USER_UNBLOCKED,
        targetType: 'user',
        targetId: userId,
      });
    }

    if (dto.role !== undefined && dto.role !== before.role) {
      await this.audit.log({
        actorId: admin.id,
        action: AuditAction.USER_ROLE_CHANGED,
        targetType: 'user',
        targetId: userId,
        metadata: { from: before.role, to: dto.role },
      });
    }

    return this.getAdminDetail(userId);
  }

  async blockForModeration(
    actorId: string,
    userId: string,
    reportId: string,
  ) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.isBlocked) {
      return;
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: { isBlocked: true },
    });
    await this.revokeRefreshTokens(userId);
    await this.audit.log({
      actorId,
      action: AuditAction.USER_BLOCKED,
      targetType: 'user',
      targetId: userId,
      metadata: { reportId, source: 'report' },
    });
  }

  private async revokeRefreshTokens(userId: string) {
    await this.prisma.refreshToken.deleteMany({ where: { userId } });
  }

  async getMyOrganized(userId: string, upcoming = true) {
    const now = new Date();
    const items = await this.prisma.routeOccurrence.findMany({
      where: {
        organizerId: userId,
        ...(upcoming
          ? {
              status: OccurrenceStatus.PUBLISHED,
              OR: [{ startsAt: null }, { startsAt: { gte: now } }],
            }
          : {
              OR: [
                { status: { not: OccurrenceStatus.PUBLISHED } },
                { startsAt: { lt: now } },
              ],
            }),
      },
      orderBy: { startsAt: 'asc' },
      include: { city: { select: { slug: true } } },
    });

    const mapped = await Promise.all(
      items.map(async (item) => ({
        ...(await this.media.signProfileEventPreview(
          toProfileEventPreview(item, !upcoming),
        )),
        cityId: item.city.slug,
        status: item.status.toLowerCase(),
      })),
    );

    return { items: mapped };
  }

  private toAdminListItem(
    user: {
      id: string;
      phone: string | null;
      email: string | null;
      name: string | null;
      role: UserRole;
      isBlocked: boolean;
      phoneVerified: boolean;
      emailVerified: boolean;
      lastActiveAt: Date | null;
      createdAt: Date;
      city: { slug: string; name: string } | null;
      _count: {
        organizedEvents: number;
        reportsReceived: number;
        reportsFiled: number;
      };
    },
  ) {
    return {
      id: user.id,
      phone: user.phone,
      email: user.email,
      name: user.name,
      role: user.role.toLowerCase(),
      isBlocked: user.isBlocked,
      phoneVerified: user.phoneVerified,
      emailVerified: user.emailVerified,
      city: user.city,
      lastActiveAt: user.lastActiveAt?.toISOString() ?? null,
      createdAt: user.createdAt.toISOString(),
      counts: {
        organizedEvents: user._count.organizedEvents,
        reportsReceived: user._count.reportsReceived,
        reportsFiled: user._count.reportsFiled,
      },
    };
  }

  private async findUserOrThrow(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        city: true,
        interests: { select: { filterId: true } },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  private async signProfile<T extends { avatarUrl: string | null }>(
    profile: T,
  ): Promise<T> {
    const avatarUrl = await this.media.signOptionalRef(profile.avatarUrl);
    return { ...profile, avatarUrl };
  }

  private toProfile(
    user: {
      id: string;
      phone: string | null;
      email: string | null;
      phoneVerified: boolean;
      emailVerified: boolean;
      name: string | null;
      avatarUrl: string | null;
      bio: string | null;
      role: string;
      isBlocked: boolean;
      city: { id: string; slug: string; name: string } | null;
      interests: { filterId: string }[];
    },
    isSelf: boolean,
  ) {
    return {
      id: user.id,
      phone: isSelf ? user.phone : undefined,
      email: isSelf ? user.email : undefined,
      phoneVerified: isSelf ? user.phoneVerified : undefined,
      emailVerified: isSelf ? user.emailVerified : undefined,
      name: user.name,
      avatarUrl: user.avatarUrl,
      bio: user.bio,
      role: isSelf ? user.role : undefined,
      city: user.city
        ? { id: user.city.id, slug: user.city.slug, name: user.city.name }
        : null,
      interestFilterIds: user.interests.map((item) => item.filterId),
    };
  }
}
