import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { PostgisModule } from './common/geo/postgis.module';
import { IpRateLimitMiddleware } from './common/rate-limit/ip-rate-limit.middleware';
import { RateLimitModule } from './common/rate-limit/rate-limit.module';
import { AdminModule } from './admin/admin.module';
import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { ChatModule } from './chat/chat.module';
import { CitiesModule } from './cities/cities.module';
import { DatabaseModule } from './database/database.module';
import { DevicesModule } from './devices/devices.module';
import { DraftsModule } from './drafts/drafts.module';
import { GeoModule } from './geo/geo.module';
import { HealthController } from './health.controller';
import { MediaModule } from './media/media.module';
import { MetaModule } from './meta/meta.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ParticipationModule } from './participation/participation.module';
import { PeopleModule } from './people/people.module';
import { RedisModule } from './redis/redis.module';
import { ReportsModule } from './reports/reports.module';
import { RoutesModule } from './routes/routes.module';
import { TemplatesModule } from './templates/templates.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ScheduleModule.forRoot(),
    RateLimitModule,
    PostgisModule,
    AuditModule,
    DatabaseModule,
    RedisModule,
    CitiesModule,
    AuthModule,
    NotificationsModule,
    ParticipationModule,
    UsersModule,
    MetaModule,
    RoutesModule,
    DraftsModule,
    MediaModule,
    PeopleModule,
    ReportsModule,
    ChatModule,
    AdminModule,
    DevicesModule,
    TemplatesModule,
    GeoModule,
  ],
  controllers: [HealthController],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(IpRateLimitMiddleware).forRoutes('*');
  }
}
