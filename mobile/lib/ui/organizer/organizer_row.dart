import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_colors.dart';

/// Вариант отображения организатора.
enum OrganizerRowVariant {
  /// Шторка события: аватар 40, имя text-18-600.
  standard,

  /// Текстовая карточка без обложки: аватар 40, имя text-14-550, pill.
  compact,

  /// Glass-чип поверх обложки.
  chip,
}

/// Организатор события — единый виджет для всех контекстов.
class OrganizerRow extends StatelessWidget {
  const OrganizerRow({
    super.key,
    required this.name,
    required this.avatarAsset,
    this.variant = OrganizerRowVariant.standard,
    this.isVerified = false,
    this.onTap,
    this.avatarSize,
  });

  final String name;
  final String avatarAsset;
  final OrganizerRowVariant variant;
  final bool isVerified;
  final VoidCallback? onTap;
  final double? avatarSize;

  double get _avatarSize => avatarSize ?? switch (variant) {
        OrganizerRowVariant.chip => 38,
        _ => 40,
      };

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      OrganizerRowVariant.chip => _ChipOrganizer(context),
      OrganizerRowVariant.compact => _CompactOrganizer(context),
      OrganizerRowVariant.standard => _StandardOrganizer(context),
    };
  }

  Widget _StandardOrganizer(BuildContext context) {
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
              _Avatar(),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.text18_600(color: colors.text),
                ),
              ),
              if (isVerified)
                Icon(Icons.verified_rounded, size: 20, color: colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _CompactOrganizer(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(),
            const SizedBox(width: AppSpacing.s8),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.text14_550(color: colors.text),
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: AppSpacing.s4),
              Icon(Icons.verified_rounded, size: 18, color: colors.blue),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ChipOrganizer(BuildContext context) {
    final colors = context.appColors;
    const radius = BorderRadius.all(Radius.circular(100));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: colors.heroBackdrop.withValues(alpha: 0.4),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Avatar(),
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

  Widget _Avatar() {
    return ClipOval(
      child: Image.asset(
        avatarAsset,
        width: _avatarSize,
        height: _avatarSize,
        fit: BoxFit.cover,
      ),
    );
  }
}
