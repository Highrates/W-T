import { Type } from 'class-transformer';
import {
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

export class FeedQueryDto {
  @IsOptional()
  @IsString()
  cityId?: string;

  @IsOptional()
  @IsString()
  filters?: string;

  /** `lat,lng` — alias for nearLat/nearLng (mobile / MAPS.md). */
  @IsOptional()
  @IsString()
  near?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  nearLat?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  nearLng?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0.1)
  @Max(500)
  radiusKm?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0.1)
  @Max(500)
  radius_km?: number;

  @IsOptional()
  @IsUUID()
  cursor?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;
}

export class MapQueryDto {
  @IsOptional()
  @IsString()
  bbox?: string;

  @IsOptional()
  @IsString()
  near?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  nearLat?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  nearLng?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0.1)
  @Max(500)
  radiusKm?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0.1)
  @Max(500)
  radius_km?: number;

  @IsOptional()
  @IsString()
  cityId?: string;

  @IsOptional()
  @IsString()
  filters?: string;
}
