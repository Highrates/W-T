import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { GeoModule } from './geo/geo.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    GeoModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
