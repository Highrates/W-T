import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import { AuthService } from './auth.service';
import { hashToken } from './auth.utils';
import { PrismaService } from '../database/prisma.service';
import { EmailService } from './email/email.service';
import { OtpService } from './otp/otp.service';
import { SmsService } from './sms/sms.service';

describe('AuthService.refresh', () => {
  const user = {
    id: '11111111-1111-1111-1111-111111111111',
    phone: '+79990001122',
    email: null,
    phoneVerified: true,
    emailVerified: false,
    role: UserRole.USER,
    isBlocked: false,
    name: null,
    avatarUrl: null,
    bio: null,
    cityId: null,
    lastActiveAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  it('rotates refresh token and returns a new session', async () => {
    const refreshToken = 'plain-refresh-token';
    const tokenHash = hashToken(refreshToken);

    const prisma = {
      refreshToken: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'rt-1',
          tokenHash,
          expiresAt: new Date(Date.now() + 60_000),
          user,
        }),
        delete: jest.fn().mockResolvedValue(undefined),
        create: jest.fn().mockResolvedValue(undefined),
      },
    } as unknown as PrismaService;

    const jwt = {
      signAsync: jest.fn().mockResolvedValue('new-access-token'),
    } as unknown as JwtService;

    const auth = new AuthService(
      prisma,
      jwt,
      {} as OtpService,
      {} as SmsService,
      {} as EmailService,
      new ConfigService({
        JWT_ACCESS_TTL: '15m',
        JWT_REFRESH_TTL: '30d',
      }),
    );

    const session = await auth.refresh(refreshToken);

    expect(session.accessToken).toBe('new-access-token');
    expect(session.refreshToken).not.toBe(refreshToken);
    expect(session.user.id).toBe(user.id);
    expect(prisma.refreshToken.delete).toHaveBeenCalledWith({ where: { id: 'rt-1' } });
    expect(prisma.refreshToken.create).toHaveBeenCalled();
  });

  it('rejects expired refresh tokens', async () => {
    const prisma = {
      refreshToken: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'rt-2',
          expiresAt: new Date(Date.now() - 1),
          user,
        }),
      },
    } as unknown as PrismaService;

    const auth = new AuthService(
      prisma,
      {} as JwtService,
      {} as OtpService,
      {} as SmsService,
      {} as EmailService,
      new ConfigService({ JWT_ACCESS_TTL: '15m', JWT_REFRESH_TTL: '30d' }),
    );

    await expect(auth.refresh('expired')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
