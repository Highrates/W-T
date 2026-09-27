import { Logger } from '@nestjs/common';
import { GoogleAuth } from 'google-auth-library';
import { PushPayload } from './notifications.service';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

export class FcmV1Client {
  private readonly logger = new Logger(FcmV1Client.name);
  private readonly projectId: string;
  private readonly auth: GoogleAuth;

  constructor(projectId: string, serviceAccountJson: string) {
    this.projectId = projectId;
    const credentials = JSON.parse(serviceAccountJson) as Record<string, unknown>;
    this.auth = new GoogleAuth({
      credentials,
      scopes: [FCM_SCOPE],
    });
  }

  static fromEnv(
    projectId: string | undefined,
    serviceAccountJson: string | undefined,
  ): FcmV1Client | null {
    if (!projectId?.trim() || !serviceAccountJson?.trim()) {
      return null;
    }
    return new FcmV1Client(projectId.trim(), serviceAccountJson.trim());
  }

  async sendToToken(token: string, payload: PushPayload): Promise<void> {
    const client = await this.auth.getClient();
    const accessToken = await client.getAccessToken();
    const bearer = accessToken.token;

    if (!bearer) {
      throw new Error('FCM: failed to obtain access token');
    }

    const url = `https://fcm.googleapis.com/v1/projects/${this.projectId}/messages:send`;
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${bearer}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: {
            title: payload.title,
            body: payload.body,
          },
          data: payload.data ?? {},
        },
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      this.logger.warn(`FCM send failed (${response.status}): ${body}`);
      throw new Error(`FCM send failed (${response.status})`);
    }
  }
}
