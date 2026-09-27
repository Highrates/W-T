import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

export enum OccurrenceLifecycleAction {
  CANCEL = 'cancel',
  HIDE = 'hide',
  REPUBLISH = 'republish',
}

/** Редактирование опубликованного события организатором. */
export class UpdateOccurrenceDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  title?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(4000)
  description?: string;

  @IsOptional()
  @IsDateString()
  scheduledAt?: string | null;

  @IsOptional()
  @IsBoolean()
  hideExactTime?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  coverUrls?: string[];

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(2)
  maxParticipants?: number;
}

export class OccurrenceLifecycleDto {
  @IsEnum(OccurrenceLifecycleAction)
  action!: OccurrenceLifecycleAction;
}
