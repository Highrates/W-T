import {
  BadRequestException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  GetObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'crypto';
import { isDevelopment } from '../config/env';
import { MediaPurpose } from './dto/presign.dto';

@Injectable()
export class MediaService {
  private readonly logger = new Logger(MediaService.name);
  private readonly client: S3Client;
  private readonly bucket: string;
  private readonly publicBaseUrl: string;
  private readonly stub: boolean;
  private readonly publicRead: boolean;
  private readonly uploadExpiresIn: number;
  private readonly readExpiresIn: number;
  /** When true, assertUrlsOwned also HeadObject-checks S3 (skipped in stub mode). */
  private readonly headObjectVerify: boolean;

  constructor(private readonly config: ConfigService) {
    this.bucket = config.get<string>('S3_BUCKET', 'walktalk');
    this.publicBaseUrl = config.get<string>(
      'S3_PUBLIC_BASE_URL',
      'http://localhost:9000/walktalk',
    ).replace(/\/+$/, '');
    this.stub = config.get<string>('S3_STUB', 'false') === 'true';
    this.publicRead = resolvePublicRead(config);
    this.uploadExpiresIn = Number(config.get('S3_UPLOAD_URL_TTL_SECONDS', 900));
    this.readExpiresIn = Number(config.get('S3_READ_URL_TTL_SECONDS', 3600));
    this.headObjectVerify =
      config.get<string>('MEDIA_HEAD_OBJECT_VERIFY', 'false') === 'true';

    this.client = new S3Client({
      region: config.get<string>('S3_REGION', 'us-east-1'),
      endpoint: config.get<string>('S3_ENDPOINT', 'http://localhost:9000'),
      forcePathStyle: true,
      credentials: {
        accessKeyId: config.get<string>('S3_ACCESS_KEY', 'walktalk'),
        secretAccessKey: config.get<string>('S3_SECRET_KEY', 'walktalksecret'),
      },
    });
  }

  async presign(userId: string, contentType: string, purpose: MediaPurpose) {
    const ext = extensionForContentType(contentType);
    const key = `${purpose}/${userId}/${randomUUID()}${ext}`;

    if (this.stub) {
      const publicUrl = `${this.publicBaseUrl}/${key}`;
      this.logger.log(`[S3 stub] presign ${key}`);
      return {
        key,
        uploadUrl: publicUrl,
        readUrl: publicUrl,
        expiresIn: this.uploadExpiresIn,
      };
    }

    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(this.client, command, {
      expiresIn: this.uploadExpiresIn,
    });

    const readUrl = await this.signReadUrl(key);

    return {
      key,
      uploadUrl,
      readUrl,
      expiresIn: this.uploadExpiresIn,
    };
  }

  async assertUrlsOwned(
    userId: string,
    urls: string[],
    purpose: MediaPurpose,
  ): Promise<void> {
    const prefix = `${purpose}/${userId}/`;

    for (const raw of urls) {
      if (!raw?.trim()) continue;

      const key = this.extractObjectKey(raw);
      if (!key.startsWith(prefix)) {
        throw new BadRequestException(
          `Media must be uploaded under ${prefix} (got ${key})`,
        );
      }

      if (this.headObjectVerify) {
        await this.verifyObjectExists(key);
      }
    }
  }

  private async verifyObjectExists(key: string): Promise<void> {
    if (this.stub) return;

    try {
      await this.client.send(
        new HeadObjectCommand({ Bucket: this.bucket, Key: key }),
      );
    } catch {
      throw new BadRequestException(`Media object not found: ${key}`);
    }
  }

  normalizeToKeys(urls: string[]): string[] {
    return urls
      .map((item) => this.extractObjectKey(item))
      .filter((key) => key.length > 0);
  }

  extractObjectKey(urlOrKey: string): string {
    const trimmed = urlOrKey.trim();
    if (!trimmed) return '';

    if (!trimmed.includes('://')) {
      return trimmed.replace(/^\/+/, '');
    }

    try {
      const url = new URL(trimmed);
      let path = decodeURIComponent(url.pathname.replace(/^\/+/, ''));

      if (path.startsWith(`${this.bucket}/`)) {
        path = path.slice(this.bucket.length + 1);
      }

      return path;
    } catch {
      return trimmed.replace(/^\/+/, '');
    }
  }

  isManagedMediaRef(value: string | null | undefined): boolean {
    if (!value?.trim()) return false;
    const key = this.extractObjectKey(value);
    return /^(cover|avatar|point)\/[^/]+\/.+/.test(key);
  }

  async signReadUrl(keyOrUrl: string | null | undefined): Promise<string | null> {
    if (!keyOrUrl?.trim()) return null;

    const key = this.extractObjectKey(keyOrUrl);
    if (!key) return keyOrUrl;

    if (this.publicRead || this.stub) {
      return `${this.publicBaseUrl}/${key}`;
    }

    const command = new GetObjectCommand({
      Bucket: this.bucket,
      Key: key,
    });

    return getSignedUrl(this.client, command, {
      expiresIn: this.readExpiresIn,
    });
  }

  async signReadUrls(keysOrUrls: string[]): Promise<string[]> {
    const signed = await Promise.all(
      keysOrUrls.map((item) => this.signReadUrl(item)),
    );
    return signed.filter((url): url is string => url != null);
  }

  async signOptionalRef(
    value: string | null | undefined,
  ): Promise<string | null> {
    if (!value?.trim()) return null;
    if (!this.isManagedMediaRef(value)) return value;
    return this.signReadUrl(value);
  }

  async signOccurrenceRow<
    T extends {
      coverUrls: string[];
      points: Array<{ photoUrls: string[] }>;
      organizer: { avatarUrl: string | null };
    },
  >(row: T): Promise<T> {
    const coverUrls = await this.signReadUrls(row.coverUrls);
    const points = await Promise.all(
      row.points.map(async (point) => ({
        ...point,
        photoUrls: await this.signReadUrls(point.photoUrls),
      })),
    );
    const avatarUrl = await this.signOptionalRef(row.organizer.avatarUrl);

    return {
      ...row,
      coverUrls,
      points,
      organizer: {
        ...row.organizer,
        avatarUrl,
      },
    };
  }

  async signProfileEventPreview<
    T extends { coverUrl: string | null },
  >(preview: T): Promise<T> {
    const coverUrl = preview.coverUrl
      ? await this.signOptionalRef(preview.coverUrl)
      : null;
    return { ...preview, coverUrl };
  }
}

function resolvePublicRead(config: ConfigService): boolean {
  const explicit = config.get<string>('S3_PUBLIC_READ');
  if (explicit === 'true') return true;
  if (explicit === 'false') return false;
  return isDevelopment();
}

function extensionForContentType(contentType: string): string {
  switch (contentType) {
    case 'image/png':
      return '.png';
    case 'image/webp':
      return '.webp';
    default:
      return '.jpg';
  }
}
