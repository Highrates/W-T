import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/user_profile.dart';

/// Имя и мета внизу фото: градиентное затемнение (город — в чипах шапки).
class PeopleProfileOverlay extends StatelessWidget {
  const PeopleProfileOverlay({
    super.key,
    required this.profile,
    required this.bottomInset,
  });

  final UserProfile profile;
  final double bottomInset;

  static const double _fadeHeight = 200;

  static const Color _metaPrimary = Colors.white;
  static final Color _metaSecondary = Colors.white.withValues(alpha: 0.85);
  static final Color _metaTertiary = Colors.white.withValues(alpha: 0.7);

  @override
  Widget build(BuildContext context) {
    final eventsLine = profile.peopleTabEventsLine;
    final detailLine = profile.peopleTabDetailLine;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: 0.45),
              Colors.black.withValues(alpha: 0.7),
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.paddingGlobal,
            AppSpacing.s48,
            AppSpacing.paddingGlobal,
            bottomInset + AppSpacing.s16,
          ),
          child: SizedBox(
            height: _fadeHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.text18_600(color: _metaPrimary),
                      ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: AppSpacing.s4),
                      Icon(
                        Icons.verified_rounded,
                        size: 20,
                        color: _metaPrimary.withValues(alpha: 0.9),
                      ),
                    ],
                  ],
                ),
                if (eventsLine != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    eventsLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.text14_550(color: _metaSecondary),
                  ),
                ],
                if (detailLine != null && detailLine.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    detailLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.text14_550(color: _metaTertiary),
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
