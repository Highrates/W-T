import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  OccurrenceStatus,
  ParticipationStatus,
  RouteOccurrence,
} from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import { MediaService } from '../media/media.service';
import { NotificationsService } from '../notifications/notifications.service';
import { ChatMessagesQueryDto } from './dto/chat-messages-query.dto';
import { ChatMessagePayload } from './chat.types';

@Injectable()
export class ChatService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly media: MediaService,
    private readonly notifications: NotificationsService,
  ) {}

  async listMessages(
    userId: string,
    occurrenceId: string,
    query: ChatMessagesQueryDto,
  ) {
    const room = await this.ensureRoomForAccess(userId, occurrenceId);
    const limit = query.limit ?? 50;

    const rows = await this.prisma.message.findMany({
      where: { roomId: room.id },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      ...(query.cursor
        ? {
            cursor: { id: query.cursor },
            skip: 1,
          }
        : {}),
      include: {
        sender: {
          select: { id: true, name: true, avatarUrl: true },
        },
      },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const chronological = [...page].reverse();

    const items = await Promise.all(
      chronological.map((row) => this.toPayload(room.occurrenceId, row)),
    );

    return {
      roomId: room.id,
      occurrenceId: room.occurrenceId,
      items,
      nextCursor: hasMore ? page[page.length - 1]?.id ?? null : null,
    };
  }

  async sendMessage(
    userId: string,
    occurrenceId: string,
    body: string,
  ): Promise<ChatMessagePayload> {
    const trimmed = body.trim();
    if (!trimmed) {
      throw new BadRequestException('Message body is required');
    }

    const room = await this.ensureRoomForAccess(userId, occurrenceId);

    const message = await this.prisma.message.create({
      data: {
        roomId: room.id,
        senderId: userId,
        body: trimmed,
      },
      include: {
        sender: {
          select: { id: true, name: true, avatarUrl: true },
        },
      },
    });

    const payload = await this.toPayload(room.occurrenceId, message);
    void this.notifyParticipants(room.occurrenceId, userId, payload);
    return payload;
  }

  async ensureRoomForAccess(userId: string, occurrenceId: string) {
    const occurrence = await this.assertChatAccess(userId, occurrenceId);

    const room = await this.prisma.chatRoom.upsert({
      where: { occurrenceId },
      create: { occurrenceId },
      update: {},
    });

    return { ...room, occurrence };
  }

  async assertChatAccess(
    userId: string,
    occurrenceId: string,
  ): Promise<RouteOccurrence> {
    const occurrence = await this.prisma.routeOccurrence.findUnique({
      where: { id: occurrenceId },
    });

    if (!occurrence) {
      throw new NotFoundException('Occurrence not found');
    }

    if (occurrence.status === OccurrenceStatus.CANCELLED) {
      throw new BadRequestException('Chat is closed for cancelled events');
    }

    if (occurrence.organizerId === userId) {
      return occurrence;
    }

    const participation = await this.prisma.participation.findUnique({
      where: {
        occurrenceId_userId: { occurrenceId, userId },
      },
    });

    if (
      !participation ||
      participation.status !== ParticipationStatus.ACCEPTED
    ) {
      throw new ForbiddenException('Only accepted participants can access chat');
    }

    return occurrence;
  }

  private async toPayload(
    occurrenceId: string,
    row: {
      id: string;
      roomId: string;
      body: string;
      createdAt: Date;
      sender: { id: string; name: string | null; avatarUrl: string | null };
    },
  ): Promise<ChatMessagePayload> {
    return {
      id: row.id,
      roomId: row.roomId,
      occurrenceId,
      sender: {
        id: row.sender.id,
        name: row.sender.name,
        avatarUrl: await this.media.signOptionalRef(row.sender.avatarUrl),
      },
      body: row.body,
      createdAt: row.createdAt.toISOString(),
    };
  }

  private async notifyParticipants(
    occurrenceId: string,
    senderId: string,
    message: ChatMessagePayload,
  ) {
    const occurrence = await this.prisma.routeOccurrence.findUnique({
      where: { id: occurrenceId },
      select: {
        title: true,
        organizerId: true,
        participations: {
          where: { status: ParticipationStatus.ACCEPTED },
          select: { userId: true },
        },
      },
    });

    if (!occurrence) return;

    const recipientIds = new Set<string>([occurrence.organizerId]);
    for (const row of occurrence.participations) {
      recipientIds.add(row.userId);
    }
    recipientIds.delete(senderId);

    const senderLabel = message.sender.name?.trim() || 'Участник';
    await Promise.allSettled(
      [...recipientIds].map((userId) =>
        this.notifications.notifyUser(userId, {
          title: occurrence.title,
          body: `${senderLabel}: ${this.previewBody(message.body)}`,
          data: { occurrenceId, chatMessageId: message.id },
        }),
      ),
    );
  }

  private previewBody(body: string): string {
    const trimmed = body.trim();
    if (trimmed.length <= 120) return trimmed;
    return `${trimmed.slice(0, 117)}…`;
  }
}
