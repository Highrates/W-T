import { Global, Module } from '@nestjs/common';
import { PostgisLocationService } from './postgis-location.service';

@Global()
@Module({
  providers: [PostgisLocationService],
  exports: [PostgisLocationService],
})
export class PostgisModule {}
