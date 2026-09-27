import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

/** M3: materialized view refresh for `/people` scoring. */
@Injectable()
export class PeopleStatsService {
  private readonly logger = new Logger(PeopleStatsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async refresh(): Promise<void> {
    try {
      await this.prisma.$executeRaw`
        REFRESH MATERIALIZED VIEW CONCURRENTLY user_people_stats
      `;
    } catch (error) {
      this.logger.warn(
        `People stats refresh failed: ${error instanceof Error ? error.message : error}`,
      );
    }
  }
}
