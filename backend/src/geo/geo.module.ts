import { Module } from '@nestjs/common';
import { GeoController } from './geo.controller';
import { GeoService } from './geo.service';
import { YandexGeoClient } from './yandex-geo.client';

@Module({
  controllers: [GeoController],
  providers: [GeoService, YandexGeoClient],
  exports: [GeoService],
})
export class GeoModule {}
