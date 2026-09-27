import RedisMock from 'ioredis-mock';

/** In-memory Redis for unit tests (supports EVAL used by rate limit Lua). */
export function createTestRedis() {
  return new RedisMock();
}
