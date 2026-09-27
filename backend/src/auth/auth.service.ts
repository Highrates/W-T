import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { User, UserRole } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import {
  AuthSessionResponse,
  AuthUser,
  TokenPair,
} from './auth.types';
import {
  generateRefreshToken,
  hashToken,
  normalizeEmail,
  normalizePhone,
  parseDurationToSeconds,
} from './auth.utils';
import { EmailService } from './email/email.service';
import { OtpService } from './otp/otp.service';
import { SmsService } from './sms/sms.service';

@Injectable()
export class AuthService {
  private readonly accessTtlSeconds: number;
  private readonly refreshTtlSeconds: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly otp: OtpService,
    private readonly sms: SmsService,
    private readonly email: EmailService,
    config: ConfigService,
  ) {
    this.accessTtlSeconds = parseDurationToSeconds(
      config.get('JWT_ACCESS_TTL', '15m'),
    );
    this.refreshTtlSeconds = parseDurationToSeconds(
      config.get('JWT_REFRESH_TTL', '30d'),
    );
  }

  async requestPhoneOtp(rawPhone: string): Promise<{ ok: true }> {
    const phone = normalizePhone(rawPhone);
    const code = await this.otp.issue('phone', phone);
    await this.sms.sendOtp(phone, code);
    return { ok: true };
  }

  async verifyPhoneOtp(
    rawPhone: string,
    code: string,
    linkUserId?: string,
  ): Promise<AuthSessionResponse> {
    const phone = normalizePhone(rawPhone);
    const valid = await this.otp.verify('phone', phone, code);

    if (!valid) {
      throw new BadRequestException('Invalid or expired code');
    }

    const user = linkUserId
      ? await this.attachPhoneToUser(linkUserId, phone)
      : await this.signInOrCreateByPhone(phone);

    return this.createSession(user);
  }

  async requestEmailOtp(rawEmail: string): Promise<{ ok: true }> {
    const email = normalizeEmail(rawEmail);
    const code = await this.otp.issue('email', email);
    await this.email.sendOtp(email, code);
    return { ok: true };
  }

  async verifyEmailOtp(
    rawEmail: string,
    code: string,
    linkUserId?: string,
  ): Promise<AuthSessionResponse> {
    const email = normalizeEmail(rawEmail);
    const valid = await this.otp.verify('email', email, code);

    if (!valid) {
      throw new BadRequestException('Invalid or expired code');
    }

    const user = linkUserId
      ? await this.attachEmailToUser(linkUserId, email)
      : await this.signInOrCreateByEmail(email);

    return this.createSession(user);
  }

  /** JWT + OTP: привязать телефон к текущему аккаунту. */
  async linkPhoneOtp(
    userId: string,
    rawPhone: string,
    code: string,
  ): Promise<AuthSessionResponse> {
    return this.verifyPhoneOtp(rawPhone, code, userId);
  }

  /** JWT + OTP: привязать email к текущему аккаунту. */
  async linkEmailOtp(
    userId: string,
    rawEmail: string,
    code: string,
  ): Promise<AuthSessionResponse> {
    return this.verifyEmailOtp(rawEmail, code, userId);
  }

  async refresh(refreshToken: string): Promise<AuthSessionResponse> {
    const tokenHash = hashToken(refreshToken);
    const stored = await this.prisma.refreshToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    });

    if (!stored || stored.expiresAt < new Date() || stored.user.isBlocked) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    await this.prisma.refreshToken.delete({ where: { id: stored.id } });

    return this.createSession(stored.user);
  }

  async logout(refreshToken: string): Promise<{ ok: true }> {
    const tokenHash = hashToken(refreshToken);
    await this.prisma.refreshToken.deleteMany({ where: { tokenHash } });
    return { ok: true };
  }

  async getAuthMe(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        id: true,
        phone: true,
        email: true,
        phoneVerified: true,
        emailVerified: true,
        role: true,
        isBlocked: true,
      },
    });

    return user;
  }

  async touchLastActive(user: AuthUser): Promise<void> {
    await this.prisma.$executeRaw`
      UPDATE users
      SET last_active_at = NOW()
      WHERE id = ${user.id}::uuid
      AND (
        last_active_at IS NULL
        OR last_active_at < NOW() - INTERVAL '5 minutes'
      )
    `;
  }

  hasVerifiedContact(user: Pick<User, 'phoneVerified' | 'emailVerified'>): boolean {
    return user.phoneVerified || user.emailVerified;
  }

  private async signInOrCreateByPhone(phone: string): Promise<User> {
    return this.prisma.user.upsert({
      where: { phone },
      create: { phone, phoneVerified: true, lastActiveAt: new Date() },
      update: { phoneVerified: true, lastActiveAt: new Date() },
    });
  }

  private async signInOrCreateByEmail(email: string): Promise<User> {
    return this.prisma.user.upsert({
      where: { email },
      create: { email, emailVerified: true, lastActiveAt: new Date() },
      update: { emailVerified: true, lastActiveAt: new Date() },
    });
  }

  private async attachPhoneToUser(userId: string, phone: string): Promise<User> {
    const owner = await this.prisma.user.findUnique({ where: { phone } });
    if (owner && owner.id !== userId) {
      throw new ConflictException(
        'This phone is already linked to another account',
      );
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: { phone, phoneVerified: true, lastActiveAt: new Date() },
    });
  }

  private async attachEmailToUser(userId: string, email: string): Promise<User> {
    const owner = await this.prisma.user.findUnique({ where: { email } });
    if (owner && owner.id !== userId) {
      throw new ConflictException(
        'This email is already linked to another account',
      );
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: { email, emailVerified: true, lastActiveAt: new Date() },
    });
  }

  private async createSession(user: User): Promise<AuthSessionResponse> {
    if (user.isBlocked) {
      throw new UnauthorizedException('Account is blocked');
    }

    const tokens = await this.issueTokens(user.id, user.role);

    return {
      ...tokens,
      user: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        phoneVerified: user.phoneVerified,
        emailVerified: user.emailVerified,
        role: user.role,
        isBlocked: user.isBlocked,
      },
    };
  }

  private async issueTokens(userId: string, role: UserRole): Promise<TokenPair> {
    const accessToken = await this.jwt.signAsync({ sub: userId, role });
    const refreshToken = generateRefreshToken();
    const expiresAt = new Date(Date.now() + this.refreshTtlSeconds * 1000);

    await this.prisma.refreshToken.create({
      data: {
        userId,
        tokenHash: hashToken(refreshToken),
        expiresAt,
      },
    });

    return {
      accessToken,
      refreshToken,
      expiresIn: this.accessTtlSeconds,
    };
  }
}
