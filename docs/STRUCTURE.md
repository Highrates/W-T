# Walk&Talk — архитектура проекта

> Живой документ. Обновляем по мере принятия решений.

## Позиционирование (не менять без обсуждения)

**Продукт:** социальные прогулки и тематические события — найти компанию для похода, йоги, прогулки, бани и т.п.

**Не позиционировать как:** dating-приложение, «Tinder для прогулок», знакомства/свидания.

**Для сторов и маркетинга:** Social / Lifestyle — «совместные прогулки», «тематические события», «компания для активности».

---

## Стек

| Слой | Технология | Примечание |
|------|------------|------------|
| Мобильное приложение | **Flutter** (iOS + Android) | Mac + iPhone для разработки и TestFlight |
| UI | Собственный **UI-kit** по макету | Не shadcn; design tokens + переиспользуемые виджеты |
| Карты | **Яндекс MapKit** | Точки маршрута, карта события |
| Бэкенд API | **NestJS** (TypeScript), монолит на MVP | REST + WebSocket |
| БД | **PostgreSQL** + **PostGIS** | Геопоиск, маршруты |
| Кэш / pub-sub | **Redis** | Сессии, лента, чат |
| Файлы | **REG.RU S3** (S3-compatible) | Фото маршрутов, аватары |
| Сервер | **REG.RU VPS** (Docker) | API, БД, Redis |
| Платежи | **TBD** (не ЮKassa) | Монетизация позже; провайдер выберем отдельно |
| Push | **FCM** + **APNs** | Через бэкенд |
| Чат | **Свой** (WebSocket + Postgres + Redis) | Без внешнего SaaS |
| Админка (web) | **React** + shadcn/ui | Модерация, пользователи, статистика |
| SMS / email | Провайдер через бэкенд | Верификация телефона и почты |

---

## Высокоуровневая схема

```
┌─────────────────────────────────────────────────────────┐
│  Flutter App (iOS / Android)                             │
│  · UI-kit · Яндекс MapKit · WebSocket (чат)             │
└───────────────────────────┬─────────────────────────────┘
                            │ HTTPS / WSS
┌───────────────────────────▼─────────────────────────────┐
│  REG.RU VPS — NestJS API                                 │
│  · Auth · Routes · Participation · Chat · Payments       │
└─────┬─────────────┬─────────────┬────────────────────────┘
      ▼             ▼             ▼
  PostgreSQL    REG.RU S3      Redis
  + PostGIS     (медиа)
      │
      ├── Яндекс: Геокодер, Геосаджест, Places (HTTP, только бэкенд)
      └── Payments (TBD), SMS, email, FCM/APNs
```

**Карты и гео:** см. [`docs/MAPS.md`](MAPS.md) — MapKit на клиенте (отображение), PostGIS + HTTP API Яндекса на сервере.

---

## Доменные сущности (кратко)

| Сущность | Описание |
|----------|----------|
| `User` | Профиль, аватар, город; верификация email + телефон |
| `RouteTemplate` | Шаблон маршрута: описание, фото, точки, тип, настройки участия |
| `RouteOccurrence` | Конкретное событие (дата/время); ссылка на template или standalone |
| `RoutePoint` | Точка на карте (`geography` PostGIS); `address`, опционально `poi_id` (Яндекс Places) |
| `Participation` | Заявка/участие: `pending` \| `accepted` \| `rejected` \| `cancelled` |
| `Route.join_mode` | `auto` (до лимита) \| `approval` (подтверждение организатором) |
| `ChatRoom` | Чат маршрута (участники + организатор) |
| `Message` | Сообщения в комнате |
| `Payment` | TBD; подписка / поднятие — позже, монетизация пока бесплатна |

---

## Продуктовые решения

| Тема | Решение |
|------|---------|
| Аудитория | Романтика и неромантические активности (горы, йога, баня, прогулки) |
| Участие | Оба режима: авто до лимита и с подтверждением организатором |
| Маршруты | Разовые события + шаблоны с повторением |
| Чат | Да, свой, для участников маршрута |
| Верификация | Email + телефон (на старте) |
| Модерация | TBD (премодерация / постмодерация — отдельное обсуждение) |
| Монетизация | Бесплатно; платежи заложены в архитектуру |

---

## MVP — фазы

