import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AdminOccurrencesQueryDto } from './dto/admin-occurrences-query.dto';
import { OccurrenceLifecycleDto } from './dto/update-occurrence.dto';
import { OccurrencesService } from './occurrences.service';

@Controller('admin/occurrences')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.MODERATOR)
export class AdminOccurrencesController {
  constructor(private readonly occurrences: OccurrencesService) {}

  @Get()
  list(@Query() query: AdminOccurrencesQueryDto) {
    return this.occurrences.listForAdmin(query);
  }

  @Get(':id')
  detail(@Param('id') id: string) {
    return this.occurrences.getAdminDetail(id);
  }

  @Post(':id/lifecycle')
  lifecycle(
    @CurrentUser() admin: AuthUser,
    @Param('id') id: string,
    @Body() dto: OccurrenceLifecycleDto,
  ) {
    return this.occurrences.applyAdminLifecycle(admin.id, id, dto.action);
  }
}
