import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AdminReportsQueryDto } from './dto/admin-reports-query.dto';
import { AdminUpdateReportDto } from './dto/admin-update-report.dto';
import { ReportsService } from './reports.service';

/** M3 admin stub — moderation queue for user/event reports. */
@Controller('admin/reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.MODERATOR)
export class AdminReportsController {
  constructor(private readonly reports: ReportsService) {}

  @Get()
  list(@Query() query: AdminReportsQueryDto) {
    return this.reports.listForAdmin(query);
  }

  @Patch(':id')
  update(
    @CurrentUser() admin: AuthUser,
    @Param('id') id: string,
    @Body() dto: AdminUpdateReportDto,
  ) {
    return this.reports.updateForAdmin(admin.id, id, dto);
  }
}
