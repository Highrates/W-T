import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/profile_event_preview.dart';
import '../../../cards/presentation/widgets/walk_when_display.dart';

/// Компактная карточка события в профиле организатора.
class ProfileEventPreviewCard extends StatelessWidget {
  const ProfileEventPreviewCard({
    super.key,
    required this.preview,
    required this.onTap,
  });

  final ProfileEventPreview preview;
  final VoidCallback onTap;

  static const double width = 220;
  static const double coverHeight = 150;

  /// Высота ряда в горизонтальном списке.
  static const double listHeight = 236;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final muted = preview.isPast;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          child: Opacity(
            opacity: muted ? 0.72 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  child: Image.asset(
                    preview.coverAsset,
                    width: width,
                    height: coverHeight,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  preview.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.text15_450(color: colors.text),
                ),
                const SizedBox(height: AppSpacing.s4),
                if (preview.isWhenHidden || preview.whenLabel != null)
                  WalkWhenDisplay(
                    isHidden: preview.isWhenHidden,
                    whenLabel: preview.whenLabel,
                    iconColor: colors.caption,
                    textStyle: AppTextStyles.text13_400(color: colors.caption),
                  ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  preview.goingLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.text13_400(color: colors.caption),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
