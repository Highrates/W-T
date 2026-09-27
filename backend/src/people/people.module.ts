import { Module } from '@nestjs/common';
import { MediaModule } from '../media/media.module';
import { PeopleController } from './people.controller';
import { PeopleService } from './people.service';
import { PeopleStatsCron } from './people-stats.cron';
import { PeopleStatsService } from './people-stats.service';

@Module({
  imports: [MediaModule],
  controllers: [PeopleController],
  providers: [PeopleService, PeopleStatsService, PeopleStatsCron],
  exports: [PeopleStatsService],
})
export class PeopleModule {}
