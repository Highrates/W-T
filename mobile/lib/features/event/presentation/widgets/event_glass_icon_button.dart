import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../../core/theme/app_glass_tokens.dart';

/// Круглая glass-кнопка в hero (назад, меню ⋯).
class EventGlassIconButton extends StatelessWidget {
  const EventGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  static const double size = 44;
  static const double iconSize = 22;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: AppGlassTokens.lightNavShadows,
                  ),
                ),
              ),
            ),
            LiquidGlass(
              shape: LiquidRoundedSuperellipse(borderRadius: size / 2),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onPressed,
                  customBorder: const CircleBorder(),
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: AppGlassTokens.chipText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
