import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';

class EventMapPlaceholder extends StatelessWidget {
  const EventMapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: ColoredBox(
        color: colors.secondBackground,
        child: SizedBox(
          height: 200,
          width: double.infinity,
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
                'Скоро',
                style: AppTextStyles.text14_550(color: colors.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
