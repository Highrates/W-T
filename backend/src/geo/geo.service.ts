import { Injectable } from '@nestjs/common';
import { YandexGeoClient } from './yandex-geo.client';

@Injectable()
export class GeoService {
  constructor(private readonly yandex: YandexGeoClient) {}

  suggest(query: string, ll?: string) {
    return this.yandex.suggest(query, { ll, results: 7 });
  }

  reverseGeocode(latitude: number, longitude: number) {
    return this.yandex.reverseGeocode(latitude, longitude);
  }
}
