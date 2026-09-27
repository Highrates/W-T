import { IsEnum, IsString, Matches } from 'class-validator';

export enum MediaPurpose {
  COVER = 'cover',
  AVATAR = 'avatar',
  POINT = 'point',
}

export class PresignDto {
  @IsString()
  @Matches(/^(image\/(jpeg|png|webp)|application\/octet-stream)$/)
  contentType!: string;

  @IsEnum(MediaPurpose)
  purpose!: MediaPurpose;
}
