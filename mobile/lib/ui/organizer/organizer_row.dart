import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_colors.dart';

/// Строка организатора в шторке мероприятия.
class OrganizerRow extends StatelessWidget {
  const OrganizerRow({
    super.key,
    required this.name,
    required this.avatarAsset,
    this.isVerified = false,
    this.onTap,
    this.avatarSize = 40,
  });

  final String name;
  final String avatarAsset;
  final bool isVerified;
  final VoidCallback? onTap;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  avatarAsset,
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.text18_600(color: colors.text),
                ),
              ),
              if (isVerified)
                Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: colors.blue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
