import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/walk_card_data.dart';
import '../../../../shared/models/walk_card_route_metric.dart';
import '../../../../ui/avatars/avatar_stack.dart';
import '../../../profile/presentation/open_user_profile.dart';
import 'walk_when_display.dart';

class WalkCardHeader extends StatelessWidget {
  const WalkCardHeader({
    super.key,
    required this.data,
    required this.borderSide,
    this.onGoingTap,
    this.radius = AppRadius.r12,
    this.avatarSize = 16,
    this.avatarOverlap = 10,
  });

  final WalkCardData data;
  final BorderSide borderSide;
  final VoidCallback? onGoingTap;
  final double radius;
  final double avatarSize;
  final double avatarOverlap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final metaStyle = AppTextStyles.text14_550(color: colors.text);
    final canOpenGoing = onGoingTap != null && data.participants.isNotEmpty;

    final routeIcon = switch (data.routeMetric) {
      WalkCardRouteMetric.points => (
        asset: 'assets/icons/common/mappin.svg',
        width: 13.0,
        height: 16.0,
      ),
      WalkCardRouteMetric.distance => (
        asset: 'assets/icons/common/rote.svg',
        width: 14.0,
        height: 14.0,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ),
        border: Border(
          top: borderSide,
          left: borderSide,
          right: borderSide,
        ),
      ),
      child: Row(
        children: [
          WalkWhenDisplay(
            isHidden: data.isWhenHidden,
            whenLabel: data.whenLabel,
            iconColor: colors.caption,
            textStyle: metaStyle,
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.participants.isNotEmpty) ...[
                AvatarStack(
                  assets: data.participantAvatarAssets,
                  size: avatarSize,
                  overlap: avatarOverlap,
                  onAvatarTap: (index) => openUserProfile(
                    context,
                    data.participants[index].id,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
              ],
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canOpenGoing ? onGoingTap : null,
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s4,
                      horizontal: AppSpacing.s4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(data.goingLabel, style: metaStyle),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                          ),
                          child: Text(
                            '·',
                            style: metaStyle.copyWith(color: colors.caption),
                          ),
                        ),
                        _WalkCardHeaderMetaItem(
                          iconAsset: routeIcon.asset,
                          iconWidth: routeIcon.width,
                          iconHeight: routeIcon.height,
                          label: data.routeMetricLabel,
                          style: metaStyle,
                          iconColor: colors.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalkCardHeaderMetaItem extends StatelessWidget {
  const _WalkCardHeaderMetaItem({
    required this.iconAsset,
    required this.iconWidth,
    required this.iconHeight,
    required this.label,
    required this.style,
    required this.iconColor,
  });

  final String iconAsset;
  final double iconWidth;
  final double iconHeight;
  final String label;
  final TextStyle style;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconAsset,
          width: iconWidth,
          height: iconHeight,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
        const SizedBox(width: AppSpacing.s4),
        Text(label, style: style),
      ],
    );
  }
}
