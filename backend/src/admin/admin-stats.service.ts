import { Injectable } from '@nestjs/common';
import {
  OccurrenceStatus,
  ParticipationStatus,
  ReportStatus,
} from '@prisma/client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class AdminStatsService {
  constructor(private readonly prisma: PrismaService) {}

  async getStats() {
    const [
      usersTotal,
      usersBlocked,
      reportsOpen,
      reportsReviewed,
      reportsDismissed,
      occurrencesPublished,
      occurrencesHidden,
      occurrencesCancelled,
      participationsTotal,
      participationsAccepted,
      participationsPending,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { isBlocked: true } }),
      this.prisma.report.count({ where: { status: ReportStatus.OPEN } }),
      this.prisma.report.count({ where: { status: ReportStatus.REVIEWED } }),
      this.prisma.report.count({ where: { status: ReportStatus.DISMISSED } }),
      this.prisma.routeOccurrence.count({
        where: { status: OccurrenceStatus.PUBLISHED },
      }),
      this.prisma.routeOccurrence.count({
        where: { status: OccurrenceStatus.HIDDEN },
      }),
      this.prisma.routeOccurrence.count({
        where: { status: OccurrenceStatus.CANCELLED },
      }),
      this.prisma.participation.count(),
      this.prisma.participation.count({
        where: { status: ParticipationStatus.ACCEPTED },
      }),
      this.prisma.participation.count({
        where: { status: ParticipationStatus.PENDING },
      }),
    ]);

    return {
      users: { total: usersTotal, blocked: usersBlocked },
      reports: {
        open: reportsOpen,
        reviewed: reportsReviewed,
        dismissed: reportsDismissed,
      },
      occurrences: {
        published: occurrencesPublished,
        hidden: occurrencesHidden,
        cancelled: occurrencesCancelled,
      },
      joins: {
        total: participationsTotal,
        accepted: participationsAccepted,
        pending: participationsPending,
      },
    };
  }
}
