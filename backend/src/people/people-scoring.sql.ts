import { Prisma } from '@prisma/client';
import { PostgisLocationService } from '../common/geo/postgis-location.service';

export type PeopleRankedRow = {
  id: string;
  name: string | null;
  avatar_url: string | null;
  bio: string | null;
  phone_verified: boolean;
  email_verified: boolean;
  city_slug: string | null;
  city_name: string | null;
  upcoming_count: number;
  interest_filter_ids: string[];
  score: number;
};

export function buildPeopleRankedQuery(params: {
  now: Date;
  citySlug?: string;
  nearLat?: number;
  nearLng?: number;
  radiusKm: number;
  interestIds: string[];
  cursor?: string;
  limit: number;
  postgis: PostgisLocationService;
}): Prisma.Sql {
  const interestArray = params.interestIds;
  const radiusM = params.radiusKm * 1000;

  const geoEligible = Prisma.sql`
    SELECT DISTINCT o.organizer_id
    FROM route_occurrences o
    INNER JOIN cities c ON c.id = o.city_id
    WHERE o.status = 'PUBLISHED'
    AND (o.starts_at IS NULL OR o.starts_at >= ${params.now})
    ${params.citySlug ? Prisma.sql`AND c.slug = ${params.citySlug}` : Prisma.empty}
    AND ${params.postgis.withinRadius(
      Prisma.sql`o.location`,
      params.nearLng!,
      params.nearLat!,
      radiusM,
    )}
  `;

  const cityEligible = Prisma.sql`
    SELECT DISTINCT o.organizer_id
    FROM route_occurrences o
    INNER JOIN cities c ON c.id = o.city_id
    WHERE o.status = 'PUBLISHED'
    AND (o.starts_at IS NULL OR o.starts_at >= ${params.now})
    AND c.slug = ${params.citySlug}
  `;

  const globalEligible = Prisma.sql`
    SELECT DISTINCT o.organizer_id
    FROM route_occurrences o
    WHERE o.status = 'PUBLISHED'
    AND (o.starts_at IS NULL OR o.starts_at >= ${params.now})
  `;

  const eligible =
    params.nearLat != null && params.nearLng != null
      ? geoEligible
      : params.citySlug
        ? cityEligible
        : globalEligible;

  const interestOverlapSql =
    interestArray.length > 0
      ? Prisma.sql`(
          SELECT COUNT(*)::int
          FROM unnest(s.interest_filter_ids) AS fid
          WHERE fid = ANY(${interestArray}::text[])
        )`
      : Prisma.sql`0`;

  const cursorSql = params.cursor
    ? Prisma.sql`
        AND (
          r.score,
          r.upcoming_count,
          r.id
        ) < (
          SELECT score, upcoming_count, id
          FROM ranked
          WHERE id = ${params.cursor}::uuid
        )
      `
    : Prisma.empty;

  return Prisma.sql`
    WITH eligible AS (${eligible}),
    ranked AS (
      SELECT
        u.id,
        u.name,
        u.avatar_url,
        u.bio,
        u.phone_verified,
        u.email_verified,
        c.slug AS city_slug,
        c.name AS city_name,
        s.upcoming_events_count AS upcoming_count,
        s.interest_filter_ids,
        (
          ${interestOverlapSql} * 10
          + s.upcoming_events_count * 5
          + GREATEST(
            0,
            30 - EXTRACT(EPOCH FROM (NOW() - COALESCE(s.last_active_at, NOW() - INTERVAL '999 days'))) / 86400
          )
        )::float AS score
      FROM users u
      INNER JOIN eligible e ON e.organizer_id = u.id
      INNER JOIN user_people_stats s ON s.user_id = u.id
      LEFT JOIN cities c ON c.id = u.city_id
      WHERE u.is_blocked = false
    )
    SELECT *
    FROM ranked r
    WHERE TRUE
    ${cursorSql}
    ORDER BY r.score DESC, r.upcoming_count DESC, r.id ASC
    LIMIT ${params.limit + 1}
  `;
}
