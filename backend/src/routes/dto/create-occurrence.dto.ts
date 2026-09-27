import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { CreatePointDto } from './create-point.dto';

export enum JoinModeDto {
  AUTO = 'auto',
  APPROVAL = 'approval',
}

export enum RouteSourceDto {
  BLANK = 'blank',
  FROM_PREVIOUS = 'fromPrevious',
  FROM_TEMPLATE = 'fromTemplate',
}

export class CreateOccurrenceDto {
  @IsOptional()
  @IsEnum(RouteSourceDto)
  source?: RouteSourceDto;

  @IsOptional()
  @IsUUID()
  sourceOccurrenceId?: string;

  @IsOptional()
  @IsUUID()
  templateId?: string;

  @IsString()
  @MinLength(3)
  @MaxLength(120)
  title!: string;

  @IsString()
  @MinLength(10)
  @MaxLength(5000)
  description!: string;

  @IsOptional()
  @IsString()
  cityId?: string;

  @IsArray()
  @IsString({ each: true })
  formatIds!: string[];

  @IsArray()
  @IsString({ each: true })
  themeIds!: string[];

  @IsOptional()
  @IsDateString()
  scheduledAt?: string;

  @IsOptional()
  @IsBoolean()
  hideExactTime?: boolean;

  @IsEnum(JoinModeDto)
  joinMode!: JoinModeDto;

  @IsInt()
  @Min(2)
  maxParticipants!: number;

  @IsOptional()
  @IsBoolean()
  isOneOnOne?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  coverUrls?: string[];

  @IsArray()
  @ArrayMinSize(2)
  @ValidateNested({ each: true })
  @Type(() => CreatePointDto)
  points!: CreatePointDto[];
}
