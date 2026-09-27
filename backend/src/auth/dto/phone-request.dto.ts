import { IsNotEmpty, IsString, Matches } from 'class-validator';

export class PhoneRequestDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+?[0-9\s\-()]{10,18}$/, {
    message: 'phone must be a valid phone number',
  })
  phone!: string;
}
