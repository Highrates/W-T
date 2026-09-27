import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { MediaModule } from '../media/media.module';
import { parseDurationToSeconds } from '../auth/auth.utils';
import { ChatController } from './chat.controller';
import { ChatGateway } from './chat.gateway';
import { ChatPubSubService } from './chat-pubsub.service';
import { ChatService } from './chat.service';

@Module({
  imports: [
    MediaModule,
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.getOrThrow<string>('JWT_ACCESS_SECRET'),
        signOptions: {
          expiresIn: parseDurationToSeconds(
            config.get('JWT_ACCESS_TTL', '15m'),
          ),
        },
      }),
    }),
  ],
  controllers: [ChatController],
  providers: [ChatService, ChatPubSubService, ChatGateway],
  exports: [ChatService],
})
export class ChatModule {}
