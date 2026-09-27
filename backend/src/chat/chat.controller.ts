import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { ChatPubSubService } from './chat-pubsub.service';
import { ChatService } from './chat.service';
import { ChatMessagesQueryDto } from './dto/chat-messages-query.dto';
import { CreateChatMessageDto } from './dto/create-chat-message.dto';

@Controller('occurrences/:occurrenceId/chat')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(
    private readonly chat: ChatService,
    private readonly pubsub: ChatPubSubService,
  ) {}

  @Get('messages')
  listMessages(
    @CurrentUser() user: AuthUser,
    @Param('occurrenceId') occurrenceId: string,
    @Query() query: ChatMessagesQueryDto,
  ) {
    return this.chat.listMessages(user.id, occurrenceId, query);
  }

  @Post('messages')
  async sendMessage(
    @CurrentUser() user: AuthUser,
    @Param('occurrenceId') occurrenceId: string,
    @Body() dto: CreateChatMessageDto,
  ) {
    const message = await this.chat.sendMessage(
      user.id,
      occurrenceId,
      dto.body,
    );
    await this.pubsub.publish(message.roomId, message);
    return message;
  }
}
