import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { parseDurationToSeconds } from './auth.utils';
import { SmtpEmailService } from './email/smtp-email.service';
import { EmailService } from './email/email.service';
import { OtpService } from './otp/otp.service';
import { SmsStubService } from './sms/sms-stub.service';
import { SmsService } from './sms/sms.service';
import { UnimatrixSmsService } from './sms/unimatrix-sms.service';
import { JwtStrategy } from './strategies/jwt.strategy';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.getOrThrow<string>('JWT_ACCESS_SECRET'),
        signOptions: {
          expiresIn: parseDurationToSeconds(
            config.get('JWT_ACCESS_TTL', '15m'),
          ),
        },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    OtpService,
    JwtStrategy,
    {
      provide: SmsService,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const stub = config.get<string>('SMS_STUB', 'true') === 'true';
        const apiKey = config.get<string>('UNIMATRIX_API_KEY');
        if (stub || !apiKey) {
          return new SmsStubService();
        }
        return new UnimatrixSmsService(config);
      },
    },
    {
      provide: EmailService,
      useClass: SmtpEmailService,
    },
  ],
  exports: [AuthService],
})
export class AuthModule {}
