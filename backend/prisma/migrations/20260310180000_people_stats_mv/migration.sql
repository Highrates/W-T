-- Denormalized people ranking inputs (M3). Refresh via PeopleStatsService.refresh().
CREATE MATERIALIZED VIEW user_people_stats AS
SELECT
  u.id AS user_id,
  COUNT(o.id) FILTER (
    WHERE o.status = 'PUBLISHED'
    AND (o.starts_at IS NULL OR o.starts_at >= NOW())
  )::int AS upcoming_events_count,
  u.last_active_at,
  COALESCE(
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT ui.filter_id), NULL),
    ARRAY[]::text[]
  ) AS interest_filter_ids
FROM users u
LEFT JOIN route_occurrences o ON o.organizer_id = u.id
LEFT JOIN user_interests ui ON ui.user_id = u.id
WHERE u.is_blocked = false
GROUP BY u.id, u.last_active_at;

CREATE UNIQUE INDEX user_people_stats_user_id_idx ON user_people_stats (user_id);
