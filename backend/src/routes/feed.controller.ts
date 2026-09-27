import { Controller, Get, Query, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AuthUser } from '../auth/auth.types';
import { OptionalJwtAuthGuard } from '../common/guards/optional-jwt-auth.guard';
import { FeedQueryDto } from './dto/feed-query.dto';
import { OccurrencesService } from './occurrences.service';
import { normalizeFeedQuery } from './query.utils';

@Controller('feed')
export class FeedController {
  constructor(private readonly occurrences: OccurrencesService) {}

  @Get()
  @UseGuards(OptionalJwtAuthGuard)
  getFeed(
    @Query() query: FeedQueryDto,
    @Req() req: Request & { user?: AuthUser | null },
  ) {
    return this.occurrences.getFeed(
      normalizeFeedQuery(query),
      req.user?.id ?? undefined,
    );
  }
}
