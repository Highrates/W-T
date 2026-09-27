import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { ParticipationService } from '../participation/participation.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(
    private readonly users: UsersService,
    private readonly participation: ParticipationService,
  ) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  getMe(@CurrentUser() user: AuthUser) {
    return this.users.getMe(user.id);
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  updateMe(@CurrentUser() user: AuthUser, @Body() dto: UpdateUserDto) {
    return this.users.updateMe(user.id, dto);
  }

  @Get('me/organized')
  @UseGuards(JwtAuthGuard)
  getMyOrganized(
    @CurrentUser() user: AuthUser,
    @Query('upcoming') upcoming?: string,
  ) {
    return this.users.getMyOrganized(user.id, upcoming !== 'false');
  }

  @Get('me/participations')
  @UseGuards(JwtAuthGuard)
  getMyParticipations(
    @CurrentUser() user: AuthUser,
    @Query('upcoming') upcoming?: string,
  ) {
    return this.participation.getMyParticipations(
      user.id,
      upcoming !== 'false',
    );
  }

  @Get(':id')
  getPublic(@Param('id') id: string) {
    return this.users.getPublicProfile(id);
  }
}
