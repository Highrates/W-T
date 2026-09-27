import {
  Body,
  Controller,
  Delete,
  Get,
  Put,
  UseGuards,
} from '@nestjs/common';
import { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DraftsService } from './drafts.service';
import { UpsertDraftDto } from './dto/upsert-draft.dto';

@Controller('drafts')
@UseGuards(JwtAuthGuard)
export class DraftsController {
  constructor(private readonly drafts: DraftsService) {}

  @Get('me')
  getMine(@CurrentUser() user: AuthUser) {
    return this.drafts.getMine(user.id);
  }

  @Put('me')
  upsertMine(@CurrentUser() user: AuthUser, @Body() dto: UpsertDraftDto) {
    return this.drafts.upsertMine(user.id, dto);
  }

  @Delete('me')
  deleteMine(@CurrentUser() user: AuthUser) {
    return this.drafts.deleteMine(user.id);
  }
}
