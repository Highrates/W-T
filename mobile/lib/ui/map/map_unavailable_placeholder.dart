import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_colors.dart';

/// Заглушка, когда MapKit не инициализирован (нет ключа или dev без карты).
class MapUnavailablePlaceholder extends StatelessWidget {
  const MapUnavailablePlaceholder({
    super.key,
    this.height,
    this.message = 'Карта недоступна',
    this.hint,
    this.borderRadius = AppRadius.r12,
  });

  final double? height;
  final String message;
  final String? hint;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color: colors.secondBackground,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/common/mappin.svg',
                  width: 28,
                  height: 34,
                  colorFilter: ColorFilter.mode(
                    colors.caption.withValues(alpha: 0.5),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  message,
                  style: AppTextStyles.text14_550(color: colors.text),
                  textAlign: TextAlign.center,
                ),
                if (hint != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    hint!,
                    style: AppTextStyles.text13_400(color: colors.caption),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
