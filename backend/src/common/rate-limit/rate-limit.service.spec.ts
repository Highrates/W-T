import { ConfigService } from '@nestjs/config';
import { createTestRedis } from '../../test/redis-memory';
import { RedisService } from '../../redis/redis.service';
import { RateLimitService } from './rate-limit.service';

function mockRedisService(client: ReturnType<typeof createTestRedis>): RedisService {
  return { getClient: () => client } as RedisService;
}

describe('RateLimitService sliding window', () => {
  it('allows up to max requests atomically then blocks', async () => {
    const redis = createTestRedis();
    const service = new RateLimitService(
      mockRedisService(redis),
      new ConfigService({
        RATE_LIMIT_AUTH_MAX: 2,
        RATE_LIMIT_AUTH_WINDOW_SECONDS: 60,
      }),
    );

    expect((await service.check('auth', '1.2.3.4')).allowed).toBe(true);
    expect((await service.check('auth', '1.2.3.4')).allowed).toBe(true);

    const blocked = await service.check('auth', '1.2.3.4');
    expect(blocked.allowed).toBe(false);
    expect(blocked.retryAfterSeconds).toBeGreaterThan(0);
  });

  it('does not exceed max under concurrent checks', async () => {
    const redis = createTestRedis();
    const service = new RateLimitService(
      mockRedisService(redis),
      new ConfigService({
        RATE_LIMIT_AUTH_MAX: 5,
        RATE_LIMIT_AUTH_WINDOW_SECONDS: 60,
      }),
    );

    const results = await Promise.all(
      Array.from({ length: 20 }, () => service.check('auth', '9.9.9.9')),
    );

    const allowed = results.filter((result) => result.allowed).length;
    expect(allowed).toBe(5);
  });
});
