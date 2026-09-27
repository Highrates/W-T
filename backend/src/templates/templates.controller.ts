import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { VerifiedContactGuard } from '../common/guards/verified-contact.guard';
import { CreateTemplateDto } from './dto/create-template.dto';
import { SpawnOccurrenceDto } from './dto/spawn-occurrence.dto';
import { TemplatesService } from './templates.service';

@Controller('templates')
@UseGuards(JwtAuthGuard)
export class TemplatesController {
  constructor(private readonly templates: TemplatesService) {}

  @Get('me')
  listMine(@CurrentUser() user: AuthUser) {
    return this.templates.listMine(user.id);
  }

  @Post()
  @UseGuards(VerifiedContactGuard)
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateTemplateDto) {
    return this.templates.createFromOccurrence(user.id, dto.occurrenceId);
  }

  @Post(':id/occurrences')
  @UseGuards(VerifiedContactGuard)
  spawn(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: SpawnOccurrenceDto,
  ) {
    return this.templates.spawnOccurrence(user.id, id, dto);
  }
}