| Фаза | Фокус |
|------|--------|
| **M1** | Auth, профиль, создание маршрута, Яндекс-точки, S3, лента, фильтры |
| **M2** | Участие (auto + approval), push, карта маршрута, шаблоны/повторы |
| **M3** | Чат, админка (минимум), TestFlight / internal testing |
| **D (backend)** | Chat REST+WS, `GET /admin/audit-logs` — **в коде**; админ SPA — `admin/` (Vite + shadcn); платежи — TBD |

---

## Репозиторий

```
Walk&Talk/
├── docs/
│   ├── STRUCTURE.md          # этот файл
│   └── MAPS.md               # карты и гео
├── mobile/                   # Flutter (iOS + Android)
│   ├── lib/
│   │   ├── app/              # MaterialApp, тема, точка входа UI
│   │   ├── core/
│   │   │   ├── config/       # Yandex MapKit (dart-defines)
│   │   │   ├── map/          # MapKit bootstrap, lifecycle, visibility
│   │   │   └── theme/        # design tokens (цвета, spacing, glass, типографика)
│   │   ├── ui/               # UI-kit (переиспользуемые виджеты)
│   │   │   ├── avatars/
│   │   │   ├── buttons/
│   │   │   ├── chips/
│   │   │   ├── dropdown/
│   │   │   ├── icons/
│   │   │   ├── layout/
│   │   │   ├── map/
│   │   │   ├── media/
│   │   │   ├── navigation/
│   │   │   └── organizer/
│   │   ├── features/         # фичи (data + presentation)
│   │   │   ├── shell/        # MainShellScreen, фильтры, локация
│   │   │   ├── cards/        # лента карточек (feed)
│   │   │   ├── event/        # страница события, маршрут на карте
│   │   │   ├── map/          # таб «Карта»
│   │   │   ├── people/       # таб «Люди»
│   │   │   ├── profile/      # профиль пользователя
│   │   │   ├── create_route/ # wizard «Создать маршрут»
│   │   │   ├── geo/          # Geosuggest + reverse geocode client
│   │   │   └── dev/          # UiKitPreviewScreen
│   │   ├── shared/
│   │   │   └── models/       # DTO для mock/API (GeoPoint, WalkCardData, …)
│   │   └── main.dart
│   ├── assets/
│   │   ├── app_icon.png
│   │   ├── fonts/            # Inter Variable
│   │   ├── icons/            # nav/, actions/, common/ (SVG)
│   │   └── images/           # cards/, people/ (mock-фото)
│   ├── docs/
│   │   └── DESIGN_TOKENS.md  # детали токенов из Figma
│   └── README.md
├── backend/                  # NestJS — geo API (M1)
│   └── src/geo/              # suggest, reverse geocode
└── admin/                    # Vite + React + shadcn — модерация (M3)
```

**Точка входа приложения:** `MainShellScreen` — нижняя glass-навигация и три основных таба. Отображаемое имя: **«Выходи»** (`MaterialApp.title`).

---

## Flutter — зависимости (ключевые)

| Пакет | Назначение |
|-------|------------|
| `flutter_riverpod` | DI, shared state (фильтры, join, feed) |
| `go_router` | Навигация: `/`, `/event/:id`, `/event/:id/template`, `/profile/:id`, `/create-route` |
| `flutter_svg` | SVG-иконки из `assets/icons/` |
| `liquid_glass_renderer` | Glass-эффект: nav bar, чипы, footer event |
| `http` | REST-клиент → NestJS geo API |
| `shared_preferences` | Локальный черновик wizard «Создать маршрут» |
| `yandex_maps_mapkit_lite` | Яндекс MapKit на табе «Карта» и в event |

Ключи: `dart_defines.json` → `MAPKIT_API_KEY`, `API_BASE_URL` (`core/config/`).

---

## Flutter — фичи (текущее состояние)

| Фича | Экран / модуль | Статус |
|------|----------------|--------|
| `shell` | `MainShellScreen`, `ShellLocationFilterRow`, `FeedHotFiltersRow` | Реализовано (mock-данные) |
| `cards` | `CardsScreen`, `WalkCard` | Реализовано (mock-лента) |
| `event` | `EventScreen`, карта маршрута, точки, join-flow | Реализовано (mock) |
| `map` | `MapScreen`, пины событий | Реализовано (mock + MapKit) |
| `people` | `PeopleScreen`, overlay профиля | Реализовано (mock) |
| `profile` | `UserProfileScreen`, sheets | Реализовано (mock-репозиторий) |
| `create_route` | `CreateRouteScreen`, `RouteTemplateScreen`, `CreateRoutePointsMap` | **MVP UI** (publish + draft + geo) |
| `geo` | `GeoRepository`, `GeoApiClient` → NestJS `/geo/*` | Реализовано (fallback mock) |
| `dev` | `UiKitPreviewScreen` | Превью UI-kit |

