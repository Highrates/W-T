import { UserRole } from '@prisma/client';
import { IsBoolean, IsEnum, IsOptional } from 'class-validator';

const ADMIN_ASSIGNABLE_ROLES = [
  UserRole.USER,
  UserRole.MODERATOR,
  UserRole.ADMIN,
] as const;

export class AdminUpdateUserDto {
  @IsOptional()
  @IsBoolean()
  isBlocked?: boolean;

  /** Only callers with role ADMIN may change this field. */
  @IsOptional()
  @IsEnum(ADMIN_ASSIGNABLE_ROLES)
  role?: UserRole;
}
