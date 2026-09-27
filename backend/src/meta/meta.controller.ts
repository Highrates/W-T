import { Controller, Get, Query } from '@nestjs/common';
import { MetaService } from './meta.service';

@Controller('meta')
export class MetaController {
  constructor(private readonly meta: MetaService) {}

  @Get('cities')
  listCities(@Query('active_only') activeOnly?: string) {
    return this.meta.listCities(activeOnly === 'true');
  }

  @Get('filters')
  listFilters() {
    return this.meta.listFilters();
  }
}
