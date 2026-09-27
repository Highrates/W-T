import { Module } from '@nestjs/common';
import { GeoModule } from '../geo/geo.module';
import { MediaModule } from '../media/media.module';
import { PeopleModule } from '../people/people.module';
import { ParticipationModule } from '../participation/participation.module';
import { AdminOccurrencesController } from './admin-occurrences.controller';
import { FeedController } from './feed.controller';
import { OccurrencesController } from './occurrences.controller';
import { OccurrencesService } from './occurrences.service';

@Module({
  imports: [GeoModule, MediaModule, ParticipationModule, PeopleModule],
  controllers: [OccurrencesController, AdminOccurrencesController, FeedController],
  providers: [OccurrencesService],
  exports: [OccurrencesService],
})
export class RoutesModule {}
