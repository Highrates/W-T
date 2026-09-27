import { Controller, Get, Query } from '@nestjs/common';
import { PeopleQueryDto } from './dto/people-query.dto';
import { PeopleService } from './people.service';

@Controller('people')
export class PeopleController {
  constructor(private readonly people: PeopleService) {}

  @Get()
  list(@Query() query: PeopleQueryDto) {
    return this.people.list(query);
  }
}
