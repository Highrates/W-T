# Walk&Talk — mobile

Flutter-приложение (iOS + Android).

## Требования

- Flutter 3.x ([установка](https://docs.flutter.dev/get-started/install))
- Xcode (iOS) / Android Studio (Android)
- macOS для сборки под iPhone

## Запуск

```bash
cd mobile
flutter pub get
flutter run
```

На подключённом iPhone:

```bash
flutter devices
flutter run -d <device-id>
```

## Структура `lib/`

```
lib/
├── app/           # MaterialApp, роутинг
├── core/theme/    # Design tokens, Inter, AppTheme
├── ui/            # UI-kit (компоненты)
├── features/      # Экраны по фичам
└── main.dart
```

## Шрифт

**Inter** — `assets/fonts/` (Regular, Medium, SemiBold, Bold).

Документация проекта: [../docs/STRUCTURE.md](../docs/STRUCTURE.md)