**Mock-слой:** репозитории и data-классы в `features/*/data/*_mock.dart`; API пока не подключён.

**Shared-модели:** `GeoPoint`, `EventRoutePoint`, `EventCardData`, `EventDetailData`, `UserProfile`, `MapOccurrencePin`, … — в `shared/models/`.

**Навигация:** `app/app_router.dart`, `openEvent()`, `openUserProfile()`, `openCreateRoute()` (меню → «Создать маршрут»).

### Wizard «Создать маршрут» (organizer flow)

Точка входа: **бургер-меню** → «Создать маршрут» → `/create-route`.

Состояние: `CreateRouteDraft` + `CreateRouteController` (Riverpod). **Черновик** — `shared_preferences` (`CreateRouteDraftStorage`), автосохранение на каждом шаге; при входе — диалог «Продолжить / Новый».

| Шаг | Содержание | Валидация |
|-----|------------|-----------|
| 1. Источник | Новый / из моих прошлых / шаблон | Выбор элемента при копии |
| 2. Формат и тема | Пешком или авто; темы — multi-select | Формат обязателен |
| 3. О маршруте | Название, описание | Название ≥3, описание ≥10 |
| 4. Когда | Дата/время, «скрыть точное время» | Дата обязательна |
| 5. Точки | Поиск + MapKit tap/drag пина + polyline между точками | Старт + финиш |
| 6. Фото | Mock-обложки, можно пропустить | — |
| 7. Участие | 1×1 (лимит 2) или группа; join auto/approval | Лимит ≥2 (если не 1×1) |
| 8. Проверка | Превью + «Опубликовать» | — |

**Правила продукта (реализованы в MVP):**

| Правило | Реализация |
|---------|------------|
| 1×1 = лимит 2 | `isOneOnOne` → `maxParticipants: 2` |
| Шаблон копирует маршрут/описание, дата новая | `selectTemplate`: points + description + format/themes; без title/cover/date |
| Город карточки = город старта | `CreateRouteGeo.resolveCityId` по координатам старта |
| Join по умолчанию | 1×1 → `approval`, группа → `auto` (можно изменить) |
| После publish | `/event/:id?published=1` + sheet «Шаблон / Посмотреть» |
| Повторы | `/event/:id/template` — отдельно от wizard |

**Publish:** `EventRepository.publishFromDraft()` → mock добавляет в ленту; `feedControllerProvider` invalidate.

**Следующие итерации:** polyline в реальном времени при drag, пешая маршрутизация, S3 upload, server draft.

---

## Flutter — UI-kit (компоненты)

Детали токенов: [`mobile/docs/DESIGN_TOKENS.md`](../mobile/docs/DESIGN_TOKENS.md). Экспорт: `ui/ui_kit.dart`.

### Реализовано

| Компонент | Файл / папка | Назначение |
|-----------|--------------|------------|
| `AppTheme`, tokens | `core/theme/` | Цвета light/dark, spacing 4–64, radius, glass, Inter |
| `AppBottomNavBar` | `ui/navigation/` | Glass-nav: **menu** · **people \| cards \| map** · **аватар профиля** |
| `AppNavTab` | `ui/navigation/` | Вкладки pill: `feed`, `people`, `map` |
| `AppMenuSheet` | `ui/navigation/` | Bottom sheet: **создать маршрут**, профиль, мои события, … |
| `AppGlassFooterBar` | `ui/navigation/` | Glass-footer на странице события |
| `ShellLocationFilterRow` | `features/shell/` | Локация + фильтр (plain / glass chips) |
| `ChipDropdown` | `ui/dropdown/` | Выбор города в chip |
| `FeedHotFiltersRow` | `features/shell/` | Горизонтальные glass-чипы фильтров ленты |
| `GlassChipButton` | `ui/chips/` | Glass chip (фильтры, локация) |
| `CategoryTab` | `ui/category_tab.dart` | Пешком / Авто / Меню / Люди |
| `WalkCard` | `features/cards/` | Карточка события в ленте |
| `WalkCardHeader` / `WalkCardBody` | `features/cards/` | Шапка и тело карточки |
| `WalkCardJoinEffects` | `features/cards/` | CTA «+ Хочу с вами», статусы участия |
| `PrimaryButtonBlack` / `PrimaryButtonSmoke` | `ui/buttons/` | Основные CTA |
| `SecondaryButton` | `ui/buttons/` | Контур / outlined вариант |
| `AvatarStack` / `TappableAvatar` | `ui/avatars/` | Стек и одиночный аватар |
| `OrganizerRow` (variants) | `ui/organizer/` | Организатор: standard / compact / chip |
| `HeroDetailScaffold` | `ui/layout/` | Hero + draggable sheet (event, profile) |
| `CoverCarousel` | `ui/media/` | Карусель обложек |
| `AppYandexMap` / `AppMapPin` | `ui/map/` | MapKit-виджет и пин |
| `LocationIcon` | `ui/icons/` | Иконка локации |
| `AppGlobalPadding` | `ui/layout/` | Горизонтальный padding-global |

