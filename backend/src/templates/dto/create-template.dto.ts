import { IsUUID } from 'class-validator';

export class CreateTemplateDto {
  @IsUUID()
  occurrenceId!: string;
}
