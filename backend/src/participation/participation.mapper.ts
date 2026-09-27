import {
  JoinMode,
  Participation,
  ParticipationStatus,
  RouteOccurrence,
} from '@prisma/client';

export type JoinStatusDto =
  | 'can_join'
  | 'pending'
  | 'approved'
  | 'full';

export function resolveJoinStatus(
  occurrence: Pick<
    RouteOccurrence,
    'organizerId' | 'participantCount' | 'maxParticipants' | 'joinMode'
  >,
  participation: Pick<Participation, 'status'> | null,
  viewerId?: string,
): JoinStatusDto {
  if (!viewerId) {
    return occurrence.participantCount >= occurrence.maxParticipants
      ? 'full'
      : 'can_join';
  }

  if (viewerId === occurrence.organizerId) {
    return 'approved';
  }

  if (participation?.status === ParticipationStatus.ACCEPTED) {
    return 'approved';
  }

  if (participation?.status === ParticipationStatus.PENDING) {
    return 'pending';
  }

  if (occurrence.participantCount >= occurrence.maxParticipants) {
    return 'full';
  }

  return 'can_join';
}

export function joinStatusToMobile(status: JoinStatusDto): JoinStatusDto {
  return status;
}

export function initialParticipationStatus(joinMode: JoinMode): ParticipationStatus {
  return joinMode === JoinMode.APPROVAL
    ? ParticipationStatus.PENDING
    : ParticipationStatus.ACCEPTED;
}
