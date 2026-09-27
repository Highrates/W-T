import { Module } from '@nestjs/common';
import { AdminAuditController } from './admin-audit.controller';
import { AdminStatsController } from './admin-stats.controller';
import { AdminStatsService } from './admin-stats.service';

@Module({
  controllers: [AdminAuditController, AdminStatsController],
  providers: [AdminStatsService],
})
export class AdminModule {}
