import { Module } from '@nestjs/common';
import { MediaModule } from '../media/media.module';
import { ParticipationModule } from '../participation/participation.module';
import { AdminUsersController } from './admin-users.controller';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [MediaModule, ParticipationModule],
  controllers: [UsersController, AdminUsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
