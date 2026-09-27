import { IsNotEmpty, IsString, Length, Matches } from 'class-validator';

export class PhoneVerifyDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+?[0-9\s\-()]{10,18}$/)
  phone!: string;

  @IsString()
  @Length(6, 6)
  code!: string;
}
