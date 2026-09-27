import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PeopleStatsService } from './people-stats.service';

function isPeopleStatsCronEnabled(): boolean {
  const flag = process.env.PEOPLE_STATS_CRON_ENABLED?.trim().toLowerCase();
  return flag !== 'false' && flag !== '0';
}

/** Periodic refresh of `user_people_stats` (see also write-triggered refresh). */
@Injectable()
export class PeopleStatsCron {
  private readonly logger = new Logger(PeopleStatsCron.name);

  constructor(private readonly peopleStats: PeopleStatsService) {}

  @Cron(process.env.PEOPLE_STATS_CRON ?? '0 */15 * * * *')
  async refreshMaterializedView(): Promise<void> {
    if (!isPeopleStatsCronEnabled()) {
      return;
    }

    this.logger.debug('Refreshing user_people_stats (cron)');
    await this.peopleStats.refresh();
  }
}
