import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SmsService } from './sms.service';

/**
 * Unimatrix SMS integration.
 * Falls back to logging when API key is missing (same as stub).
 */
@Injectable()
export class UnimatrixSmsService extends SmsService {
  private readonly logger = new Logger(UnimatrixSmsService.name);

  constructor(private readonly config: ConfigService) {
    super();
  }

  async sendOtp(phone: string, code: string): Promise<void> {
    const apiKey = this.config.get<string>('UNIMATRIX_API_KEY');
    const sender = this.config.get<string>('UNIMATRIX_SENDER', 'WalkTalk');
    const stub = this.config.get<string>('SMS_STUB', 'true') === 'true';

    if (stub || !apiKey) {
      this.logger.log(`[Unimatrix stub] OTP for ${phone}: ${code}`);
      return;
    }

    const body = {
      to: phone,
      text: `Код для Выходи: ${code}`,
      from: sender,
    };

    const response = await fetch('https://api.unimtx.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const text = await response.text();
      this.logger.error(`Unimatrix SMS failed: ${response.status} ${text}`);
      throw new Error('Failed to send SMS');
    }
  }
}
