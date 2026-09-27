import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import nodemailer from 'nodemailer';
import type { Transporter } from 'nodemailer';
import { EmailService } from './email.service';

@Injectable()
export class SmtpEmailService extends EmailService {
  private readonly logger = new Logger(SmtpEmailService.name);
  private transporter: Transporter | null = null;

  constructor(private readonly config: ConfigService) {
    super();
  }

  async sendOtp(email: string, code: string): Promise<void> {
    const stub = this.config.get<string>('EMAIL_STUB', 'false') === 'true';
    const pass = this.config.get<string>('SMTP_PASS');

    if (stub || !pass) {
      this.logger.log(`[Email stub] OTP for ${email}: ${code}`);
      return;
    }

    const from = this.config.get<string>(
      'EMAIL_FROM',
      'timescale.25@gmail.com',
    );
    const transporter = this.getTransporter();

    await transporter.sendMail({
      from: `"Выходи" <${from}>`,
      to: email,
      subject: 'Код подтверждения — Выходи',
      text: `Ваш код: ${code}\n\nКод действует 5 минут.`,
      html: `<p>Ваш код: <strong>${code}</strong></p><p>Код действует 5 минут.</p>`,
    });

    this.logger.log(`OTP email sent to ${email}`);
  }

  private getTransporter(): Transporter {
    if (this.transporter) return this.transporter;

    const host = this.config.get<string>('SMTP_HOST', 'smtp.gmail.com');
    const port = Number(this.config.get<string>('SMTP_PORT', '587'));
    const user = this.config.get<string>('SMTP_USER', 'timescale.25@gmail.com');
    const pass = this.config.get<string>('SMTP_PASS', '');

    this.transporter = nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: { user, pass },
    });

    return this.transporter;
  }
}
