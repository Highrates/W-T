import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/event_card_data.dart';
import '../../../../ui/media/cover_carousel.dart';
import '../../../../ui/organizer/organizer_row.dart';
import 'walk_card_join_effects.dart';

class WalkCardBody extends StatelessWidget {
  const WalkCardBody({
    super.key,
    required this.data,
    required this.borderSide,
    this.onOrganizerTap,
    this.onJoinTap,
    this.isJoinSubmitting = false,
    this.radius = AppRadius.r12,
    this.coverHeight = 424,
    this.cardInset = AppSpacing.s4,
  });

  final EventCardData data;
  final BorderSide borderSide;
  final VoidCallback? onOrganizerTap;
  final VoidCallback? onJoinTap;
  final bool isJoinSubmitting;
  final double radius;
  final double coverHeight;
  final double cardInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(cardInset, 0, cardInset, cardInset),
      decoration: BoxDecoration(
        color: context.appColors.background,
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
            color: context.appColors.text.withValues(alpha: 0.06),
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
                  overlayBottomLeft: OrganizerRow(
                    variant: OrganizerRowVariant.chip,
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
                  style: context.text18_600,
                ),
                const SizedBox(height: 6),
                Text(
                  data.description,
                  style: context.text14_550,
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
            status: data.joinStatus,
            isSubmitting: isJoinSubmitting,
            onJoinTap: onJoinTap,
            showBalloons: false,
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

  final EventCardData data;
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
      child: OrganizerRow(
        variant: OrganizerRowVariant.compact,
        name: data.organizerName,
        avatarAsset: data.organizerAvatarAsset,
        isVerified: data.isOrganizerVerified,
        onTap: onOrganizerTap,
      ),
    );
  }
}
