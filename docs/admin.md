# Admin panel — API contract & bootstrap

Backend for the **Walk&Talk / «Выходи»** admin UI (web SPA). All admin routes live under `/api/admin/*` on the same NestJS host as the mobile API.

Related: [MODERATION.md](./MODERATION.md) (trust & safety model, report actions, audit log).

---

## Base URL

| Environment | API base |
|-------------|----------|
| Local dev | `http://localhost:3000/api` |
| Staging/prod | `https://<api-host>/api` |

Global prefix: **`/api`**. Admin paths: **`/api/admin/...`**.

---

## Authentication

There is **no separate admin login**. Moderators and admins use the same OTP flow as mobile users.

### 1. Obtain tokens (OTP)

```http
POST /api/auth/email/request
Content-Type: application/json

{ "email": "ops@example.com" }
```

```http
POST /api/auth/email/verify
Content-Type: application/json

{ "email": "ops@example.com", "code": "123456" }
```

Response (`200`):

```json
{
  "accessToken": "<jwt>",
  "refreshToken": "<opaque>",
  "expiresIn": 900,
  "user": {
    "id": "uuid",
    "phone": null,
    "email": "ops@example.com",
    "phoneVerified": false,
    "emailVerified": true,
    "role": "ADMIN"
  }
}
```

Phone flow: `POST /api/auth/phone/request` + `/phone/verify` with `{ "phone": "+79991234567", "code": "..." }`.

### 2. Call admin endpoints

```http
Authorization: Bearer <accessToken>
```

Access JWT payload: `{ sub: userId, role: "USER" | "MODERATOR" | "ADMIN" }`.  
On each request the server **re-reads `role` from the database** (role changes apply without re-login until access token expires).

Refresh when access expires:

```http
POST /api/auth/refresh
Content-Type: application/json

{ "refreshToken": "<opaque>" }
```

Logout (revoke refresh token):

```http
POST /api/auth/logout
Authorization: Bearer <accessToken>
Content-Type: application/json

{ "refreshToken": "<opaque>" }
```

### 3. Bootstrap first ADMIN

The user must exist in `users` (log in once via OTP from mobile or curl).

```bash
cd backend
export SEED_ADMIN_EMAIL=ops@example.com
# or SEED_ADMIN_PHONE=+79991234567
npm run ops:promote-admin
```

Then OTP verify again (or `POST /auth/refresh`) to get a JWT with `role: ADMIN`.

Seed can also promote on `npm run db:seed` if `SEED_ADMIN_*` is set in the environment.

### Auth errors

| Status | Meaning |
|--------|---------|
| `401 Unauthorized` | Missing/invalid JWT, expired access, blocked user (`isBlocked=true`), revoked refresh |
| `403 Forbidden` | Valid JWT but `role` not in route allowlist (e.g. `USER` hitting `/admin/*`) |

Blocked users: all refresh tokens are deleted on block; existing access JWTs fail on next request.

---

## CORS (admin SPA)

The API uses an **explicit origin allowlist** (not `*`).

### Development

If `CORS_ORIGINS` is **unset or empty**, defaults apply:

- `http://localhost:3000`
- `http://127.0.0.1:3000`
- `http://localhost:5173` (Vite)
- `http://127.0.0.1:5173`

`credentials: true` — the admin SPA must send cookies/credentials only if you use them; for Bearer tokens, typical fetch:

```javascript
fetch(`${API_BASE}/admin/stats`, {
  headers: { Authorization: `Bearer ${accessToken}` },
});
```

### Staging / production

**Required:** set `CORS_ORIGINS` to comma-separated admin (and other) front-end origins.

```env
NODE_ENV=production
CORS_ORIGINS=https://admin.example.com,https://staging-admin.example.com
```

Startup fails if `NODE_ENV !== development` and `CORS_ORIGINS` is empty (`validateEnv()`).

Also required in production: `JWT_ACCESS_SECRET` (min 32 characters).

---

## Roles

| Role | Admin API |
|------|-----------|
| `USER` | No access (`403`) |
| `MODERATOR` | Reports, users (block), stats, occurrence lifecycle |
| `ADMIN` | Same + **change user roles** (`PATCH /admin/users/:id { role }`) |

---

## Common patterns

### Pagination (cursor)

List endpoints return:

```json
{
  "items": [ /* ... */ ],
  "nextCursor": "uuid-or-null"
}
```

Pass `?cursor=<nextCursor>&limit=20` (default `limit=20`, max `100`).

### Enums in JSON

API responses use **lowercase** strings (`open`, `reviewed`, `admin`, …).  
Request bodies for PATCH/POST accept Prisma enum names (**uppercase** in query/body where `@IsEnum` uses Prisma types, e.g. `status=OPEN` in query) — follow each endpoint example below.

---

## Endpoints

All require `Authorization: Bearer …` and role `MODERATOR` or `ADMIN`.

### Dashboard stats

```http
GET /api/admin/stats
```

Response (`200`):

```json
{
  "users": { "total": 1200, "blocked": 3 },
  "reports": { "open": 5, "reviewed": 40, "dismissed": 12 },
  "occurrences": { "published": 890, "hidden": 2, "cancelled": 15 },
  "joins": { "total": 3400, "accepted": 3100, "pending": 45 }
}
```

---

### Reports queue

```http
GET /api/admin/reports?status=OPEN&limit=20&cursor=
```

Query:

| Param | Type | Description |
|-------|------|-------------|
| `status` | `OPEN` \| `REVIEWED` \| `DISMISSED` | Filter |
| `targetUserId` | UUID | Reports against this user |
| `occurrenceId` | UUID | Reports on this event |
| `cursor` | UUID | Pagination |
| `limit` | 1–100 | Page size |

Response item shape:

