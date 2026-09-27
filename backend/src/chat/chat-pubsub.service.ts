import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { ChatMessagePayload } from './chat.types';

const CHANNEL_PREFIX = 'chat:room:';

@Injectable()
export class ChatPubSubService implements OnModuleDestroy {
  private readonly logger = new Logger(ChatPubSubService.name);
  private readonly publisher: Redis;
  private readonly subscriber: Redis;
  private readonly handlers = new Set<
    (roomId: string, message: ChatMessagePayload) => void
  >();

  constructor(config: ConfigService) {
    const url = config.get<string>('REDIS_URL', 'redis://localhost:6379');
    this.publisher = new Redis(url, { maxRetriesPerRequest: 3 });
    this.subscriber = new Redis(url, { maxRetriesPerRequest: 3 });
    void this.subscriber.psubscribe(`${CHANNEL_PREFIX}*`);
    this.subscriber.on('pmessage', (_pattern, channel, payload) => {
      const roomId = channel.slice(CHANNEL_PREFIX.length);
      try {
        const message = JSON.parse(payload) as ChatMessagePayload;
        for (const handler of this.handlers) {
          handler(roomId, message);
        }
      } catch (error) {
        this.logger.warn(
          `Invalid chat pubsub payload: ${error instanceof Error ? error.message : error}`,
        );
      }
    });
  }

  onMessage(handler: (roomId: string, message: ChatMessagePayload) => void) {
    this.handlers.add(handler);
    return () => this.handlers.delete(handler);
  }

  async publish(roomId: string, message: ChatMessagePayload) {
    await this.publisher.publish(
      `${CHANNEL_PREFIX}${roomId}`,
      JSON.stringify(message),
    );
  }

  async onModuleDestroy() {
    await Promise.allSettled([
      this.publisher.quit(),
      this.subscriber.quit(),
    ]);
  }
}
