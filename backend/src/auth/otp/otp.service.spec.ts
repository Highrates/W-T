import { HttpException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTestRedis } from '../../test/redis-memory';
import { RedisService } from '../../redis/redis.service';
import { OtpService } from './otp.service';

function mockRedisService(client: ReturnType<typeof createTestRedis>): RedisService {
  return { getClient: () => client } as RedisService;
}

describe('OtpService verify lockout', () => {
  let otp: OtpService;
  let redis: ReturnType<typeof createTestRedis>;

  beforeEach(() => {
    redis = createTestRedis();
    otp = new OtpService(
      mockRedisService(redis),
      new ConfigService({
        OTP_TTL_SECONDS: 300,
        OTP_VERIFY_MAX_ATTEMPTS: 3,
        OTP_VERIFY_ATTEMPT_WINDOW_SECONDS: 900,
        OTP_VERIFY_LOCKOUT_BASE_SECONDS: 60,
        OTP_VERIFY_LOCKOUT_MULTIPLIER: 2,
        OTP_VERIFY_LOCKOUT_MAX_SECONDS: 3600,
        OTP_VERIFY_LOCKOUT_LEVEL_TTL_SECONDS: 86400,
      }),
    );
  });

  it('locks out after max failed verify attempts', async () => {
    await otp.issue('email', 'user@example.com');
    const code = (await redis.get('otp:email:user@example.com'))!;

    expect(await otp.verify('email', 'user@example.com', '000000')).toBe(false);
    expect(await otp.verify('email', 'user@example.com', '000000')).toBe(false);
    expect(await otp.verify('email', 'user@example.com', '000000')).toBe(false);

    await expect(otp.verify('email', 'user@example.com', code)).rejects.toBeInstanceOf(
      HttpException,
    );

    const lockTtl = await redis.ttl('otp-verify-lock:email:user@example.com');
    expect(lockTtl).toBeGreaterThan(0);
  });

  it('clears verify state after successful code', async () => {
    await otp.issue('phone', '+79990001122');
    const code = (await redis.get('otp:phone:+79990001122'))!;

    expect(await otp.verify('phone', '+79990001122', code)).toBe(true);
    expect(await redis.get('otp-verify-attempts:phone:+79990001122')).toBeNull();
  });
});
