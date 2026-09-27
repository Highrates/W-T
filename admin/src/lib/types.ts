export type UserRole = 'USER' | 'MODERATOR' | 'ADMIN' | 'user' | 'moderator' | 'admin'

export type AuthUser = {
  id: string
  phone: string | null
  email: string | null
  phoneVerified: boolean
  emailVerified: boolean
  role: string
  isBlocked?: boolean
}

export type AuthTokens = {
  accessToken: string
  refreshToken: string
  expiresIn: number
  user: AuthUser
}

export type AdminStats = {
  users: { total: number; blocked: number }
  reports: { open: number; reviewed: number; dismissed: number }
  occurrences: { published: number; hidden: number; cancelled: number }
  joins: { total: number; accepted: number; pending: number }
}

export type AdminReport = {
  id: string
  status: string
  reason: string
  comment: string | null
  moderatorNote: string | null
  createdAt: string
  updatedAt: string
  reporter: { id: string; name: string | null }
  targetUser: { id: string; name: string | null } | null
  occurrence: { id: string; title: string } | null
  actionsApplied?: string[]
}

export type AdminAuditLog = {
  id: string
  action: string
  targetType: string
  targetId: string
  metadata: unknown
  createdAt: string
  actor: {
    id: string
    name: string | null
    email: string | null
    phone: string | null
  }
}

export type CursorPage<T> = {
  items: T[]
  nextCursor: string | null
}

export type AdminUserListItem = {
  id: string
  phone: string | null
  email: string | null
  name: string | null
  role: string
  isBlocked: boolean
  phoneVerified: boolean
  emailVerified: boolean
  city: { slug: string; name: string } | null
  lastActiveAt: string | null
  createdAt: string
  counts: {
    organizedEvents: number
    reportsReceived: number
    reportsFiled: number
  }
}

export type AdminUserDetail = AdminUserListItem & {
  bio: string | null
  avatarUrl: string | null
  interestFilterIds: string[]
  interestTags: string[]
  updatedAt: string
  counts: AdminUserListItem['counts'] & {
    participations: number
    deviceTokens: number
  }
  city: { id: string; slug: string; name: string } | null
  organizedEvents?: AdminOccurrenceListItem[]
  reportsReceived?: AdminReport[]
  reportsFiled?: AdminReport[]
}

export type AdminOccurrenceListItem = {
  id: string
  title: string
  status: string
  startsAt: string | null
  publishedAt: string
  coverUrl: string | null
  city: { id?: string; slug: string; name: string }
  organizer?: { id: string; name: string | null; email?: string | null }
  participantCount: number
  maxParticipants: number
  isOneOnOne?: boolean
  formatIds?: string[]
  themeIds?: string[]
  counts: {
    points: number
    reports: number
    participations?: number
  }
}

export type AdminOccurrenceDetail = {
  id: string
  title: string
  description: string
  status: string
  joinMode: string
  startsAt: string | null
  hideExactTime: boolean
  publishedAt: string
  createdAt: string
  updatedAt: string
  coverUrls: string[]
  city: { id: string; slug: string; name: string }
  organizer: {
    id: string
    name: string | null
    email: string | null
    phone: string | null
    isBlocked: boolean
  }
  participantCount: number
  maxParticipants: number
  isOneOnOne: boolean
  formatIds: string[]
  themeIds: string[]
  startLatitude: number
  startLongitude: number
  points: Array<{
    id: string
    sortOrder: number
    title: string
    latitude: number
    longitude: number
    address: string | null
    detail: string | null
    description: string | null
    isStart: boolean
    isFinish: boolean
    photoUrls: string[]
  }>
  reports: Array<{
    id: string
    status: string
    reason: string
    comment: string | null
    createdAt: string
    reporter: { id: string; name: string | null }
    targetUser: { id: string; name: string | null } | null
  }>
  counts: {
    points: number
    reports: number
    participations: number
  }
}

export function normalizeRole(role: string): 'user' | 'moderator' | 'admin' {
  return role.toLowerCase() as 'user' | 'moderator' | 'admin'
}

export function isStaffRole(role: string): boolean {
  const r = normalizeRole(role)
  return r === 'admin' || r === 'moderator'
}
