import { Prisma } from '@prisma/client';
import {
  parseFeedFilterCriteria,
  prismaFeedFilters,
  sqlFeedFilters,
} from './feed-filter-criteria';

describe('feed filter criteria', () => {
  it('parses format, theme and one_on_one filters', () => {
    const criteria = parseFeedFilterCriteria(
      new Set(['walk', 'nature', 'one_on_one']),
    );

    expect(criteria).toEqual({
      participationOneOnOne: true,
      formatIds: ['walk'],
      themeIds: ['nature'],
    });
  });

  it('builds non-empty SQL when filters are selected', () => {
    const empty = sqlFeedFilters({ formatIds: [], themeIds: [] });
    const filtered = sqlFeedFilters({
      formatIds: ['walk'],
      themeIds: ['food'],
      participationOneOnOne: false,
    });

    expect(empty).toBe(Prisma.empty);
    expect(filtered).not.toBe(Prisma.empty);
  });

  it('maps to Prisma hasSome filters', () => {
    expect(
      prismaFeedFilters({
        formatIds: ['walk'],
        themeIds: ['nature'],
      }),
    ).toEqual({
      formatIds: { hasSome: ['walk'] },
      themeIds: { hasSome: ['nature'] },
    });
  });
});
