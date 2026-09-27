import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service';

type Tx = Parameters<Parameters<PrismaService['$transaction']>[0]>[0];

export type OccurrenceLocationSync = {
  id: string;
  startLongitude: number;
  startLatitude: number;
  points: Array<{ id: string; longitude: number; latitude: number }>;
};

/** PostGIS ST_MakePoint expects longitude first, then latitude. */
export function makeGeographyPoint(lng: number, lat: number): Prisma.Sql {
  return Prisma.sql`ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography`;
}

@Injectable()
export class PostgisLocationService {
  /** Backfill `location` on route_occurrences + route_points after Prisma create. */
  async syncOccurrenceLocations(
    tx: Tx,
    occurrence: OccurrenceLocationSync,
  ): Promise<void> {
    await tx.$executeRaw`
      UPDATE route_occurrences
      SET location = ${makeGeographyPoint(
        occurrence.startLongitude,
        occurrence.startLatitude,
      )}
      WHERE id = ${occurrence.id}::uuid
    `;

    for (const point of occurrence.points) {
      await tx.$executeRaw`
        UPDATE route_points
        SET location = ${makeGeographyPoint(point.longitude, point.latitude)}
        WHERE id = ${point.id}::uuid
      `;
    }
  }

  withinRadius(
    locationColumn: Prisma.Sql,
    lng: number,
    lat: number,
    radiusM: number,
  ): Prisma.Sql {
    return Prisma.sql`ST_DWithin(${locationColumn}, ${makeGeographyPoint(lng, lat)}, ${radiusM})`;
  }
}
