# Walk&Talk API (NestJS)

Backend для приложения **Выходи**: auth, профили, маршруты, лента, geo.

## Стек

- NestJS 11 + TypeScript
- PostgreSQL 16 + PostGIS (Docker)
- Redis 7 (OTP)
- MinIO (S3-compatible, локально)
- Prisma ORM

## Быстрый старт

```bash
cd backend
docker compose up -d
cp .env.example .env   # SMTP_PASS, JWT secrets
npm install
npm run db:migrate:deploy
npm run db:seed
npm run start:dev
```

API: `http://localhost:3000/api`

```bash
npm test   # OTP lockout, join race, feed filters, media ownership, refresh, rate limit
```

MinIO console: `http://localhost:9001` (walktalk / walktalksecret)

## Эндпоинты

### Health
| GET | `/api/health` |

### Auth (Фаза A)
| POST | `/api/auth/phone/request`, `/phone/verify` |
| POST | `/api/auth/email/request`, `/email/verify` |
| POST | `/api/auth/phone/link/request`, `/phone/link/verify` | Bearer — привязать телефон к текущему User |
| POST | `/api/auth/email/link/request`, `/email/link/verify` | Bearer — привязать email к текущему User |
| POST | `/api/auth/refresh`, `/logout` |
| GET | `/api/auth/me` |

Verify с Bearer (optional): OTP подтверждает контакт и **привязывает** к текущей сессии вместо создания отдельного аккаунта. Конфликт (`409`) — контакт уже у другого User. Merge аккаунтов — не реализован (M3+).

### Users (Фаза A)
| GET/PATCH | `/api/users/me` | PATCH: `name`, `bio`, `cityId`, `interestFilterIds`, `avatarUrl` |
| GET | `/api/users/:id` |

`avatarUrl`: presign с `purpose: avatar` → PUT в S3 → PATCH с `readUrl`/key из `avatar/{userId}/`. `null` — удалить аватар.

### Meta
| GET | `/api/meta/cities?active_only=true` |
| GET | `/api/meta/filters` |

### Routes / Feed (Фаза B)
| POST | `/api/occurrences` | Bearer + verified phone/email |
| PATCH | `/api/occurrences/:id` | организатор: title, description, startsAt, coverUrls, maxParticipants |
| POST | `/api/occurrences/:id/lifecycle` | `{ "action": "cancel" \| "hide" \| "republish" }` |
| GET | `/api/occurrences/:id` | деталь + точки |
| GET | `/api/feed?city_id=sochi&filters=walk,nature&near=43.57,39.74&radius_km=15` |
| GET | `/api/occurrences/map?bbox=west,south,east,north` |
| GET | `/api/occurrences/map?near=lat,lng&radius_km=15` |

Фильтры ленты/карты — в SQL (`format_ids &&`, `theme_ids &&`, `is_one_on_one`), cursor стабилен.

**Edit после publish:** маршрут (points), format/theme, joinMode — **не меняются**. Cancel → push участникам (FCM v1 или stub).

### Drafts (Фаза B)
| GET/PUT/DELETE | `/api/drafts/me` | синхронизация wizard |

### Media (Фаза B)
| POST | `/api/media/presign` | `{ contentType, purpose: cover|avatar|point }` |

Publish/PATCH проверяет ключи `purpose/{userId}/…`. Опционально `MEDIA_HEAD_OBJECT_VERIFY=true` — доп. `HeadObject` в S3.

### Participation (Фаза C)
| POST | `/api/occurrences/:id/join` | Bearer + verified |
| POST | `/api/occurrences/:id/leave` | Bearer |
| GET | `/api/occurrences/:id/participations` | организатор |
| PATCH | `/api/participations/:id` | `{ status: accepted\|rejected }` |

`joinStatus` в ленте/детали: `can_join` \| `pending` \| `approved` \| `full`

### People (Фаза C)
| GET | `/api/people?city_id=sochi&near=43.57,39.74&radius_km=15&interests=walk,nature` |

Ранжирование в SQL: `interest_overlap×10 + upcoming×5 + recency`. Денормализация — materialized view `user_people_stats` (refresh после publish/spawn + cron каждые 15 мин, `PEOPLE_STATS_CRON*`).

### Users — расширение (Фаза C)
| GET | `/api/users/me/organized?upcoming=true` |
| GET | `/api/users/me/participations?upcoming=true` |
| GET | `/api/users/:id` | + upcomingEvents, isOrganizer |

### Templates (Фаза C)
| POST | `/api/templates` | `{ occurrenceId }` — сохранить шаблон |
| GET | `/api/templates/me` | мои шаблоны |
| POST | `/api/templates/:id/occurrences` | новое событие из шаблона |

### Reports (Фаза C)
| POST | `/api/reports` | `{ targetUserId?, occurrenceId?, reason, comment? }` |
| GET | `/api/admin/reports` | ADMIN/MODERATOR — очередь модерации |
| PATCH | `/api/admin/reports/:id` | `{ status: reviewed\|dismissed, moderatorNote?, actions? }` |

При `status: reviewed` опционально `actions`: `block_target_user`, `hide_occurrence` (см. [docs/MODERATION.md](../docs/MODERATION.md)).

Причины: `SPAM`, `INAPPROPRIATE`, `HARASSMENT`, `FAKE`, `OTHER`

### Admin — moderation (M3+)
| GET | `/api/admin/stats` | users, reports, occurrences, joins |
| GET | `/api/admin/audit-logs` | история модерации (фильтры + cursor) |
| POST | `/api/admin/occurrences/:id/lifecycle` | `{ action: cancel\|hide\|republish }` — без проверки организатора |
| GET/PATCH | `/api/admin/reports` | очередь + resolve с actions |

