# Design tokens

Источник: Figma. Обновляется по мере поступления макетов.

## Типографика (Inter Variable)

| Token | Size | Weight | Line height | Letter spacing |
|-------|------|--------|-------------|----------------|
| `text-body` | 14 | 400 | 18 | -0.4 |
| `text-15-450` | 15 | 450 | 20 | -0.4 |
| `text-13-400` | 13 | 400 | 16 | -0.4 |
| `text-14-550` | 14 | 550 | 18 | -0.4 |
| `text-18-600` | 18 | 600 | 22 | -0.3 |

**Код:** `AppTextStyles` / `context.textBody`, … — `lib/core/theme/app_text_styles.dart`

## Цвета

### Light

| Token | HEX |
|-------|-----|
| background | `#FFFFFF` |
| text | `#000000` |
| second-bg | `#F2F3F4` |
| caption | `#A1A1A1` |
| accent | `#FF423E` |
| blue | `#00A8FE` |
| green | `#00D652` |

### Dark

| Token | HEX |
|-------|-----|
| background | `#111111` |
| text | `#FFFFFF` |
| second-bg | `#232323` |
| caption | `#747373` |
| accent | `#FF0000` |
| blue | `#00A8FE` |
| green | `#00D652` |

**Код:** `context.appColors` — `AppThemeColors` extension.

## Отступы

Шкала: **4 / 8 / 12 / 16 / 24 / 32 / 48 / 64**

| Token | px |
|-------|-----|
| `s4` / `xs` | 4 |
| `s8` / `sm` | 8 |
| `s12` / `md` | 12 |
| `s16` / `lg` | 16 |
| `s24` / `xl` | 24 |
| `s32` / `xxl` | 32 |
| `s48` / `xxxl` | 48 |
| `s64` / `xxxxl` | 64 |

**Код:** `AppSpacing` — `lib/core/theme/app_spacing.dart`

| Token | px |
|-------|-----|
| `padding-global` | 16 |
| `gap6` | 6 (иконка ↔ текст) |

## Радиусы

Шкала: **4 / 8 / 12 / 16**

| Token | px |
|-------|-----|
| `r4` / `br4` | 4 |
| `r8` / `br8` | 8 |
| `r12` / `br12` | 12 |
| `r16` / `br16` | 16 |

**Код:** `AppRadius` — `lib/core/theme/app_radius.dart`

## Компоненты UI-kit

| Компонент | Файл |
|-----------|------|
| `PrimaryButtonBlack` | `lib/ui/buttons/primary_button_black.dart` |
| `PrimaryButtonSmoke` | `lib/ui/buttons/primary_button_smoke.dart` |
| `SecondaryButton` | `lib/ui/buttons/secondary_button.dart` — `filled` / `whiteOutlined` |
| `GlassChipButton` | `lib/ui/chips/glass_chip_button.dart` — glass как nav (cards + people) |
| `AppGlassTokens` | `lib/core/theme/app_glass_tokens.dart` — light fill, shadows, active `#EDEDED` |
| `ChipDropdown` | `lib/ui/dropdown/chip_dropdown.dart` — меню под чипом |
| `ShellFilterBar` | `lib/features/shell/presentation/shell_filter_bar.dart` — чипы hug, gap auto (`Spacer`); «Все» — мультиселект + сброс |
| Dropdown (чип) | `text-18-600` + `text`; галочка — `blue`; поиск локации: `br12`, bg `background`, stroke 12% `text` / 0.3, placeholder `caption` |
| `LocationIcon` | `lib/ui/icons/location_icon.dart` — 18×18 |
| `CategoryTab` | `lib/ui/category_tab.dart` — active: `second-bg` + `text`; default: `background` + `caption`; py 8, px 12, r12 |
| `AppGlobalPadding` | `lib/ui/layout/app_global_padding.dart` |
| `AppBottomNavBar` | `lib/ui/navigation/app_bottom_nav_bar.dart` — [liquid_glass_renderer](https://pub.dev/packages/liquid_glass_renderer) |

### Bottom nav

`[menu] · [people | cards | location] · [add]` — glass Refraction **100**, Depth **16**, Frost **7**, Fill **black 40%**; иконки **white 80%**; active: круг **48px** **white**, icon **black**. Menu/`+` — white 80%. Чипы шапки — Fill **`#F7F7F7` 80%** (`GlassChipButton`).

Превью: `UiKitPreviewScreen` (`flutter run`).

### Вкладка «Люди»

| Элемент | Код / ассеты |
|---------|----------------|
| Экран | `lib/features/people/presentation/people_screen.dart` |
| Моки | `lib/features/people/data/people_mock.dart` |
| Фото моков | [`assets/images/people/`](../assets/images/people/README.md) — `01.jpg` … `05.jpg` |
| Чипы сверху | `ShellFilterBar` + `GlassChipButton` (glass как nav), текст `text` |
| Низ фото | `PeopleProfileOverlay` — имя; организатор: `N событий` + теги; участник: bio 1–2 строки (город только в чипах) |

### Вкладка «Карточки»

| Элемент | Код / ассеты |
|---------|----------------|
| Фон ленты | `#F2F3F4` — `feedBackground` / `CardsScreen` |
| Карточка | `lib/features/cards/presentation/widgets/walk_card.dart` |
| Лента | `CardsScreen`, моки `lib/features/cards/data/cards_feed_mock.dart` |
| Обложки маршрута | `assets/images/cards/01.jpg` … `15.jpg`, листание + точки в `WalkCard` |
| CTA карточки | «Присоединиться!», radius 8, inset 4px, текст `text` (black) |
| Метрика маршрута | `points` → `mappin.svg`; `distance` → `rote.svg` + «N км» |
| Чип организатора | аватар 40×40, fill black 40%, blur 12 |
| Иконки шапки карточки | `assets/icons/common/time.svg`, `mappin.svg` |

## Иконки

Папка для загрузки: [`assets/icons/`](../assets/icons/README.md)

- `nav/` — таб-бар
- `actions/` — лайк, фильтр, репост и т.д.
- `common/` — прочие