```json
{
  "id": "uuid",
  "status": "open",
  "reason": "spam",
  "comment": "optional text",
  "moderatorNote": null,
  "createdAt": "2026-09-10T10:00:00.000Z",
  "updatedAt": "2026-09-10T10:00:00.000Z",
  "reporter": { "id": "uuid", "name": "Anna" },
  "targetUser": { "id": "uuid", "name": "Bob" },
  "occurrence": { "id": "uuid", "title": "Walk by the sea" }
}
```

`targetUser` / `occurrence` may be `null` depending on report type.

#### Resolve report

```http
PATCH /api/admin/reports/:id
Content-Type: application/json

{
  "status": "REVIEWED",
  "moderatorNote": "Spam confirmed",
  "actions": ["block_target_user", "hide_occurrence"]
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `status` | yes | `REVIEWED` or `DISMISSED` (cannot set back to `OPEN`) |
| `moderatorNote` | no | Max 2000 chars |
| `actions` | no | Only when `status` is `REVIEWED` |

Actions (optional, array):

| Action | Effect |
|--------|--------|
| `block_target_user` | Requires `targetUserId` on report; sets `isBlocked`, revokes refresh tokens |
| `hide_occurrence` | Requires `occurrenceId`; sets occurrence `HIDDEN` |

Response: same as list item + `"actionsApplied": ["block_target_user"]`.

Errors: `400` if action incompatible with report targets; `404` if report missing.

Side effects and audit: see [MODERATION.md](./MODERATION.md).

---

### Users

```http
GET /api/admin/users?q=anna&role=USER&isBlocked=false&limit=20
```

Query:

| Param | Type | Description |
|-------|------|-------------|
| `q` | string | Substring match on phone, email, name |
| `role` | `USER` \| `MODERATOR` \| `ADMIN` | Filter |
| `isBlocked` | boolean | `true` / `false` |
| `cursor`, `limit` | | Pagination |

List item:

```json
{
  "id": "uuid",
  "phone": "+79991234567",
  "email": null,
  "name": "Anna",
  "role": "user",
  "isBlocked": false,
  "phoneVerified": true,
  "emailVerified": false,
  "city": { "slug": "sochi", "name": "Сочи" },
  "lastActiveAt": "2026-09-10T09:00:00.000Z",
  "createdAt": "2026-01-01T00:00:00.000Z",
  "counts": {
    "organizedEvents": 2,
    "reportsReceived": 0,
    "reportsFiled": 1
  }
}
```

#### User detail

```http
GET /api/admin/users/:id
```

Extended profile with `bio`, `interestFilterIds`, `interestTags`, `counts.participations`, `counts.deviceTokens`, signed `avatarUrl`.

#### Update user

```http
PATCH /api/admin/users/:id
Content-Type: application/json

{ "isBlocked": true }
```

| Field | Who can set |
|-------|-------------|
| `isBlocked` | MODERATOR, ADMIN |
| `role` | **ADMIN only** (`USER`, `MODERATOR`, `ADMIN`) |

Rules: cannot block self; cannot demote own admin role.  
Blocking revokes all refresh tokens for that user.

---

### Occurrences (events)

```http
GET /api/admin/occurrences?status=PUBLISHED&q=баня&organizerId=&cityId=sochi&limit=20
```

| Param | Type | Description |
|-------|------|-------------|
| `q` | string | Title / description / organizer name |
| `status` | `PUBLISHED` \| `HIDDEN` \| `CANCELLED` \| `COMPLETED` | Filter |
| `organizerId` | UUID | Organizer filter |
| `cityId` | UUID or city slug | City filter |
| `cursor`, `limit` | | Pagination |

```http
GET /api/admin/occurrences/:id
```

Detail includes points, covers, organizer, and recent reports on the event.

### Occurrence lifecycle (moderator)

Same actions as organizer, **without** organizer ownership check.

```http
POST /api/admin/occurrences/:id/lifecycle
Content-Type: application/json

{ "action": "hide" }
```

| `action` | Result |
|----------|--------|
| `cancel` | `CANCELLED`, participations cancelled, push to participants |
| `hide` | `HIDDEN` (hidden from feed) |
| `republish` | `HIDDEN` → `PUBLISHED` |

Response:

```json
{ "id": "uuid", "status": "hidden" }
```

---

### Audit log

```http
GET /api/admin/audit-logs?targetType=user&targetId=&actorId=&action=USER_BLOCKED&limit=50
```

Query: `targetType` (`user` \| `occurrence` \| `report`), `targetId`, `actorId`, `action` (Prisma enum, e.g. `USER_BLOCKED`), cursor pagination.

Response item:

```json
{
  "id": "uuid",
  "action": "user_blocked",
  "targetType": "user",
  "targetId": "uuid",
  "metadata": { "reportId": "uuid", "source": "report" },
  "createdAt": "2026-09-10T10:00:00.000Z",
  "actor": { "id": "uuid", "name": "Mod", "email": null, "phone": "+7999..." }
}
```

---

## Local dev checklist

```bash
cd backend
docker compose up -d
cp .env.example .env
npm install
npm run db:migrate:deploy
npm run start:dev
```

1. OTP login once with your email/phone.  
2. `SEED_ADMIN_EMAIL=you@example.com npm run ops:promote-admin`  
3. OTP verify → copy `accessToken`.  
4. Admin SPA at `http://localhost:5173` with `CORS_ORIGINS` unset (dev defaults) or explicit:

   ```env
   CORS_ORIGINS=http://localhost:5173
   ```

5. `GET http://localhost:3000/api/admin/stats` with Bearer token.

---

## Changelog / versioning

Admin routes shipped in **M3** (backend `0.4.x`). Breaking changes to request/response shapes should be noted here and in `backend/README.md`.
