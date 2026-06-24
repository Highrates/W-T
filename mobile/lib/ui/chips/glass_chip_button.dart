import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../core/theme/app_glass_tokens.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_colors.dart';

/// Чип в стиле bottom nav: liquid glass + [AppGlassTokens.navBarGlass].
///
/// Родитель должен обернуть в [LiquidGlassLayer] с `useBackdropGroup: true`.
class GlassChipButton extends StatelessWidget {
  const GlassChipButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.labelColor,
    this.iconColor,
    this.selected = false,
    this.iconOnly = false,
    this.contentPadding,
    this.simulatedGlass = false,
  });

  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final Color? labelColor;
  final Color? iconColor;
  final bool selected;

  /// Только иконка без подписи (например, кнопка фильтра).
  final bool iconOnly;

  /// По умолчанию — компактный ряд фильтров ленты.
  final EdgeInsets? contentPadding;

  /// Без [LiquidGlass]: заливка как bottom nav (карта / platform view).
  final bool simulatedGlass;

  static const double radius = 100;

  static const EdgeInsets compactPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s12,
    vertical: AppSpacing.s4,
  );

  /// Локация и фильтр в шапке (чуть выше).
  static const EdgeInsets headerPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s12,
    vertical: AppSpacing.s8,
  );

  static const double iconSize = 18;
  static const double _textLineHeight = 20;

  static double rowHeightFor(EdgeInsets contentPadding) =>
      contentPadding.vertical * 2 + _textLineHeight;

  /// Высота ряда горячих фильтров.
  static double get height => rowHeightFor(compactPadding);

  /// Высота чипов локации / фильтра.
  static double get headerHeight => rowHeightFor(headerPadding);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textColor = labelColor ??
        (selected ? colors.text : AppGlassTokens.chipText);
    final leadingColor = iconColor ?? textColor;

    final shellColor = selected
        ? AppGlassTokens.navActiveIndicator
        : (simulatedGlass ? AppGlassTokens.navBarFill : Colors.transparent);

    final content = Material(
      color: shellColor,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(radius),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Padding(
          padding: contentPadding ?? compactPadding,
          child: SizedBox(
            height: _textLineHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: IconTheme(
                      data: IconThemeData(
                        color: leadingColor,
                        size: iconSize,
                      ),
                      child: icon!,
                    ),
                  ),
                  if (!iconOnly) const SizedBox(width: AppSpacing.gap6),
                ],
                if (!iconOnly)
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.text14_550(color: textColor),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (simulatedGlass) {
      return IntrinsicWidth(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: AppGlassTokens.lightNavShadows,
          ),
          child: content,
        ),
      );
    }

    return IntrinsicWidth(
      child: IntrinsicHeight(
        child: LiquidGlass(
          shape: const LiquidRoundedSuperellipse(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      ),
    );
  }
}
