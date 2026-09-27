import { Injectable, Logger } from '@nestjs/common';
import { SmsService } from './sms.service';

@Injectable()
export class SmsStubService extends SmsService {
  private readonly logger = new Logger(SmsStubService.name);

  async sendOtp(phone: string, code: string): Promise<void> {
    this.logger.log(`[SMS stub] OTP for ${phone}: ${code}`);
  }
}
