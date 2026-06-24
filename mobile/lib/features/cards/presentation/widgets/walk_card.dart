import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/walk_card_data.dart';
import 'walk_card_body.dart';
import 'walk_card_header.dart';

/// Карточка события: header + body (макет Cards).
class WalkCard extends StatelessWidget {
  const WalkCard({
    super.key,
    required this.data,
    this.onOrganizerTap,
    this.onGoingTap,
    this.onJoinSubmitted,
    this.onCardTap,
  });

  final WalkCardData data;
  final VoidCallback? onOrganizerTap;
  final VoidCallback? onGoingTap;
  final VoidCallback? onJoinSubmitted;
  final VoidCallback? onCardTap;

  static const double radius = AppRadius.r12;
  static const double borderWidth = 0.5;
  static const double coverHeight = 424;
  static const double avatarSize = 16;
  static const double avatarOverlap = 10;
  static const double cardInset = AppSpacing.s4;

  static BorderSide borderSide(AppThemeColors colors) => BorderSide(
        width: borderWidth,
        color: colors.borderSubtle,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final side = borderSide(colors);

    final card = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WalkCardHeader(
          data: data,
          borderSide: side,
          onGoingTap: onGoingTap,
          radius: radius,
          avatarSize: avatarSize,
          avatarOverlap: avatarOverlap,
        ),
        WalkCardBody(
          data: data,
          borderSide: side,
          onOrganizerTap: onOrganizerTap,
          onJoinSubmitted: onJoinSubmitted,
          radius: radius,
          coverHeight: coverHeight,
          cardInset: cardInset,
        ),
      ],
    );

    if (onCardTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCardTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}
