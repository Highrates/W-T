import {
  BadGatewayException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  GeoReverseResultDto,
  GeoSuggestItemDto,
  YandexGeocoderResponse,
  YandexSuggestResponse,
} from './geo.types';

@Injectable()
export class YandexGeoClient {
  constructor(private readonly config: ConfigService) {}

  async suggest(
    query: string,
    options?: { ll?: string; results?: number },
  ): Promise<GeoSuggestItemDto[]> {
    const apiKey = this.config.get<string>('YANDEX_GEOSUGGEST_API_KEY');
    if (!apiKey) {
      throw new ServiceUnavailableException('YANDEX_GEOSUGGEST_API_KEY is not set');
    }

    const params = new URLSearchParams({
      apikey: apiKey,
      text: query,
      lang: 'ru_RU',
      results: String(options?.results ?? 7),
      types: 'geo,biz,street,house',
    });

    if (options?.ll) {
      params.set('ll', options.ll);
    }

    const response = await fetch(
      `https://suggest-maps.yandex.ru/v1/suggest?${params.toString()}`,
    );

    if (!response.ok) {
      throw new BadGatewayException(
        `Yandex suggest failed: ${response.status} ${response.statusText}`,
      );
    }

    const payload = (await response.json()) as YandexSuggestResponse;
    const raw = payload.results ?? [];

    const geocoded: GeoSuggestItemDto[] = [];
    for (const item of raw) {
      const title = item.title?.text?.trim();
      if (!title) continue;

      const subtitle = item.subtitle?.text?.trim() ?? '';
      const searchText = subtitle ? `${title}, ${subtitle}` : title;

      try {
        const point = await this.geocodeAddress(searchText);
        geocoded.push({
          title,
          subtitle,
          latitude: point.latitude,
          longitude: point.longitude,
          cityId: point.cityId,
        });
      } catch {
        // Skip suggestions we cannot geocode (rate limits / ambiguous text).
      }
    }

    return geocoded;
  }

  async reverseGeocode(
    latitude: number,
    longitude: number,
  ): Promise<GeoReverseResultDto> {
    const point = await this.geocodeCoordinates(longitude, latitude);
    return {
      title: point.title,
      address: point.address,
      latitude: point.latitude,
      longitude: point.longitude,
      cityId: point.cityId,
    };
  }

  private async geocodeAddress(text: string) {
    return this.geocode(`${encodeURIComponent(text)}`);
  }

  private async geocodeCoordinates(longitude: number, latitude: number) {
    return this.geocode(`${longitude},${latitude}`);
  }

  private async geocode(geocodeParam: string) {
    const apiKey = this.config.get<string>('YANDEX_GEOCODER_API_KEY');
    if (!apiKey) {
      throw new ServiceUnavailableException('YANDEX_GEOCODER_API_KEY is not set');
    }

    const params = new URLSearchParams({
      apikey: apiKey,
      geocode: geocodeParam,
      format: 'json',
      lang: 'ru_RU',
      results: '1',
    });

    const response = await fetch(
      `https://geocode-maps.yandex.ru/1.x/?${params.toString()}`,
    );

    if (!response.ok) {
      throw new BadGatewayException(
        `Yandex geocoder failed: ${response.status} ${response.statusText}`,
      );
    }

    const payload = (await response.json()) as YandexGeocoderResponse;
    const geoObject =
      payload.response?.GeoObjectCollection?.featureMember?.[0]?.GeoObject;

    if (!geoObject?.Point?.pos) {
      throw new BadGatewayException('Geocoder returned no results');
    }

    const [lonRaw, latRaw] = geoObject.Point.pos.split(' ');
    const longitude = Number(lonRaw);
    const latitude = Number(latRaw);

    const meta = geoObject.metaDataProperty?.GeocoderMetaData;
    const address =
      meta?.Address?.formatted ??
      meta?.text ??
      geoObject.description ??
      geoObject.name ??
      '';

    const title = geoObject.name ?? address;
    const cityId = this.resolveCityId(meta?.Address?.Components);

    return {
      title,
      address,
      latitude,
      longitude,
      cityId,
    };
  }

  private resolveCityId(
    components?: Array<{ kind?: string; name?: string }>,
  ): string | undefined {
    if (!components?.length) return undefined;

    const locality = components.find((part) => part.kind === 'locality');
    if (!locality?.name) return undefined;

    return this.citySlug(locality.name);
  }

  private citySlug(name: string): string {
    const normalized = name.trim().toLowerCase();
    const known: Record<string, string> = {
      сочи: 'sochi',
      москва: 'moscow',
      'санкт-петербург': 'spb',
      'сaint-petersburg': 'spb',
      казань: 'kazan',
      'нижний новгород': 'nizhny',
      'екатеринбург': 'ekb',
      'новосибирск': 'novosibirsk',
      краснодар: 'krasnodar',
    };

    return known[normalized] ?? normalized.replace(/\s+/g, '_');
  }
}
