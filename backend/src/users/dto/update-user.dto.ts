import {
  IsArray,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(80)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  bio?: string;

  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsUUID()
  cityId?: string | null;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  interestFilterIds?: string[];

  /** S3 key or presigned URL under `avatar/{userId}/`. Pass `null` to remove. */
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsString()
  @MaxLength(2048)
  avatarUrl?: string | null;
}
