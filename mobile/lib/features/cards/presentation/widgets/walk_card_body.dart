import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/walk_card_data.dart';
import '../../../../ui/media/cover_carousel.dart';
import '../../../../ui/organizer/organizer_chip.dart';
import 'walk_card_join_effects.dart';

class WalkCardBody extends StatelessWidget {
  const WalkCardBody({
    super.key,
    required this.data,
    required this.borderSide,
    this.onOrganizerTap,
    this.onJoinSubmitted,
    this.radius = AppRadius.r12,
    this.coverHeight = 424,
    this.cardInset = AppSpacing.s4,
  });

  final WalkCardData data;
  final BorderSide borderSide;
  final VoidCallback? onOrganizerTap;
  final VoidCallback? onJoinSubmitted;
  final double radius;
  final double coverHeight;
  final double cardInset;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(cardInset, 0, cardInset, cardInset),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        ),
        border: Border(
          left: borderSide,
          right: borderSide,
          bottom: borderSide,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.text.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.hasCoverPhotos)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.r8),
              child: SizedBox(
                width: double.infinity,
                height: coverHeight,
                child: CoverCarousel(
                  coverAssets: data.coverAssets,
                  overlayBottomLeft: OrganizerChip(
                    name: data.organizerName,
                    avatarAsset: data.organizerAvatarAsset,
                    isVerified: data.isOrganizerVerified,
                    onTap: onOrganizerTap,
                  ),
                ),
              ),
            )
          else
            _WalkCardTextOnlyContent(
              data: data,
              onOrganizerTap: onOrganizerTap,
            ),
          const SizedBox(height: AppSpacing.s16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: AppTextStyles.text18_600(color: colors.text),
                ),
                const SizedBox(height: 6),
                Text(
                  data.description,
                  style: AppTextStyles.text14_550(color: colors.text),
                  maxLines: data.hasCoverPhotos ? null : 8,
                  overflow: data.hasCoverPhotos
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          WalkCardJoinSection(
            initialStatus: data.joinStatus,
            onJoinSubmitted: onJoinSubmitted,
          ),
        ],
      ),
    );
  }
}

/// Текстовая карточка без обложек: только строка организатора.
class _WalkCardTextOnlyContent extends StatelessWidget {
  const _WalkCardTextOnlyContent({
    required this.data,
    this.onOrganizerTap,
  });

  final WalkCardData data;
  final VoidCallback? onOrganizerTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s8,
        AppSpacing.s8,
        AppSpacing.s8,
        0,
      ),
      child: _WalkCardOrganizerRow(
        name: data.organizerName,
        avatarAsset: data.organizerAvatarAsset,
        isVerified: data.isOrganizerVerified,
        onTap: onOrganizerTap,
      ),
    );
  }
}

class _WalkCardOrganizerRow extends StatelessWidget {
  const _WalkCardOrganizerRow({
    required this.name,
    required this.avatarAsset,
    this.isVerified = false,
    this.onTap,
  });

  final String name;
  final String avatarAsset;
  final bool isVerified;
  final VoidCallback? onTap;

  static const double _avatarSize = 40;

  @override
  Widget build(BuildContext context) {
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
            ClipOval(
              child: Image.asset(
                avatarAsset,
                width: _avatarSize,
                height: _avatarSize,
                fit: BoxFit.cover,
              ),
            ),
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
              Icon(
                Icons.verified_rounded,
                size: 18,
                color: colors.blue,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
