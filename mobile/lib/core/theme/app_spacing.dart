/// Шкала отступов (Figma): 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64.
abstract final class AppSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;

  /// gap между иконкой и текстом (например SecondaryButton).
  static const double gap6 = 6;

  /// padding-global — горизонтальные отступы экрана.
  static const double paddingGlobal = s16;

  /// Алиасы для удобства в коде.
  static const double xs = s4;
  static const double sm = s8;
  static const double md = s12;
  static const double lg = s16;
  static const double xl = s24;
  static const double xxl = s32;
  static const double xxxl = s48;
  static const double xxxxl = s64;
}
