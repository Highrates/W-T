import { IsEmail, IsNotEmpty, IsString, Length } from 'class-validator';

export class EmailVerifyDto {
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @IsString()
  @Length(6, 6)
  code!: string;
}
