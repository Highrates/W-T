import { Prisma } from '@prisma/client';
import {
  isFormatId,
  isParticipationId,
  isThemeId,
} from './feed-filters';

/** Parsed feed filters for SQL / Prisma (axes AND, within axis OR). */
export type FeedFilterCriteria = {
  participationOneOnOne?: boolean;
  formatIds: string[];
  themeIds: string[];
};

export function parseFeedFilterCriteria(
  selectedIds: Set<string>,
): FeedFilterCriteria {
  if (selectedIds.size === 0) {
    return { formatIds: [], themeIds: [] };
  }

  const participation = [...selectedIds].filter(isParticipationId);
  const formatIds = [...selectedIds].filter(isFormatId);
  const themeIds = [...selectedIds].filter(isThemeId);

  let participationOneOnOne: boolean | undefined;
  if (participation.length > 0) {
    const wantOne = participation.includes('one_on_one');
    const wantGroup = participation.includes('group');
    if (wantOne && !wantGroup) participationOneOnOne = true;
    else if (wantGroup && !wantOne) participationOneOnOne = false;
  }

  return { participationOneOnOne, formatIds, themeIds };
}

export function sqlFeedFilters(criteria: FeedFilterCriteria): Prisma.Sql {
  const clauses: Prisma.Sql[] = [];

  if (criteria.participationOneOnOne === true) {
    clauses.push(Prisma.sql`o.is_one_on_one = true`);
  } else if (criteria.participationOneOnOne === false) {
    clauses.push(Prisma.sql`o.is_one_on_one = false`);
  }

  if (criteria.formatIds.length > 0) {
    clauses.push(Prisma.sql`o.format_ids && ${criteria.formatIds}::text[]`);
  }

  if (criteria.themeIds.length > 0) {
    clauses.push(Prisma.sql`o.theme_ids && ${criteria.themeIds}::text[]`);
  }

  if (clauses.length === 0) {
    return Prisma.empty;
  }

  return Prisma.sql`AND ${Prisma.join(clauses, ' AND ')}`;
}

export function prismaFeedFilters(
  criteria: FeedFilterCriteria,
): Pick<
  import('@prisma/client').Prisma.RouteOccurrenceWhereInput,
  'isOneOnOne' | 'formatIds' | 'themeIds'
> {
  return {
    ...(criteria.participationOneOnOne !== undefined
      ? { isOneOnOne: criteria.participationOneOnOne }
      : {}),
    ...(criteria.formatIds.length > 0
      ? { formatIds: { hasSome: criteria.formatIds } }
      : {}),
    ...(criteria.themeIds.length > 0
      ? { themeIds: { hasSome: criteria.themeIds } }
      : {}),
  };
}
