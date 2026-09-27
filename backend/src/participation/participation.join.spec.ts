import { BadRequestException } from '@nestjs/common';
import {
  JoinMode,
  OccurrenceStatus,
  ParticipationStatus,
} from '@prisma/client';
import { MediaService } from '../media/media.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../database/prisma.service';
import { ParticipationService } from './participation.service';

type LockedRow = {
  id: string;
  organizer_id: string;
  title: string;
  join_mode: JoinMode;
  max_participants: number;
  participant_count: number;
  status: OccurrenceStatus;
};

/** Simulates DB row lock + conditional participant_count increment. */
function createJoinRacePrisma(initial: LockedRow) {
  const state = { ...initial, participations: new Map<string, ParticipationStatus>() };

  const tx = {
    $queryRaw: jest.fn(async (strings: TemplateStringsArray) => {
      const sql = strings.join('');
      if (sql.includes('FOR UPDATE')) {
        return [state];
      }
      if (sql.includes('participant_count + 1')) {
        if (state.participant_count >= state.max_participants) {
          return [];
        }
        state.participant_count += 1;
        return [{ participant_count: state.participant_count }];
      }
      return [];
    }),
    participation: {
      findUnique: jest.fn(async () => null),
      create: jest.fn(async ({ data }: { data: { userId: string } }) => {
        state.participations.set(data.userId, ParticipationStatus.ACCEPTED);
        return { id: `p-${data.userId}`, status: ParticipationStatus.ACCEPTED };
      }),
      update: jest.fn(),
    },
  };

  return {
    state,
    prisma: {
      $transaction: jest.fn(async (fn: (inner: typeof tx) => Promise<unknown>) =>
        fn(tx),
      ),
    } as unknown as PrismaService,
  };
}

describe('ParticipationService.join race', () => {
  const occurrenceId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const organizerId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  it('rejects join when event is already full', async () => {
    const { prisma } = createJoinRacePrisma({
      id: occurrenceId,
      organizer_id: organizerId,
      title: 'Walk',
      join_mode: JoinMode.AUTO,
      max_participants: 2,
      participant_count: 2,
      status: OccurrenceStatus.PUBLISHED,
    });

    const service = new ParticipationService(
      prisma,
      {} as MediaService,
      { notifyUser: jest.fn() } as unknown as NotificationsService,
    );

    await expect(
      service.join('cccccccc-cccc-cccc-cccc-cccccccccccc', occurrenceId),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('allows only remaining seats under concurrent joins', async () => {
    const { state, prisma } = createJoinRacePrisma({
      id: occurrenceId,
      organizer_id: organizerId,
      title: 'Walk',
      join_mode: JoinMode.AUTO,
      max_participants: 2,
      participant_count: 1,
      status: OccurrenceStatus.PUBLISHED,
    });

    const service = new ParticipationService(
      prisma,
      {} as MediaService,
      { notifyUser: jest.fn() } as unknown as NotificationsService,
    );

    const userIds = [
      'user-1',
      'user-2',
      'user-3',
      'user-4',
      'user-5',
    ];

    const results = await Promise.allSettled(
      userIds.map((userId) => service.join(userId, occurrenceId)),
    );

    const fulfilled = results.filter((result) => result.status === 'fulfilled');
    expect(fulfilled).toHaveLength(1);
    expect(state.participant_count).toBe(2);
  });
});
