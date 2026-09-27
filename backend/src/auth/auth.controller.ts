import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../common/guards/optional-jwt-auth.guard';
import { AuthService } from './auth.service';
import { AuthUser } from './auth.types';
import { EmailRequestDto } from './dto/email-request.dto';
import { EmailVerifyDto } from './dto/email-verify.dto';
import { PhoneRequestDto } from './dto/phone-request.dto';
import { PhoneVerifyDto } from './dto/phone-verify.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('phone/request')
  requestPhone(@Body() dto: PhoneRequestDto) {
    return this.auth.requestPhoneOtp(dto.phone);
  }

  @Post('phone/verify')
  @UseGuards(OptionalJwtAuthGuard)
  verifyPhone(
    @Body() dto: PhoneVerifyDto,
    @CurrentUser() user?: AuthUser | null,
  ) {
    return this.auth.verifyPhoneOtp(dto.phone, dto.code, user?.id);
  }

  @Post('phone/link/request')
  @UseGuards(JwtAuthGuard)
  linkPhoneRequest(@Body() dto: PhoneRequestDto) {
    return this.auth.requestPhoneOtp(dto.phone);
  }

  @Post('phone/link/verify')
  @UseGuards(JwtAuthGuard)
  linkPhoneVerify(
    @CurrentUser() user: AuthUser,
    @Body() dto: PhoneVerifyDto,
  ) {
    return this.auth.linkPhoneOtp(user.id, dto.phone, dto.code);
  }

  @Post('email/request')
  requestEmail(@Body() dto: EmailRequestDto) {
    return this.auth.requestEmailOtp(dto.email);
  }

  @Post('email/verify')
  @UseGuards(OptionalJwtAuthGuard)
  verifyEmail(
    @Body() dto: EmailVerifyDto,
    @CurrentUser() user?: AuthUser | null,
  ) {
    return this.auth.verifyEmailOtp(dto.email, dto.code, user?.id);
  }

  @Post('email/link/request')
  @UseGuards(JwtAuthGuard)
  linkEmailRequest(@Body() dto: EmailRequestDto) {
    return this.auth.requestEmailOtp(dto.email);
  }

  @Post('email/link/verify')
  @UseGuards(JwtAuthGuard)
  linkEmailVerify(
    @CurrentUser() user: AuthUser,
    @Body() dto: EmailVerifyDto,
  ) {
    return this.auth.linkEmailOtp(user.id, dto.email, dto.code);
  }

  @Post('refresh')
  refresh(@Body() dto: RefreshTokenDto) {
    return this.auth.refresh(dto.refreshToken);
  }

  @Post('logout')
  logout(@Body() dto: RefreshTokenDto) {
    return this.auth.logout(dto.refreshToken);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@CurrentUser() user: { id: string }) {
    return this.auth.getAuthMe(user.id);
  }
}
