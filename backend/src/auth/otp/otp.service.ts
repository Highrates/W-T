import {
  HttpException,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '../../redis/redis.service';
import { generateOtpCode } from '../auth.utils';

type OtpChannel = 'phone' | 'email';

@Injectable()
export class OtpService {
  private readonly ttlSeconds: number;
  private readonly rateLimitMax: number;
  private readonly rateLimitWindowSeconds: number;
  private readonly verifyMaxAttempts: number;
  private readonly verifyAttemptWindowSeconds: number;
  private readonly lockoutBaseSeconds: number;
  private readonly lockoutMultiplier: number;
  private readonly lockoutMaxSeconds: number;
  private readonly lockoutLevelTtlSeconds: number;

  constructor(
    private readonly redis: RedisService,
    config: ConfigService,
  ) {
    this.ttlSeconds = Number(config.get('OTP_TTL_SECONDS', 300));
    this.rateLimitMax = Number(config.get('OTP_RATE_LIMIT_MAX', 3));
    this.rateLimitWindowSeconds = Number(
      config.get('OTP_RATE_LIMIT_WINDOW_SECONDS', 900),
    );
    this.verifyMaxAttempts = Number(config.get('OTP_VERIFY_MAX_ATTEMPTS', 5));
    this.verifyAttemptWindowSeconds = Number(
      config.get('OTP_VERIFY_ATTEMPT_WINDOW_SECONDS', 900),
    );
    this.lockoutBaseSeconds = Number(
      config.get('OTP_VERIFY_LOCKOUT_BASE_SECONDS', 60),
    );
    this.lockoutMultiplier = Number(
      config.get('OTP_VERIFY_LOCKOUT_MULTIPLIER', 2),
    );
    this.lockoutMaxSeconds = Number(
      config.get('OTP_VERIFY_LOCKOUT_MAX_SECONDS', 3600),
    );
    this.lockoutLevelTtlSeconds = Number(
      config.get('OTP_VERIFY_LOCKOUT_LEVEL_TTL_SECONDS', 86400),
    );
  }

  async issue(channel: OtpChannel, identifier: string): Promise<string> {
    await this.assertRateLimit(channel, identifier);

    const code = generateOtpCode();
    const client = this.redis.getClient();
    const otpKey = this.otpKey(channel, identifier);

    await client.set(otpKey, code, 'EX', this.ttlSeconds);
    await client.incr(this.rateKey(channel, identifier));
    await client.expire(
      this.rateKey(channel, identifier),
      this.rateLimitWindowSeconds,
    );

    return code;
  }

  async verify(
    channel: OtpChannel,
    identifier: string,
    code: string,
  ): Promise<boolean> {
    await this.assertVerifyNotLocked(channel, identifier);

    const client = this.redis.getClient();
    const otpKey = this.otpKey(channel, identifier);
    const stored = await client.get(otpKey);

    if (!stored || stored !== code.trim()) {
      await this.recordFailedVerify(channel, identifier);
      return false;
    }

    await this.clearVerifyState(channel, identifier);
    await client.del(otpKey);
    return true;
  }

  private async assertVerifyNotLocked(
    channel: OtpChannel,
    identifier: string,
  ): Promise<void> {
    const client = this.redis.getClient();
    const ttl = await client.ttl(this.verifyLockKey(channel, identifier));

    if (ttl > 0) {
      throw new HttpException(
        {
          message: 'Too many failed verification attempts. Try again later.',
          retryAfterSeconds: ttl,
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private async recordFailedVerify(
    channel: OtpChannel,
    identifier: string,
  ): Promise<void> {
    const client = this.redis.getClient();
    const attemptsKey = this.verifyAttemptsKey(channel, identifier);
    const attempts = await client.incr(attemptsKey);

    if (attempts === 1) {
      await client.expire(attemptsKey, this.verifyAttemptWindowSeconds);
    }

    if (attempts < this.verifyMaxAttempts) {
      return;
    }

    const lockLevelKey = this.verifyLockLevelKey(channel, identifier);
    const lockLevel = Number(await client.get(lockLevelKey)) || 0;
    const lockoutSeconds = this.lockoutDurationSeconds(lockLevel);

    await client.set(
      this.verifyLockKey(channel, identifier),
      '1',
      'EX',
      lockoutSeconds,
    );
    await client.del(attemptsKey);
    await client.set(lockLevelKey, String(lockLevel + 1));
    await client.expire(lockLevelKey, this.lockoutLevelTtlSeconds);
  }

  private lockoutDurationSeconds(lockLevel: number): number {
    const raw =
      this.lockoutBaseSeconds * this.lockoutMultiplier ** lockLevel;
    return Math.min(Math.round(raw), this.lockoutMaxSeconds);
  }

  private async clearVerifyState(
    channel: OtpChannel,
    identifier: string,
  ): Promise<void> {
    const client = this.redis.getClient();
    await client.del(
      this.verifyAttemptsKey(channel, identifier),
      this.verifyLockKey(channel, identifier),
      this.verifyLockLevelKey(channel, identifier),
    );
  }

  private async assertRateLimit(
    channel: OtpChannel,
    identifier: string,
  ): Promise<void> {
    const client = this.redis.getClient();
    const count = Number(await client.get(this.rateKey(channel, identifier)));

    if (count >= this.rateLimitMax) {
      throw new HttpException(
        'Too many OTP requests. Try again later.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private otpKey(channel: OtpChannel, identifier: string): string {
    return `otp:${channel}:${identifier}`;
  }

  private rateKey(channel: OtpChannel, identifier: string): string {
    return `otp-rate:${channel}:${identifier}`;
  }

  private verifyAttemptsKey(channel: OtpChannel, identifier: string): string {
    return `otp-verify-attempts:${channel}:${identifier}`;
  }

  private verifyLockKey(channel: OtpChannel, identifier: string): string {
    return `otp-verify-lock:${channel}:${identifier}`;
  }

  private verifyLockLevelKey(channel: OtpChannel, identifier: string): string {
    return `otp-verify-lock-level:${channel}:${identifier}`;
  }
}
