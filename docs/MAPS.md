# Карты и гео — архитектура Walk&Talk

> Решение «по уму»: **координаты и геолокационная логика на бэкенде**, MapKit в приложении **только для отображения**.

## Яндекс API — что подключить в кабинете

| API | Где используется | Ключ |
|-----|------------------|------|
| **MapKit Mobile SDK** | Flutter: таб «Карта», карта маршрута на event | `MAPKIT_API_KEY` в приложении |
| **API Геокодера** | NestJS: адрес ↔ координаты при сохранении точек | `YANDEX_GEOCODER_API_KEY` на сервере |
| **API Геосаджеста** | NestJS: подсказки города/адреса (фильтры, wizard) | `YANDEX_GEOSUGGEST_API_KEY` на сервере |
| **API Поиска по организациям** | NestJS: POI на точках маршрута (кафе, парки) | `YANDEX_PLACES_API_KEY` на сервере |

**Не подключаем на MVP:** JavaScript API (веб), Static/Tiles (оптимизация позже), матрица расстояний / isochrone (M2+).

### Почему не геокодим в приложении

- Один источник истины — PostgreSQL + PostGIS.
- Ключи Геокодера/Геосаджеста не попадают в APK/IPA.
- Одинаковое поведение iOS/Android и будущей админки (React).
- Проще кэшировать и лимитировать запросы на VPS.

---

## Слои

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter                                                     │
│  · MapKit lite — карта, пины, камера, (позже) polyline       │
│  · GeoPoint / EventRoutePoint.location — только чтение API   │
│  · НЕТ: geocode / suggest на клиенте                         │
└───────────────────────────┬─────────────────────────────────┘
                            │ REST
┌───────────────────────────▼─────────────────────────────────┐
│  NestJS                                                      │
│  · Geocoder / Geosuggest / Places (HTTP → Яндекс)            │
│  · PostGIS: ST_DWithin, bbox, маршруты                       │
│  · Возвращает lat/lng + address + optional poi_id            │
└───────────────────────────┬─────────────────────────────────┘
                            │
                      PostgreSQL + PostGIS
```

---

## Модели (mobile)

| Тип | Файл | Поля geo |
|-----|------|----------|
| `GeoPoint` | `shared/models/geo_point.dart` | `latitude`, `longitude` |
| `EventRoutePoint` | `shared/models/event_route_point.dart` | `location`, `address?`, `poiId?` |
| `MapOccurrencePin` | `shared/models/map_occurrence_pin.dart` | `location` |

Координаты приходят **готовыми** из API; моки — `event_route_points_mock.dart`, `mock_map_repository.dart`.

---

## Mobile — код

| Компонент | Путь |
|-----------|------|
| Конфиг ключа | `core/config/yandex_config.dart` |
| Инициализация | `core/map/mapkit_bootstrap.dart` → `main.dart` |
| Обёртка карты | `ui/map/app_yandex_map.dart` |
| Заглушка без ключа | `ui/map/map_unavailable_placeholder.dart` |
| Таб «Карта» | `features/map/presentation/map_screen.dart` |
| Карта на event | `features/event/.../event_route_map.dart` |
| Репозиторий пинов | `MapRepository` → позже `GET /occurrences` |

### Запуск с картой

**Локальный env (рекомендуется):**

```bash
cd mobile
cp dart_defines.example.json dart_defines.json
# вставьте ключ MapKit Mobile SDK из developer.tech.yandex.ru
flutter run --dart-define-from-file=dart_defines.json
```

Ключ задаётся **только** в `dart_defines.json` → `initMapkit()` в Dart. Нативный `YMKMapKit.setApiKey` в `AppDelegate` **не нужен** (с Flutter-плагином вызывает двойную инициализацию и краш).

Файл `dart_defines.json` в `.gitignore` — в репозиторий не попадает.

В Cursor / VS Code: Run → **Walk&Talk (mobile)** (читает тот же `dart_defines.json`).

**Или одноразово через CLI:**

```bash
flutter run --dart-define=MAPKIT_API_KEY=ваш_ключ_mapkit
```

Без ключа приложение работает: показывается заглушка с подсказкой.

**Bundle id / package** (должны совпадать с ограничениями ключа в кабинете Яндекса):

| Платформа | Идентификатор |
|-----------|---------------|
| iOS | `com.walktalk.walkTalk` |
| Android | `com.walktalk.walk_talk` |

На этапе разработки проще **снять ограничения по bundle id** в настройках ключа.

### Карта в клетках / `Could not fetch mapkit2/init`

SDK подключился (метки могут появиться), но **тайлы не загрузились** — MapKit не получил конфиг с `proxy.mob.maps.yandex.net`.

Проверьте по порядку:

1. Ключ создан именно для **MapKit Mobile SDK** (не JavaScript API, не Геокодер).
2. Ключ **активирован** — после создания в кабинете нужно ~15 минут.
3. В `dart_defines.json` — **ваш** ключ из кабинета (не плейсхолдер из example).
4. Ограничения по bundle id: iOS `com.walktalk.walkTalk`, Android `com.walktalk.walk_talk` — или без ограничений.
5. Полный перезапуск: `flutter run --dart-define-from-file=dart_defines.json` (не hot reload).
6. Устройство в интернете (Wi‑Fi/LTE), без VPN, блокирующего `*.yandex.net`.

В debug-логе при старте: `MapKit: API key loaded (xxxx…yyyy)`.

---

## API бэкенда (контракт для NestJS)

### Точки маршрута (ответ)

```json
{
  "title": "Старт — Парк Ривьера",
  "latitude": 43.5731,
  "longitude": 39.7392,
  "address": "Сочи, Парк Ривьера",
  "poi_id": null,
  "sort_order": 0
}
```

### События на карте

```
GET /occurrences/map?bbox=west,south,east,north
GET /occurrences/map?near=lat,lng&radius_km=15
```

```json
{
  "id": "uuid",
  "title": "Драконы и огни",
  "latitude": 43.5731,
  "longitude": 39.7392,
  "starts_at": "2026-06-10T13:15:00+03:00"
}
```

### Геосаджест (прокси)

```
GET /geo/suggest?q=Соч&types=locality
```

### Геокодирование (прокси)

```
GET /geo/geocode?address=Сочи,+Парк+Ривьера
POST /geo/geocode  { "latitude": 43.57, "longitude": 39.74 }
```

### POI (опционально)

```
GET /geo/places?text=кофейня&near=lat,lng
```

---

## PostGIS (схема, кратко)

```sql
-- route_point
location geography(Point, 4326) NOT NULL,
address text,
poi_id text,

-- route_occurrence (для карты)
location geography(Point, 4326),  -- центр / старт
```

Индекс: `GIST (location)`. Поиск: `ST_DWithin(location, ST_MakePoint(lng, lat)::geography, radius_m)`.

---

## Фазы

| Фаза | Карты |
|------|--------|
| **Сейчас** | MapKit lite, моки с координатами, репозитории, заглушка без ключа |
| **M1** | NestJS geo-модуль, suggest/geocode, wizard с точками |
| **M2** | bbox-лента на карте, polyline маршрута, пешая маршрутизация (сервер или MapKit full) |

---

## Changelog

| Дата | Изменение |
|------|-----------|
| 2026-06-10 | Первая версия: split client/server, модели geo, MapKit lite scaffold |