### Запланировано (ещё не в коде)

| Компонент | Назначение |
|-----------|------------|
| `AppScaffold` | Общий каркас экрана + safe area |
| `AppTextField` | Поля форм (auth, wizard) — пока `TextField` Material |
| `EmptyState` / `LoadingState` | Пустая лента, загрузка |
| `AppNetworkImage` | Фото с плейсхолдером (сейчас — asset/mock) |

---

## Flutter — экраны (MVP)

| Экран | Приоритет | Статус |
|-------|-----------|--------|
| Splash / onboarding | P0 | Не начато |
| Auth (email, phone OTP) | P0 | Не начато |
| **Feed (лента)** — таб `feed` | P0 | **Реализовано** (mock) |
| Создание маршрута (wizard) | P0 | **MVP UI** (`CreateRouteScreen`, mock publish) |
| Деталь маршрута / события | P0 | **Реализовано** (`EventScreen`, mock) |
| Карта (таб) | P1 | **Реализовано** (MapKit + mock-пины) |
| Люди (таб) | P1 | **Реализовано** (mock) |
| Профиль | P1 | **Реализовано** (mock) |
| Мои маршруты / участия | P1 | Пункт меню; экран не реализован |
| Чат маршрута | P1 | **API + экран** (`/event/:id/chat`); organizer + accepted |
| Фильтры (sheet) | P1 | Чипы ленты есть; полный sheet — заглушка |
| Настройки, верификация | P2 | Пункты меню; экраны не реализованы |
| UI-kit preview | dev | `UiKitPreviewScreen` |
| Token preview (legacy) | dev | `HomeScreen` (не в навигации) |

---

## Локальная разработка

| Задача | Команда / инструмент |
|--------|----------------------|
| iOS симулятор | Xcode + `flutter run` |
| iPhone | USB, Developer Mode |
| Hot reload | сохранение в IDE |
| Staging API | REG.RU VPS (позже) |
| Бета | TestFlight, Google Play Internal |

---

## Changelog документа

| Дата | Изменение |
|------|-----------|
| 2026-05-19 | Первая версия: стек, сущности, UI-kit, экраны, позиционирование |
| 2026-05-19 | Шаг 0: Flutter-проект в `mobile/`, Inter, design tokens, HomeScreen |
| 2026-05-19 | Токены Figma: типографика (5 стилей), light/dark цвета, Inter Variable |
| 2026-05-19 | Spacing 4–64, radius 4–16, `assets/icons/` (nav, actions, common) |
| 2026-05-19 | UI-kit: кнопки, CategoryTab, padding-global, UiKitPreviewScreen |
| 2026-05-20 | BottomNavBar glass: menu · people/cards/map · add; MainShellScreen |
| 2026-06-10 | Гео: `docs/MAPS.md`, MapKit lite в mobile, `GeoPoint`, geo на бэкенде (Геокодер/Геосаджест/Places) |
| 2026-07-09 | Актуализация: структура `lib/` (shell, cards, event, map, people, profile), glass-nav, UI-kit, статусы экранов |
| 2026-07-10 | P2: go_router, Riverpod, EventCardData, AppNavTab.feed, HeroDetailScaffold, MapDeferredHost, брендинг «Выходи» |
| 2026-07-10 | Wizard точек: drag пинов (MapKit), polyline, tap → уточнение → «Добавить» |
