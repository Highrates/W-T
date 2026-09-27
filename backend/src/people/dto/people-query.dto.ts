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

export class PeopleQueryDto {
  @IsOptional()
  @IsString()
  cityId?: string;

  /** Alias for mobile clients (`city_id=sochi`). */
  @IsOptional()
  @IsString()
  city_id?: string;

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

  /** Comma-separated interest filter ids */
  @IsOptional()
  @IsString()
  interests?: string;

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
