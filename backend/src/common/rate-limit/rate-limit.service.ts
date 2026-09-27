import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import { RedisService } from '../../redis/redis.service';
import {
  parseSlidingWindowEvalResult,
  SLIDING_WINDOW_RATE_LIMIT_SCRIPT,
} from './sliding-window.lua';

export type RateLimitGroup = 'auth' | 'geo' | 'reports';

export interface RateLimitResult {
  allowed: boolean;
  retryAfterSeconds: number;
}

@Injectable()
export class RateLimitService {
  private readonly limits: Record<
    RateLimitGroup,
    { max: number; windowSeconds: number }
  >;

  constructor(
    private readonly redis: RedisService,
    config: ConfigService,
  ) {
    this.limits = {
      auth: {
        max: Number(config.get('RATE_LIMIT_AUTH_MAX', 30)),
        windowSeconds: Number(config.get('RATE_LIMIT_AUTH_WINDOW_SECONDS', 60)),
      },
      geo: {
        max: Number(config.get('RATE_LIMIT_GEO_MAX', 60)),
        windowSeconds: Number(config.get('RATE_LIMIT_GEO_WINDOW_SECONDS', 60)),
      },
      reports: {
        max: Number(config.get('RATE_LIMIT_REPORTS_MAX', 10)),
        windowSeconds: Number(
          config.get('RATE_LIMIT_REPORTS_WINDOW_SECONDS', 300),
        ),
      },
    };
  }

  async check(group: RateLimitGroup, identifier: string): Promise<RateLimitResult> {
    const { max, windowSeconds } = this.limits[group];
    const windowMs = windowSeconds * 1000;
    const now = Date.now();
    const key = `rl:${group}:${identifier}`;
    const client = this.redis.getClient();
    const member = `${now}:${randomUUID()}`;

    const raw = await client.eval(
      SLIDING_WINDOW_RATE_LIMIT_SCRIPT,
      1,
      key,
      now,
      windowMs,
      max,
      member,
    );

    const { allowed, oldestScoreMs } = parseSlidingWindowEvalResult(raw);

    if (!allowed) {
      const retryAfterMs = Math.max(oldestScoreMs + windowMs - now, 1000);
      return {
        allowed: false,
        retryAfterSeconds: Math.ceil(retryAfterMs / 1000),
      };
    }

    return { allowed: true, retryAfterSeconds: 0 };
  }

  assertAllowed(group: RateLimitGroup, identifier: string): Promise<void> {
    return this.check(group, identifier).then((result) => {
      if (result.allowed) return;

      throw new HttpException(
        {
          message: 'Too many requests. Try again later.',
          retryAfterSeconds: result.retryAfterSeconds,
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    });
  }
}
