import { Injectable } from '@nestjs/common';
import {
  FILTER_LABELS,
  FORMAT_FILTER_IDS,
  PARTICIPATION_FILTER_IDS,
  THEME_FILTER_IDS,
} from '../routes/feed-filters';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class MetaService {
  constructor(private readonly prisma: PrismaService) {}

  async listCities(activeOnly: boolean) {
    const cities = await this.prisma.city.findMany({
      where: activeOnly ? { occurrenceCount: { gt: 0 } } : undefined,
      orderBy: { name: 'asc' },
      select: {
        id: true,
        slug: true,
        name: true,
        countryCode: true,
        occurrenceCount: true,
      },
    });

    return { cities };
  }

  listFilters() {
    const toItem = (id: string, axis: string) => ({
      id,
      label: FILTER_LABELS[id] ?? id,
      axis,
    });

    return {
      participation: PARTICIPATION_FILTER_IDS.map((id) =>
        toItem(id, 'participation'),
      ),
      format: FORMAT_FILTER_IDS.map((id) => toItem(id, 'format')),
      theme: THEME_FILTER_IDS.map((id) => toItem(id, 'theme')),
    };
  }
}
