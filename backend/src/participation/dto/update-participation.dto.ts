import { IsIn, IsString } from 'class-validator';

export class UpdateParticipationDto {
  @IsString()
  @IsIn(['accepted', 'rejected'])
  status!: 'accepted' | 'rejected';
}
