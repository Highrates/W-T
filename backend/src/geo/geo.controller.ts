import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
  Query,
} from '@nestjs/common';
import { GeoService } from './geo.service';

@Controller('geo')
export class GeoController {
  constructor(private readonly geo: GeoService) {}

  @Get('suggest')
  suggest(
    @Query('q') query?: string,
    @Query('ll') ll?: string,
    @Query('types') _types?: string,
  ) {
    const q = query?.trim();
    if (!q || q.length < 2) {
      throw new BadRequestException('Query q must be at least 2 characters');
    }

    return this.geo.suggest(q, ll);
  }

  @Post('geocode')
  reverseGeocode(
    @Body() body: { latitude?: number; longitude?: number },
  ) {
    const { latitude, longitude } = body;
    if (
      latitude == null ||
      longitude == null ||
      Number.isNaN(latitude) ||
      Number.isNaN(longitude)
    ) {
      throw new BadRequestException('latitude and longitude are required');
    }

    return this.geo.reverseGeocode(latitude, longitude);
  }
}
