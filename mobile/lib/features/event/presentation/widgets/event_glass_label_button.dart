import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../../core/theme/app_glass_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'event_glass_icon_button.dart';

/// Pill glass-кнопка с текстом (например «Далее»).
class EventGlassLabelButton extends StatelessWidget {
  const EventGlassLabelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? semanticLabel;

  static const double height = EventGlassIconButton.size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: AppGlassTokens.lightNavShadows,
                  ),
                ),
              ),
            ),
            LiquidGlass(
              shape: LiquidRoundedSuperellipse(borderRadius: height / 2),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: isLoading ? null : onPressed,
                  borderRadius: BorderRadius.circular(height / 2),
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                    ),
                    child: SizedBox(
                      height: height,
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppGlassTokens.chipText,
                                ),
                              )
                            : Text(
                                label,
                                style: AppTextStyles.text14_550(
                                  color: AppGlassTokens.chipText,
                                ),
                              ),
                      ),
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
