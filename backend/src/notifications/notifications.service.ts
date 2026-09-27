import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { readFileSync } from 'fs';
import { PrismaService } from '../database/prisma.service';
import { FcmV1Client } from './fcm-v1.client';

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Push delivery: stub in dev (`PUSH_STUB=true`).
 * Production: FCM HTTP v1 via service account (`FCM_PROJECT_ID` + `FCM_SERVICE_ACCOUNT_JSON` or `_PATH`).
 */
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private readonly stub: boolean;
  private readonly fcm: FcmV1Client | null;

  constructor(
    private readonly prisma: PrismaService,
    config: ConfigService,
  ) {
    this.stub = config.get<string>('PUSH_STUB', 'true') === 'true';
    this.fcm = this.stub ? null : this.loadFcmClient(config);
  }

  async notifyUser(userId: string, payload: PushPayload): Promise<void> {
    const tokens = await this.prisma.deviceToken.findMany({
      where: { userId },
      select: { token: true, platform: true },
    });

    if (tokens.length === 0) {
      this.logger.debug(`No device tokens for user ${userId}`);
      return;
    }

    if (this.stub) {
      this.logger.log(
        `[Push stub] → user ${userId}: ${payload.title} — ${payload.body}`,
      );
      return;
    }

    if (!this.fcm) {
      this.logger.error(
        'Push disabled: set FCM_PROJECT_ID and FCM_SERVICE_ACCOUNT_JSON(_PATH), or PUSH_STUB=true',
      );
      return;
    }

    await Promise.allSettled(
      tokens.map(async ({ token }) => {
        try {
          await this.fcm!.sendToToken(token, payload);
        } catch (error) {
          this.logger.warn(`FCM token failed for user ${userId}: ${error}`);
        }
      }),
    );
  }

  private loadFcmClient(config: ConfigService): FcmV1Client | null {
    const projectId = config.get<string>('FCM_PROJECT_ID');
    const inline = config.get<string>('FCM_SERVICE_ACCOUNT_JSON');
    const path = config.get<string>('FCM_SERVICE_ACCOUNT_PATH');

    let serviceAccountJson = inline?.trim();
    if (!serviceAccountJson && path?.trim()) {
      serviceAccountJson = readFileSync(path.trim(), 'utf8');
    }

    const client = FcmV1Client.fromEnv(projectId, serviceAccountJson);
    if (!client) {
      this.logger.warn(
        'FCM not configured (FCM_PROJECT_ID + service account). Push will not send.',
      );
    }
    return client;
  }
}
