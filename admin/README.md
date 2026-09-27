# Выходи — Admin

React SPA (Vite + TypeScript + shadcn/ui) для модерации Walk&Talk / «Выходи».

Контракт API: [`docs/admin.md`](../docs/admin.md), модель: [`docs/MODERATION.md`](../docs/MODERATION.md).

## Возможности

- OTP login: **email** или **телефон** (роль `ADMIN` / `MODERATOR`)
- Дашборд: `GET /admin/stats` (карточки → фильтры)
- События: список + detail, lifecycle hide/cancel/republish
- Жалобы: очередь, resolve + actions, deep-link `?reportId=` / `?occurrenceId=`
- Пользователи: поиск, block/unblock, смена роли (ADMIN), detail (маршруты, жалобы)
- Инструменты: lifecycle события по UUID
- Журнал действий: `GET /admin/audit-logs`
- Session warning перед expiry access JWT (`VITE_SESSION_WARN_SECONDS`)

## Dev

```bash
# Backend
cd backend
docker compose up -d
cp .env.example .env   # если ещё нет
npm run db:migrate:deploy
npm run start:dev

# Один раз залогиньтесь OTP (код в логе при EMAIL_STUB / SMS stub), затем:
SEED_ADMIN_EMAIL=you@example.com npm run ops:promote-admin
# или SEED_ADMIN_PHONE=+7999...

# Admin SPA
cd ../admin
cp .env.example .env
npm install
npm run dev
```

Откройте http://localhost:5173 — CORS defaults бэка уже включают `:5173`.

`VITE_API_BASE_URL` обязателен в production-сборке; в dev по умолчанию `http://localhost:3000/api`.
Файл `.env` не коммитится (см. `.gitignore`).

Опционально: `VITE_SESSION_WARN_SECONDS` (по умолчанию `120`) — за сколько секунд до expiry access JWT показать предупреждение и кнопку «Продлить сессию». `0` отключает.

## Deploy / security

Статика из `dist/` должна отдаваться с CSP и hardening-заголовками:

- пример nginx: [`deploy/nginx.conf`](./deploy/nginx.conf)
- Cloudflare Pages / Netlify: [`public/_headers`](./public/_headers) (копируется в `dist` при build)

**Обязательно** замените placeholder `https://api.example.com` в CSP `connect-src` на origin вашего API (схема + хост из `VITE_API_BASE_URL`, **без** `/api`). Иначе браузер заблокирует запросы к API.

### Токены

Access/refresh JWT хранятся в `localStorage` (типичный Bearer SPA). Это не `httpOnly` cookies: XSS может украсть токены. Митигации: CSP (`script-src 'self'`), короткий access TTL, revoke refresh при logout/block. Переход на cookie-сессии — отдельный объём (SameSite, CSRF, CORS credentials).

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Vite dev server |
| `npm run build` | Production build |
| `npm run preview` | Preview dist |
| `npm test` | Vitest smoke tests |
