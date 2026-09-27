import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { VerifiedContactGuard } from '../common/guards/verified-contact.guard';
import { UpdateParticipationDto } from './dto/update-participation.dto';
import { ParticipationService } from './participation.service';

@Controller('participations')
@UseGuards(JwtAuthGuard)
export class ParticipationController {
  constructor(private readonly participation: ParticipationService) {}

  @Patch(':id')
  update(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateParticipationDto,
  ) {
    return this.participation.updateStatus(user.id, id, dto);
  }
}
