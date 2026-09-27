import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../common/guards/optional-jwt-auth.guard';
import { VerifiedContactGuard } from '../common/guards/verified-contact.guard';
import { CreateOccurrenceDto } from './dto/create-occurrence.dto';
import { MapQueryDto } from './dto/feed-query.dto';
import {
  OccurrenceLifecycleDto,
  UpdateOccurrenceDto,
} from './dto/update-occurrence.dto';
import { ParticipationService } from '../participation/participation.service';
import { OccurrencesService } from './occurrences.service';
import { normalizeMapQuery } from './query.utils';

@Controller('occurrences')
export class OccurrencesController {
  constructor(
    private readonly occurrences: OccurrencesService,
    private readonly participation: ParticipationService,
  ) {}

  @Post()
  @UseGuards(JwtAuthGuard, VerifiedContactGuard)
  publish(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateOccurrenceDto,
  ) {
    return this.occurrences.publish(user.id, dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, VerifiedContactGuard)
  update(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateOccurrenceDto,
  ) {
    return this.occurrences.updateOccurrence(user.id, id, dto);
  }

  @Post(':id/lifecycle')
  @UseGuards(JwtAuthGuard, VerifiedContactGuard)
  lifecycle(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: OccurrenceLifecycleDto,
  ) {
    return this.occurrences.applyLifecycle(user.id, id, dto.action);
  }

  @Get('map')
  getMap(@Query() query: MapQueryDto) {
    return this.occurrences.getMapPins(normalizeMapQuery(query));
  }

  @Post(':id/join')
  @UseGuards(JwtAuthGuard, VerifiedContactGuard)
  join(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.participation.join(user.id, id);
  }

  @Post(':id/leave')
  @UseGuards(JwtAuthGuard)
  leave(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.participation.leave(user.id, id);
  }

  @Get(':id/participations')
  @UseGuards(JwtAuthGuard)
  listParticipations(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ) {
    return this.participation.listForOccurrence(user.id, id);
  }

  @Get(':id')
  @UseGuards(OptionalJwtAuthGuard)
  getDetail(
    @Param('id') id: string,
    @Req() req: Request & { user?: AuthUser | null },
  ) {
    return this.occurrences.getDetail(id, req.user?.id ?? undefined);
  }
}
