import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MediaPurpose } from './dto/presign.dto';
import { MediaService } from './media.service';

describe('MediaService ownership', () => {
  const userId = '11111111-1111-1111-1111-111111111111';
  let media: MediaService;

  beforeEach(() => {
    media = new MediaService(
      new ConfigService({
        S3_STUB: 'true',
        S3_PUBLIC_BASE_URL: 'http://localhost:9000/walktalk',
        MEDIA_HEAD_OBJECT_VERIFY: 'false',
      }),
    );
  });

  it('accepts keys and signed URLs under avatar/{userId}/', async () => {
    await expect(
      media.assertUrlsOwned(
        userId,
        [
          `avatar/${userId}/photo.jpg`,
          `http://localhost:9000/walktalk/avatar/${userId}/photo.jpg`,
        ],
        MediaPurpose.AVATAR,
      ),
    ).resolves.toBeUndefined();
  });

  it('rejects media owned by another user', async () => {
    await expect(
      media.assertUrlsOwned(
        userId,
        [`avatar/22222222-2222-2222-2222-222222222222/evil.jpg`],
        MediaPurpose.AVATAR,
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects wrong purpose prefix on publish', async () => {
    await expect(
      media.assertUrlsOwned(
        userId,
        [`cover/${userId}/hero.jpg`],
        MediaPurpose.AVATAR,
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('HeadObject-checks when MEDIA_HEAD_OBJECT_VERIFY=true', async () => {
    const verifying = new MediaService(
      new ConfigService({
        S3_STUB: 'false',
        S3_BUCKET: 'walktalk',
        S3_PUBLIC_BASE_URL: 'http://localhost:9000/walktalk',
        MEDIA_HEAD_OBJECT_VERIFY: 'true',
      }),
    );

    const client = (verifying as unknown as { client: { send: jest.Mock } }).client;
    client.send = jest
      .fn()
      .mockResolvedValueOnce({})
      .mockRejectedValueOnce(new Error('NotFound'));

    const key = `avatar/${userId}/ok.jpg`;

    await expect(
      verifying.assertUrlsOwned(userId, [key], MediaPurpose.AVATAR),
    ).resolves.toBeUndefined();

    await expect(
      verifying.assertUrlsOwned(userId, [`avatar/${userId}/missing.jpg`], MediaPurpose.AVATAR),
    ).rejects.toThrow(/not found/i);

    expect(client.send).toHaveBeenCalled();
  });
});
