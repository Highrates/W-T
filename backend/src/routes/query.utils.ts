import { BadRequestException } from '@nestjs/common';
import { FeedQueryDto, MapQueryDto } from './dto/feed-query.dto';

export function normalizeFeedQuery(query: FeedQueryDto): FeedQueryDto {
  return {
    ...query,
    ...parseNear(query.near, query.nearLat, query.nearLng),
    radiusKm: query.radiusKm ?? parseRadius(query.radius_km),
  };
}

export function normalizeMapQuery(query: MapQueryDto): MapQueryDto {
  return {
    ...query,
    ...parseNear(query.near, query.nearLat, query.nearLng),
    radiusKm: query.radiusKm ?? parseRadius(query.radius_km) ?? 15,
  };
}

function parseNear(
  near?: string,
  nearLat?: number,
  nearLng?: number,
): { nearLat?: number; nearLng?: number } {
  if (nearLat != null && nearLng != null) {
    return { nearLat, nearLng };
  }

  if (!near?.trim()) return {};

  const parts = near.split(',').map((part) => Number(part.trim()));
  if (parts.length !== 2 || parts.some(Number.isNaN)) {
    throw new BadRequestException('near must be lat,lng');
  }

  return { nearLat: parts[0], nearLng: parts[1] };
}

function parseRadius(value?: number | string): number | undefined {
  if (value == null || value === '') return undefined;
  const num = typeof value === 'number' ? value : Number(value);
  return Number.isNaN(num) ? undefined : num;
}
