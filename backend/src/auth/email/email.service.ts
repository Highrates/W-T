export abstract class EmailService {
  abstract sendOtp(email: string, code: string): Promise<void>;
}
