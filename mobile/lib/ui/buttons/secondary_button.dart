import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_colors.dart';

/// Стиль компактной кнопки-чипа (иконка 18×18 + текст, pill radius).
enum SecondaryButtonStyle {
  /// Фон `second-bg`.
  filled,

  /// Фон `background` (white в light), обводка 12% black, 0.3px.
  whiteOutlined,
}

/// Компактная кнопка-чип: иконка 18×18 + текст, pill radius.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.style = SecondaryButtonStyle.filled,
    this.expanded = false,
    this.labelColor,
    this.iconColor,
    this.frosted = false,
    this.frostedBlurSigma,
    this.frostedTint,
  });

  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final SecondaryButtonStyle style;

  /// Растянуть на ширину родителя ([Expanded] в Row).
  final bool expanded;

  /// По умолчанию `caption`; для чипов шапки — `text`.
  final Color? labelColor;
  final Color? iconColor;

  /// [BackdropFilter] поверх фона (вкладка «Люди»).
  final bool frosted;

  /// Blur sigma; по умолчанию 12.
  final double? frostedBlurSigma;

  /// Tint поверх blur; по умолчанию 80% исходного фона стиля.
  final Color? frostedTint;

  static const double iconSize = 18;
  static const double defaultFrostedBlurSigma = 12;
  static const double defaultFrostedBackgroundOpacity = 0.8;
  static const double radius = 100;
  static const double outlineStrokeWidth = 0.3;
  static const double outlineStrokeOpacity = 0.12;

  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s16,
    vertical: 10,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onPressed != null && !isLoading;
    final borderRadius = BorderRadius.circular(radius);

    final textColor = labelColor ?? colors.caption;
    final leadingColor = iconColor ?? colors.caption;

    final baseBackground = switch (style) {
      SecondaryButtonStyle.filled => colors.secondBackground,
      SecondaryButtonStyle.whiteOutlined => colors.background,
    };
    final blurSigma = frostedBlurSigma ?? defaultFrostedBlurSigma;
    final backgroundColor = frosted
        ? (frostedTint ??
            baseBackground.withValues(alpha: defaultFrostedBackgroundOpacity))
        : baseBackground;
    final borderSide = style == SecondaryButtonStyle.whiteOutlined && !frosted
        ? BorderSide(
            color: colors.text.withValues(alpha: outlineStrokeOpacity),
            width: outlineStrokeWidth,
          )
        : frosted && style == SecondaryButtonStyle.whiteOutlined
            ? BorderSide(
                color: Colors.white.withValues(alpha: outlineStrokeOpacity),
                width: outlineStrokeWidth,
              )
            : BorderSide.none;

    final content = Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            )
          else if (icon != null) ...[
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
            const SizedBox(width: AppSpacing.gap6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.text14_550(color: textColor),
            ),
          ),
        ],
      ),
    );

    Widget button = Material(
      color: frosted ? Colors.transparent : backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: borderSide,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: borderRadius,
        child: frosted
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: borderRadius,
                  border: borderSide == BorderSide.none
                      ? null
                      : Border.fromBorderSide(borderSide),
                ),
                child: content,
              )
            : content,
      ),
    );

    if (frosted) {
      button = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: button,
        ),
      );
    }

    if (!expanded) return button;

    return SizedBox(width: double.infinity, child: button);
  }
}
