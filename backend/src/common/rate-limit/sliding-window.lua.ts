/** Atomic sliding-window rate limit: trim → count → maybe add. */
export const SLIDING_WINDOW_RATE_LIMIT_SCRIPT = `
local key = KEYS[1]
local now = tonumber(ARGV[1])
local window_ms = tonumber(ARGV[2])
local max = tonumber(ARGV[3])
local member = ARGV[4]

redis.call('ZREMRANGEBYSCORE', key, 0, now - window_ms)
local count = redis.call('ZCARD', key)

if count >= max then
  local oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
  local oldest_score = now
  if oldest[2] then
    oldest_score = tonumber(oldest[2])
  end
  return {0, oldest_score}
end

redis.call('ZADD', key, now, member)
redis.call('PEXPIRE', key, window_ms)
return {1, count + 1}
`;

export type SlidingWindowEvalResult = {
  allowed: boolean;
  oldestScoreMs: number;
};

export function parseSlidingWindowEvalResult(raw: unknown): SlidingWindowEvalResult {
  const tuple = raw as [number | string, number | string] | null;
  const allowedFlag = Number(tuple?.[0] ?? 0);
  const oldestScoreMs = Number(tuple?.[1] ?? Date.now());

  return {
    allowed: allowedFlag === 1,
    oldestScoreMs,
  };
}