Block user: `isBlocked` + **удаление всех refresh tokens**. Все действия пишутся в `audit_logs`.

### Chat (Фаза D)
| GET | `/api/occurrences/:id/chat/messages?cursor=&limit=` | история (organizer + accepted) |
| POST | `/api/occurrences/:id/chat/messages` | `{ body }` — отправка + push участникам |
| WS | `ws://host/chat?token=<access_jwt>` | `{ type: join, occurrenceId }` → `{ type: message, body }` |

Realtime: Redis pub/sub `chat:room:{roomId}`. Одна комната на occurrence.

Платежи — **не реализованы** (провайдер TBD, не ЮKassa).

### Admin — users (M3)
| GET | `/api/admin/users?q=&role=&isBlocked=&cursor=&limit=` | search/list |
| GET | `/api/admin/users/:id` | detail + counts |
| PATCH | `/api/admin/users/:id` | `{ isBlocked?, role? }` — **role** только ADMIN |

Доступ: Bearer JWT с `role` **ADMIN** или **MODERATOR** (`RolesGuard`).

Полный контракт для admin SPA: [docs/admin.md](../docs/admin.md) (bootstrap, CORS, payloads).

## Admin login (OTP → JWT с role)

Отдельного «admin login» нет: **тот же OTP-flow**, что у пользователей.

1. `POST /api/auth/email/request` + `verify` (или phone) — создаёт/находит User, выдаёт `{ accessToken, refreshToken, user: { role, … } }`.
2. JWT access payload: `{ sub: userId, role }`. На каждом запросе `JwtStrategy` перечитывает **role из БД** (смена роли применяется без перевыпуска access, если не истёк TTL).
3. Заблокированный user (`isBlocked=true`) получает `401` на любой JWT-запрос.

### Promote ADMIN (ops)

Пользователь должен **хотя бы раз** войти через OTP (запись в `users`).

```bash
# .env или one-off:
export SEED_ADMIN_EMAIL=ops@example.com
# export SEED_ADMIN_PHONE=+79991234567

npm run ops:promote-admin
# или при db:seed, если SEED_ADMIN_* заданы в окружении
```

После promote: снова OTP verify (или `POST /auth/refresh`) → Bearer с правами ADMIN → `GET /api/admin/users`.

### Drafts — лимиты (M3)
`PUT /drafts/me`: payload до **512 KB**, в JSON автоматически добавляется `schemaVersion: 1`.

### Devices / Push (Фаза C)
| POST | `/api/devices` | `{ token, platform: ios\|android }` |
| DELETE | `/api/devices` | `{ token }` |

Push: `PUSH_STUB=true` — лог в консоль. Production: `FCM_PROJECT_ID` + `FCM_SERVICE_ACCOUNT_JSON` (HTTP v1).

### Geo
| GET | `/api/geo/suggest?q=...` |
| POST | `/api/geo/geocode` | `{ latitude, longitude }` |

## Publish маршрута

```bash
curl -X POST http://localhost:3000/api/occurrences \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Прогулка по набережной",
    "description": "Неспешная прогулка с остановками на кофе",
    "formatIds": ["walk"],
    "themeIds": ["nature", "food"],
    "scheduledAt": "2026-06-15T10:00:00+03:00",
    "joinMode": "auto",
    "maxParticipants": 6,
    "points": [
      { "title": "Старт", "latitude": 43.5855, "longitude": 39.7231, "isStart": true, "sortOrder": 0 },
      { "title": "Финиш", "latitude": 43.5731, "longitude": 39.7392, "isFinish": true, "sortOrder": 1 }
    ]
  }'
```

## Presign upload

```bash
curl -X POST http://localhost:3000/api/media/presign \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"contentType":"image/jpeg","purpose":"cover"}'
# → PUT file to uploadUrl; pass readUrl (or key) in coverUrls / photoUrls on publish
```

Ключ объекта: `{purpose}/{userId}/{uuid}.jpg` — при publish проверяется ownership.

## Join flow

```bash
# Присоединиться (auto → сразу accepted, approval → pending)
curl -X POST http://localhost:3000/api/occurrences/$ID/join \
  -H "Authorization: Bearer $TOKEN"

# Организатор принимает заявку
curl -X PATCH http://localhost:3000/api/participations/$PID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status":"accepted"}'
```

## Mobile

`API_BASE_URL`: `http://127.0.0.1:3000/api` (simulator) / `http://10.0.2.2:3000/api` (Android emulator)

## Security (staging / production)

Перед выкладкой за пределы dev:

| Переменная | Назначение |
|------------|------------|
| `NODE_ENV` | `production` или `staging` — включает строгие проверки при старте |
| `JWT_ACCESS_SECRET` | **Обязателен** (≥ 32 символов), иначе процесс не поднимется |
| `CORS_ORIGINS` | **Обязателен** — allowlist через запятую, напр. `https://admin.example.com` |

OTP:

- **issue** — rate limit (`OTP_RATE_LIMIT_*`)
- **verify** — счётчик неудачных попыток + progressive lockout (`OTP_VERIFY_*`): 60s → 120s → 240s … до 1h

В `development` CORS по умолчанию: localhost:3000 и :5173; JWT без `.env` — dev-fallback.

**MinIO:** локально `S3_PUBLIC_READ=true` + `MINIO_PUBLIC_READ=true` (anonymous download). Staging/prod: `S3_PUBLIC_READ=false`, bucket private — клиент получает signed GET (1h) в API-ответах.

**Rate limit (IP, Redis sliding window):** `/auth/*`, `/geo/*`, `/reports` — см. `RATE_LIMIT_*` в `.env.example`.
