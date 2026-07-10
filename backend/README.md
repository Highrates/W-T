# Walk&Talk API (NestJS)

Минимальный geo-модуль для wizard создания маршрута.

## Эндпоинты

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/api/health` | Health check |
| GET | `/api/geo/suggest?q=...&ll=lng,lat` | Геосаджест (прокси Яндекс) |
| POST | `/api/geo/geocode` | Reverse geocode `{ latitude, longitude }` |

## Запуск

```bash
cd backend
cp .env.example .env
# добавьте ключи Геосаджеста и Геокодера из developer.tech.yandex.ru
npm install
npm run start:dev
```

API: `http://localhost:3000/api`

## Ключи Яндекса

- `YANDEX_GEOSUGGEST_API_KEY` — API Геосаджеста
- `YANDEX_GEOCODER_API_KEY` — API Геокодера

Ключ MapKit остаётся только в mobile (`MAPKIT_API_KEY`).

## Mobile

```bash
cd mobile
flutter run --dart-define-from-file=dart_defines.json
```

В `dart_defines.json`:

```json
{
  "MAPKIT_API_KEY": "...",
  "API_BASE_URL": "http://127.0.0.1:3000/api"
}
```

Android emulator: `http://10.0.2.2:3000/api`
