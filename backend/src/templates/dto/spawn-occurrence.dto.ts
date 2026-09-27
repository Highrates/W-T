import { JoinModeDto } from '../../routes/dto/create-occurrence.dto';
import {
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

export class SpawnOccurrenceDto {
  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(120)
  title?: string;

  @IsDateString()
  scheduledAt!: string;

  @IsOptional()
  @IsBoolean()
  hideExactTime?: boolean;

  @IsOptional()
  @IsEnum(JoinModeDto)
  joinMode?: JoinModeDto;

  @IsOptional()
  @IsInt()
  @Min(2)
  maxParticipants?: number;
}
