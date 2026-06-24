import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_colors.dart';

/// Glass-чип организатора поверх фото обложки.
class OrganizerChip extends StatelessWidget {
  const OrganizerChip({
    super.key,
    required this.name,
    required this.avatarAsset,
    this.isVerified = false,
    this.onTap,
    this.avatarSize = 38,
    this.blurSigma = 12,
    this.fillOpacity = 0.4,
  });

  final String name;
  final String avatarAsset;
  final bool isVerified;
  final VoidCallback? onTap;
  final double avatarSize;
  final double blurSigma;
  final double fillOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const radius = BorderRadius.all(Radius.circular(100));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Material(
          color: colors.heroBackdrop.withValues(alpha: fillOpacity),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.asset(
                      avatarAsset,
                      width: avatarSize,
                      height: avatarSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    name,
                    style: AppTextStyles.text14_550(color: colors.onImagePrimary),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: AppSpacing.s4),
                    Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: colors.onImagePrimary.withValues(alpha: 0.9),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
