import { ReportStatus } from '@prisma/client';
import {
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ReportModerationAction } from './report-moderation-action.enum';

const ADMIN_STATUSES = [
  ReportStatus.REVIEWED,
  ReportStatus.DISMISSED,
] as const;

export class AdminUpdateReportDto {
  @IsEnum(ADMIN_STATUSES)
  status!: (typeof ADMIN_STATUSES)[number];

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  moderatorNote?: string;

  /** Side effects when resolving a report (requires status `reviewed`). */
  @IsOptional()
  @IsArray()
  @IsEnum(ReportModerationAction, { each: true })
  actions?: ReportModerationAction[];
}
