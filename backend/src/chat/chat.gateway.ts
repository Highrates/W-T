import { Logger, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  OnGatewayInit,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { UserRole } from '@prisma/client';
import { IncomingMessage } from 'http';
import { URL } from 'url';
import { WebSocket, WebSocketServer as WsServer } from 'ws';
import { PrismaService } from '../database/prisma.service';
import { ChatPubSubService } from './chat-pubsub.service';
import { ChatService } from './chat.service';
import { ChatWsClientMessage, ChatWsServerMessage } from './chat.types';

type SocketMeta = {
  userId: string;
  roomId?: string;
  occurrenceId?: string;
};

@WebSocketGateway({ path: '/chat' })
export class ChatGateway implements OnGatewayInit {
  private readonly logger = new Logger(ChatGateway.name);
  private readonly socketsByRoom = new Map<string, Set<WebSocket>>();
  private readonly metaBySocket = new WeakMap<WebSocket, SocketMeta>();

  @WebSocketServer()
  server!: WsServer;

  constructor(
    private readonly chat: ChatService,
    private readonly pubsub: ChatPubSubService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  afterInit() {
    this.server.on('connection', (socket, request) => {
      void this.handleConnection(socket, request);
    });

    this.pubsub.onMessage((roomId, message) => {
      this.broadcast(roomId, { type: 'message', message });
    });
  }

  private async handleConnection(socket: WebSocket, request: IncomingMessage) {
    try {
      const userId = await this.authenticate(request);
      this.metaBySocket.set(socket, { userId });

      socket.on('message', (raw) => {
        void this.handleRawMessage(socket, raw);
      });

      socket.on('close', () => {
        this.detachSocket(socket);
      });
    } catch (error) {
      this.logger.debug(
        `Chat WS rejected: ${error instanceof Error ? error.message : error}`,
      );
      socket.close();
    }
  }

  private async handleRawMessage(socket: WebSocket, raw: unknown) {
    const meta = this.metaBySocket.get(socket);
    if (!meta) {
      socket.close();
      return;
    }

    let parsed: ChatWsClientMessage;
    try {
      parsed = JSON.parse(String(raw)) as ChatWsClientMessage;
    } catch {
      this.send(socket, { type: 'error', message: 'Invalid JSON' });
      return;
    }

    try {
      if (parsed.type === 'join') {
        await this.handleJoin(socket, meta, parsed.occurrenceId);
        return;
      }

      if (parsed.type === 'message') {
        await this.handleSend(socket, meta, parsed.body);
        return;
      }

      this.send(socket, { type: 'error', message: 'Unknown message type' });
    } catch (error) {
      this.send(socket, {
        type: 'error',
        message: error instanceof Error ? error.message : 'Request failed',
      });
    }
  }

  private async handleJoin(
    socket: WebSocket,
    meta: SocketMeta,
    occurrenceId: string,
  ) {
    this.detachSocket(socket);

    const room = await this.chat.ensureRoomForAccess(meta.userId, occurrenceId);
    meta.roomId = room.id;
    meta.occurrenceId = occurrenceId;
    this.metaBySocket.set(socket, meta);
    this.attachSocket(room.id, socket);

    this.send(socket, {
      type: 'joined',
      occurrenceId,
      roomId: room.id,
    });
  }

  private async handleSend(
    socket: WebSocket,
    meta: SocketMeta,
    body: string,
  ) {
    if (!meta.occurrenceId || !meta.roomId) {
      throw new Error('Join a room before sending messages');
    }

    const message = await this.chat.sendMessage(
      meta.userId,
      meta.occurrenceId,
      body,
    );
    await this.pubsub.publish(meta.roomId, message);
  }

  private attachSocket(roomId: string, socket: WebSocket) {
    const set = this.socketsByRoom.get(roomId) ?? new Set<WebSocket>();
    set.add(socket);
    this.socketsByRoom.set(roomId, set);
  }

  private detachSocket(socket: WebSocket) {
    const meta = this.metaBySocket.get(socket);
    if (!meta?.roomId) return;

    const set = this.socketsByRoom.get(meta.roomId);
    if (!set) return;

    set.delete(socket);
    if (set.size === 0) {
      this.socketsByRoom.delete(meta.roomId);
    }

    meta.roomId = undefined;
    meta.occurrenceId = undefined;
  }

  private broadcast(roomId: string, payload: ChatWsServerMessage) {
    const set = this.socketsByRoom.get(roomId);
    if (!set) return;

    const encoded = JSON.stringify(payload);
    for (const socket of set) {
      if (socket.readyState === WebSocket.OPEN) {
        socket.send(encoded);
      }
    }
  }

  private send(socket: WebSocket, payload: ChatWsServerMessage) {
    if (socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify(payload));
    }
  }

  private async authenticate(request: IncomingMessage): Promise<string> {
    const host = request.headers.host ?? 'localhost';
    const url = new URL(request.url ?? '/', `http://${host}`);
    const token =
      url.searchParams.get('token') ??
      this.extractBearer(request.headers.authorization);

    if (!token) {
      throw new UnauthorizedException('Missing token');
    }

    const payload = await this.jwt.verifyAsync<{ sub: string; role: UserRole }>(
      token,
      { secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET') },
    );

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: { id: true, isBlocked: true },
    });

    if (!user || user.isBlocked) {
      throw new UnauthorizedException('Invalid user');
    }

    return user.id;
  }

  private extractBearer(value?: string): string | null {
    if (!value) return null;
    const [scheme, token] = value.split(' ');
    if (scheme?.toLowerCase() !== 'bearer' || !token) return null;
    return token;
  }
}
