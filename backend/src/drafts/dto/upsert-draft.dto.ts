import { IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpsertDraftDto {
  @IsOptional()
  @IsString()
  @MaxLength(64)
  step?: string;

  @IsObject()
  draft!: Record<string, unknown>;
}
