import { Injectable, NotFoundException } from '@nestjs/common';
import { City } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class CitiesService {
  constructor(private readonly prisma: PrismaService) {}

  async findBySlug(slug: string): Promise<City> {
    const city = await this.prisma.city.findUnique({ where: { slug } });
    if (!city) {
      throw new NotFoundException(`City not found: ${slug}`);
    }
    return city;
  }

  async findById(id: string): Promise<City> {
    const city = await this.prisma.city.findUnique({ where: { id } });
    if (!city) {
      throw new NotFoundException(`City not found: ${id}`);
    }
    return city;
  }

  /** Resolve city for occurrence from coordinates (nearest seeded city center). */
  async resolveFromCoordinates(
    latitude: number,
    longitude: number,
  ): Promise<City> {
    const cities = await this.prisma.city.findMany({
      where: { centerLat: { not: null }, centerLng: { not: null } },
    });

    if (cities.length === 0) {
      return this.findBySlug('sochi');
    }

    let best = cities[0];
    let bestDistance = Number.POSITIVE_INFINITY;

    for (const city of cities) {
      const distance = haversineKm(
        latitude,
        longitude,
        city.centerLat!,
        city.centerLng!,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        best = city;
      }
    }

    return best;
  }

  async resolveCityId(
    slugOrId: string | undefined,
    latitude: number,
    longitude: number,
  ): Promise<City> {
    if (slugOrId) {
      const bySlug = await this.prisma.city.findUnique({
        where: { slug: slugOrId },
      });
      if (bySlug) return bySlug;

      const byId = await this.prisma.city.findUnique({
        where: { id: slugOrId },
      });
      if (byId) return byId;
    }

    return this.resolveFromCoordinates(latitude, longitude);
  }

  async incrementOccurrenceCount(cityId: string, delta = 1): Promise<void> {
    await this.prisma.city.update({
      where: { id: cityId },
      data: { occurrenceCount: { increment: delta } },
    });
  }
}

function haversineKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.sqrt(a));
}
