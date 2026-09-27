import { IsEnum, IsNotEmpty, IsString } from 'class-validator';

export enum DevicePlatformDto {
  IOS = 'ios',
  ANDROID = 'android',
}

export class RegisterDeviceDto {
  @IsString()
  @IsNotEmpty()
  token!: string;

  @IsEnum(DevicePlatformDto)
  platform!: DevicePlatformDto;
}

export class UnregisterDeviceDto {
  @IsString()
  @IsNotEmpty()
  token!: string;
}
