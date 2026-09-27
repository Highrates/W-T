import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditAction, ReportStatus } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { OccurrenceLifecycleAction } from '../routes/dto/update-occurrence.dto';
import { OccurrencesService } from '../routes/occurrences.service';
import { PrismaService } from '../database/prisma.service';
import { UsersService } from '../users/users.service';
import { AdminReportsQueryDto } from './dto/admin-reports-query.dto';
import { AdminUpdateReportDto } from './dto/admin-update-report.dto';
import { CreateReportDto } from './dto/create-report.dto';
import { ReportModerationAction } from './dto/report-moderation-action.enum';

@Injectable()
export class ReportsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly users: UsersService,
    private readonly occurrences: OccurrencesService,
  ) {}

  async create(reporterId: string, dto: CreateReportDto) {
    if (!dto.targetUserId && !dto.occurrenceId) {
      throw new BadRequestException(
        'Either targetUserId or occurrenceId is required',
      );
    }

    if (dto.targetUserId === reporterId) {
      throw new BadRequestException('Cannot report yourself');
    }

    const report = await this.prisma.report.create({
      data: {
        reporterId,
        targetUserId: dto.targetUserId,
        occurrenceId: dto.occurrenceId,
        reason: dto.reason,
        comment: dto.comment?.trim(),
      },
    });

    return {
      id: report.id,
      status: report.status.toLowerCase(),
      createdAt: report.createdAt.toISOString(),
    };
  }

  async listForAdmin(query: AdminReportsQueryDto) {
    const limit = query.limit ?? 20;

    const rows = await this.prisma.report.findMany({
      where: {
        ...(query.status ? { status: query.status } : {}),
        ...(query.targetUserId ? { targetUserId: query.targetUserId } : {}),
        ...(query.occurrenceId ? { occurrenceId: query.occurrenceId } : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      ...(query.cursor
        ? {
            cursor: { id: query.cursor },
            skip: 1,
          }
        : {}),
      include: {
        reporter: { select: { id: true, name: true } },
        targetUser: { select: { id: true, name: true } },
        occurrence: { select: { id: true, title: true } },
      },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;

    return {
      items: page.map((row) => ({
        id: row.id,
        status: row.status.toLowerCase(),
        reason: row.reason.toLowerCase(),
        comment: row.comment,
        moderatorNote: row.moderatorNote,
        actionsApplied: row.actionsApplied,
        createdAt: row.createdAt.toISOString(),
        updatedAt: row.updatedAt.toISOString(),
        reporter: row.reporter,
        targetUser: row.targetUser,
        occurrence: row.occurrence,
      })),
      nextCursor: hasMore ? page[page.length - 1]?.id ?? null : null,
    };
  }

  async updateForAdmin(
    actorId: string,
    reportId: string,
    dto: AdminUpdateReportDto,
  ) {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
    });

    if (!report) {
      throw new NotFoundException('Report not found');
    }

    if (dto.actions?.length && dto.status !== ReportStatus.REVIEWED) {
      throw new BadRequestException(
        'Moderation actions require status reviewed',
      );
    }

    const actionsApplied = dto.actions?.length ? [...dto.actions] : []

    const updated = await this.prisma.report.update({
      where: { id: reportId },
      data: {
        status: dto.status,
        moderatorNote: dto.moderatorNote?.trim(),
        ...(dto.actions?.length ? { actionsApplied } : {}),
      },
      include: {
        reporter: { select: { id: true, name: true } },
        targetUser: { select: { id: true, name: true } },
        occurrence: { select: { id: true, title: true } },
      },
    });

    if (report.status !== dto.status) {
      await this.audit.log({
        actorId,
        action: AuditAction.REPORT_STATUS_CHANGED,
        targetType: 'report',
        targetId: reportId,
        metadata: { from: report.status, to: dto.status },
      });
    }

    if (dto.actions?.length) {
      await this.applyReportActions(actorId, report, dto.actions);
    }

    return {
      id: updated.id,
      status: updated.status.toLowerCase(),
      reason: updated.reason.toLowerCase(),
      comment: updated.comment,
      moderatorNote: updated.moderatorNote,
      createdAt: updated.createdAt.toISOString(),
      updatedAt: updated.updatedAt.toISOString(),
      reporter: updated.reporter,
      targetUser: updated.targetUser,
      occurrence: updated.occurrence,
      actionsApplied: updated.actionsApplied,
    };
  }

  private async applyReportActions(
    actorId: string,
    report: {
      id: string;
      targetUserId: string | null;
      occurrenceId: string | null;
    },
    actions: ReportModerationAction[],
  ) {
    for (const action of actions) {
      switch (action) {
        case ReportModerationAction.BLOCK_TARGET_USER:
          if (!report.targetUserId) {
            throw new BadRequestException(
              'Report has no target user to block',
            );
          }
          await this.users.blockForModeration(
            actorId,
            report.targetUserId,
            report.id,
          );
          break;
        case ReportModerationAction.HIDE_OCCURRENCE:
          if (!report.occurrenceId) {
            throw new BadRequestException(
              'Report has no occurrence to hide',
            );
          }
          await this.occurrences.applyAdminLifecycle(
            actorId,
            report.occurrenceId,
            OccurrenceLifecycleAction.HIDE,
          );
          break;
        default:
          throw new BadRequestException('Unknown moderation action');
      }
    }
  }
}
