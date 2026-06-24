import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../core/theme/app_glass_tokens.dart';
import '../../core/theme/app_spacing.dart';
import 'app_bottom_nav_bar.dart';

/// Нижняя плашка в стиле [AppBottomNavBar] (liquid glass + тень).
///
/// В [Stack] используйте [positioned]; внутри [LiquidGlassLayer] — [bar].
class AppGlassFooterBar extends StatelessWidget {
  const AppGlassFooterBar({
    super.key,
    required this.child,
    this.horizontalInset = AppSpacing.paddingGlobal,
    this.positioned = true,
  });

  final Widget child;
  final double horizontalInset;

  /// `false` — только glass-плашка (родитель задаёт [Positioned]).
  final bool positioned;

  static const double _barRadius = 100;

  static double bottomInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + AppBottomNavBar.barBottomMinimum;

  /// Glass-плашка без [Positioned] — для обёртки в [LiquidGlassLayer].
  Widget bar(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_barRadius),
                boxShadow: AppGlassTokens.lightNavShadows,
              ),
            ),
          ),
        ),
        LiquidGlass(
          shape: const LiquidRoundedSuperellipse(
            borderRadius: _barRadius,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s12,
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = bar(context);
    if (!positioned) return content;

    return Positioned(
      left: horizontalInset,
      right: horizontalInset,
      bottom: bottomInset(context),
      child: content,
    );
  }
}
