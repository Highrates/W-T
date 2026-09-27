import { Injectable } from '@nestjs/common';
import { PushPlatform } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import { DevicePlatformDto } from './dto/register-device.dto';

@Injectable()
export class DevicesService {
  constructor(private readonly prisma: PrismaService) {}

  async register(userId: string, token: string, platform: DevicePlatformDto) {
    const pushPlatform =
      platform === DevicePlatformDto.IOS ? PushPlatform.IOS : PushPlatform.ANDROID;

    await this.prisma.deviceToken.upsert({
      where: { token },
      create: { userId, token, platform: pushPlatform },
      update: { userId, platform: pushPlatform },
    });

    return { ok: true };
  }

  async unregister(userId: string, token: string) {
    await this.prisma.deviceToken.deleteMany({
      where: { token, userId },
    });
    return { ok: true };
  }
}
