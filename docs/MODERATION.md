# Moderation model (Walk&Talk / «Выходи»)

## Current: post-publication (reactive)

UGC goes live immediately. Trust and safety are enforced **after** publication via reports and admin tools.

```
User publishes occurrence ──► PUBLISHED (visible in feed)
        │
        ▼
Another user files report ──► OPEN queue
        │
        ▼
Moderator PATCH /admin/reports/:id
        ├─ status: dismissed  (no action)
        └─ status: reviewed + optional actions:
              • block_target_user  → isBlocked + revoke refresh tokens
              • hide_occurrence    → HIDDEN (removed from feed)
```

Organizers retain their own lifecycle (`cancel` / `hide` / `republish`) on **their** events. Moderators use the same actions on **any** event via `POST /admin/occurrences/:id/lifecycle`.

### Block user

- Sets `users.is_blocked = true`
- **Bulk-deletes** all `refresh_tokens` for that user (existing access JWTs expire by TTL; refresh stops working immediately)
- JWT strategy rejects blocked users on the next request
- Logged in `audit_logs` (`USER_BLOCKED`)

### Hide occurrence

- Status `HIDDEN` — not returned by feed/map queries
- Reversible via admin or organizer `republish`
- Logged as `OCCURRENCE_HIDDEN` / `OCCURRENCE_UNHIDDEN`

### Cancel occurrence (admin)

- Same as organizer cancel: status `CANCELLED`, participations cancelled, push to participants (“отменено модератором”)
- Logged as `OCCURRENCE_CANCELLED`

### Audit trail

Every moderator/admin action writes to `audit_logs`:

| Action | When |
|--------|------|
| `USER_BLOCKED` / `USER_UNBLOCKED` | Admin user PATCH or report action |
| `USER_ROLE_CHANGED` | Admin role change |
| `OCCURRENCE_*` | Admin lifecycle |
| `REPORT_STATUS_CHANGED` | Report reviewed/dismissed |

Fields: `actor_id`, `action`, `target_type`, `target_id`, optional `metadata` (e.g. `{ reportId, from, to }`).

## Future: pre-publication (TBD)

Not implemented. Possible directions:

- **First-time organizer review** — first N occurrences from a new account stay `DRAFT`/`PENDING` until approved
- **Risk-based hold** — auto-hide until review if signals (spam patterns, report history)
- **Geo/category allowlists** — pilot cities only

Pre-moderation would require new occurrence statuses, admin approve/reject endpoints, and feed rules. The current schema and APIs assume **post-moderation only**.

## Admin API summary

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/admin/stats` | Dashboard counters |
| GET/PATCH | `/api/admin/reports` | Report queue + resolve |
| PATCH | `/api/admin/reports/:id` | `{ status, moderatorNote?, actions?: [block_target_user, hide_occurrence] }` |
| POST | `/api/admin/occurrences/:id/lifecycle` | `{ action: cancel \| hide \| republish }` |
| GET/PATCH | `/api/admin/users` | Search, block, role |

Roles: `MODERATOR` and `ADMIN` (role changes: `ADMIN` only).
