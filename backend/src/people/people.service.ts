import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { PostgisLocationService } from '../common/geo/postgis-location.service';
import { MediaService } from '../media/media.service';
import { FILTER_LABELS } from '../routes/feed-filters';
import { PeopleQueryDto } from './dto/people-query.dto';
import {
  buildPeopleRankedQuery,
  PeopleRankedRow,
} from './people-scoring.sql';

@Injectable()
export class PeopleService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly media: MediaService,
    private readonly postgis: PostgisLocationService,
  ) {}

  async list(query: PeopleQueryDto) {
    const limit = query.limit ?? 20;
    const interestIds = parseCsv(query.interests);
    const { nearLat, nearLng } = parseNear(query);
    const citySlug = query.cityId ?? query.city_id;

    const rows = await this.prisma.$queryRaw<PeopleRankedRow[]>(
      buildPeopleRankedQuery({
        now: new Date(),
        citySlug,
        nearLat,
        nearLng,
        radiusKm: query.radiusKm ?? query.radius_km ?? 15,
        interestIds,
        cursor: query.cursor,
        limit,
        postgis: this.postgis,
      }),
    );

    if (rows.length === 0) {
      return { items: [], nextCursor: null };
    }

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore ? page[page.length - 1]?.id ?? null : null;

    const items = await Promise.all(
      page.map(async (row) => ({
        id: row.id,
        name: row.name ?? 'Пользователь',
        avatarUrl: await this.media.signOptionalRef(row.avatar_url),
        bio: row.bio,
        city:
          row.city_slug && row.city_name
            ? { slug: row.city_slug, name: row.city_name }
            : null,
        isVerified: row.phone_verified || row.email_verified,
        isOrganizer: true,
        interestTags: (row.interest_filter_ids ?? []).map(
          (id) => FILTER_LABELS[id] ?? id,
        ),
        upcomingEventsCount: Number(row.upcoming_count),
        peopleTabEventsLine: eventsLabel(Number(row.upcoming_count)),
      })),
    );

    return { items, nextCursor };
  }
}

function parseCsv(raw?: string): string[] {
  if (!raw?.trim()) return [];
  return raw.split(',').map((s) => s.trim()).filter(Boolean);
}

function parseNear(query: PeopleQueryDto): {
  nearLat?: number;
  nearLng?: number;
} {
  if (query.nearLat != null && query.nearLng != null) {
    return { nearLat: query.nearLat, nearLng: query.nearLng };
  }
  if (!query.near?.trim()) return {};
  const parts = query.near.split(',').map(Number);
  if (parts.length !== 2 || parts.some(Number.isNaN)) {
    throw new BadRequestException('near must be lat,lng');
  }
  return { nearLat: parts[0], nearLng: parts[1] };
}

function eventsLabel(count: number): string | null {
  if (count <= 0) return null;
  const mod10 = count % 10;
  const mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 14) return `${count} событий`;
  if (mod10 === 1) return `${count} событие`;
  if (mod10 >= 2 && mod10 <= 4) return `${count} события`;
  return `${count} событий`;
}
