import { Module } from '@nestjs/common';
import { RedisModule } from '../../redis/redis.module';
import { IpRateLimitMiddleware } from './ip-rate-limit.middleware';
import { RateLimitService } from './rate-limit.service';

@Module({
  imports: [RedisModule],
  providers: [RateLimitService, IpRateLimitMiddleware],
  exports: [RateLimitService, IpRateLimitMiddleware],
})
export class RateLimitModule {}
