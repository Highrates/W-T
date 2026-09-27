import {
  JoinMode,
  ParticipationStatus,
  RouteOccurrence,
  RoutePoint,
  User,
} from '@prisma/client';
import { resolveJoinStatus } from '../participation/participation.mapper';
import { FILTER_LABELS } from './feed-filters';

type OccurrenceWithRelations = RouteOccurrence & {
  city: { slug: string; name: string };
  organizer: Pick<User, 'id' | 'name' | 'avatarUrl' | 'phoneVerified' | 'emailVerified'>;
  points?: RoutePoint[];
};

type ParticipantPreview = {
  id: string;
  name: string | null;
  avatarUrl: string | null;
};

export type OccurrenceCardContext = {
  viewerParticipation?: { status: ParticipationStatus } | null;
  participants?: ParticipantPreview[];
};

export function buildTags(
  cityName: string,
  formatIds: string[],
  themeIds: string[],
): string[] {
  const tags = [cityName];
  for (const id of formatIds) {
    const label = FILTER_LABELS[id];
    if (label) tags.push(label);
  }
  for (const id of themeIds) {
    const label = FILTER_LABELS[id];
    if (label) tags.push(label);
  }
  return tags;
}

export function formatWhenLabel(
  startsAt: Date | null,
  hideExactTime: boolean,
): string | null {
  if (!startsAt) return null;

  if (hideExactTime) {
    const now = new Date();
    const sameDay =
      startsAt.getFullYear() === now.getFullYear() &&
      startsAt.getMonth() === now.getMonth() &&
      startsAt.getDate() === now.getDate();
    return sameDay ? 'Сегодня' : formatDate(startsAt);
  }

  const day = String(startsAt.getDate()).padStart(2, '0');
  const month = String(startsAt.getMonth() + 1).padStart(2, '0');
  const hour = String(startsAt.getHours()).padStart(2, '0');
  const minute = String(startsAt.getMinutes()).padStart(2, '0');
  return `${day}.${month} ${hour}:${minute}`;
}

function formatDate(date: Date): string {
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  return `${day}.${month}`;
}

export function pointsLabel(count: number): string {
  const mod10 = count % 10;
  const mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'точек';
  if (mod10 === 1) return 'точка';
  if (mod10 >= 2 && mod10 <= 4) return 'точки';
  return 'точек';
}

export function toFeedCard(
  occurrence: OccurrenceWithRelations,
  viewerId?: string,
  context: OccurrenceCardContext = {},
) {
  const pointCount = occurrence.points?.length ?? 0;
  const isVerified =
    occurrence.organizer.phoneVerified || occurrence.organizer.emailVerified;

  const joinStatus = resolveJoinStatus(
    occurrence,
    context.viewerParticipation ?? null,
    viewerId,
  );

  const participantItems = (context.participants ?? []).map((p) => ({
    id: p.id,
    name: p.name,
    avatarUrl: p.avatarUrl,
  }));

  return {
    id: occurrence.id,
    cityId: occurrence.city.slug,
    title: occurrence.title,
    description: occurrence.description,
    whenLabel: formatWhenLabel(occurrence.startsAt, occurrence.hideExactTime),
    isWhenHidden: occurrence.hideExactTime,
    goingLabel: `${occurrence.participantCount}/${occurrence.maxParticipants} идут`,
    routeMetric: 'points',
    routeMetricLabel: `${pointCount} ${pointsLabel(pointCount)}`,
    participants: participantItems,
    coverUrls: occurrence.coverUrls,
    organizer: {
      id: occurrence.organizer.id,
      name: occurrence.organizer.name ?? 'Организатор',
      avatarUrl: occurrence.organizer.avatarUrl,
      isVerified,
    },
    joinMode: occurrence.joinMode,
    ctaLabel:
      occurrence.joinMode === JoinMode.APPROVAL
        ? 'Отправить заявку'
        : 'Присоединиться!',
    joinStatus,
    tags: buildTags(
      occurrence.city.name,
      occurrence.formatIds,
      occurrence.themeIds,
    ),
    formatIds: occurrence.formatIds,
    themeIds: occurrence.themeIds,
    isOneOnOne: occurrence.isOneOnOne,
    startsAt: occurrence.startsAt?.toISOString() ?? null,
    publishedAt: occurrence.publishedAt.toISOString(),
    status: occurrence.status.toLowerCase(),
  };
}

export function toRoutePoint(point: RoutePoint) {
  return {
    id: point.id,
    title: point.title,
    latitude: point.latitude,
    longitude: point.longitude,
    address: point.address,
    detail: point.detail,
    description: point.description,
    photoUrls: point.photoUrls,
    poiId: point.poiId,
    sortOrder: point.sortOrder,
    isStart: point.isStart,
    isFinish: point.isFinish,
  };
}

export function toMapPin(occurrence: OccurrenceWithRelations) {
  return {
    id: occurrence.id,
    title: occurrence.title,
    latitude: occurrence.startLatitude,
    longitude: occurrence.startLongitude,
    startsAt: occurrence.startsAt?.toISOString() ?? null,
    coverUrl: occurrence.coverUrls[0] ?? null,
    subtitle: formatWhenLabel(occurrence.startsAt, occurrence.hideExactTime),
  };
}

export function toProfileEventPreview(
  occurrence: RouteOccurrence & { city?: { slug: string } },
  isPast = false,
) {
  return {
    eventId: occurrence.id,
    title: occurrence.title,
    coverUrl: occurrence.coverUrls[0] ?? null,
    whenLabel: formatWhenLabel(occurrence.startsAt, occurrence.hideExactTime),
    isWhenHidden: occurrence.hideExactTime,
    goingLabel: `${occurrence.participantCount}/${occurrence.maxParticipants} идут`,
    isPast,
  };
}
