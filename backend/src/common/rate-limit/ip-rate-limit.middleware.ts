import {
  HttpException,
  HttpStatus,
  Injectable,
  NestMiddleware,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NextFunction, Request, Response } from 'express';
import { parseTrustedProxyIps, resolveClientIp } from '../http/client-ip';
import { RateLimitGroup, RateLimitService } from './rate-limit.service';

@Injectable()
export class IpRateLimitMiddleware implements NestMiddleware {
  private readonly trustedProxies: Set<string>;

  constructor(
    private readonly rateLimit: RateLimitService,
    config: ConfigService,
  ) {
    this.trustedProxies = parseTrustedProxyIps(
      config.get<string>('TRUSTED_PROXY_IPS'),
    );
  }

  async use(req: Request, _res: Response, next: NextFunction) {
    const path = req.originalUrl.split('?')[0] ?? req.path;
    const group = matchRateLimitGroup(path);
    if (!group) {
      next();
      return;
    }

    const ip = resolveClientIp(req, this.trustedProxies);

    try {
      await this.rateLimit.assertAllowed(group, ip);
      next();
    } catch (error) {
      if (error instanceof HttpException) {
        next(error);
        return;
      }
      next(
        new HttpException(
          'Too many requests. Try again later.',
          HttpStatus.TOO_MANY_REQUESTS,
        ),
      );
    }
  }
}

function matchRateLimitGroup(path: string): RateLimitGroup | null {
  const normalized = path.replace(/^\/api(?=\/|$)/, '');
  if (normalized === '/auth' || normalized.startsWith('/auth/')) {
    return 'auth';
  }
  if (normalized === '/geo' || normalized.startsWith('/geo/')) {
    return 'geo';
  }
  if (normalized === '/reports' || normalized.startsWith('/reports/')) {
    return 'reports';
  }
  return null;
}
