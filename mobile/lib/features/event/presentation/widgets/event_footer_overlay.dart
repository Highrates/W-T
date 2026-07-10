import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/event_card_data.dart';
import '../../../../shared/models/event_join_status.dart';
import '../../../../ui/navigation/app_glass_footer_bar.dart';
import '../../../cards/presentation/widgets/walk_card_join_effects.dart';
import '../../../cards/presentation/widgets/walk_when_display.dart';
import 'event_footer_chat_icon.dart';

/// Glass-футер страницы мероприятия.
class EventFooterOverlay extends StatelessWidget {
  const EventFooterOverlay({
    super.key,
    required this.event,
    required this.joinStatus,
    required this.isJoinSubmitting,
    required this.routeChatEnabled,
    required this.onJoinTap,
    required this.onSuccessBannerChanged,
  });

  final EventCardData event;
  final EventJoinStatus joinStatus;
  final bool isJoinSubmitting;
  final bool routeChatEnabled;
  final VoidCallback onJoinTap;
  final ValueChanged<bool> onSuccessBannerChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final whenColor = colors.background;

    return AppGlassFooterBar(
      positioned: false,
      child: WalkCardJoinSection(
        status: joinStatus,
        isSubmitting: isJoinSubmitting,
        onJoinTap: onJoinTap,
        layout: WalkJoinSectionLayout.eventFooter,
        showBalloons: false,
        onSuccessBannerChanged: onSuccessBannerChanged,
        eventFooterChat: EventFooterChatIcon(
          enabled: routeChatEnabled,
          onTap: routeChatEnabled
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Чат маршрута — скоро')),
                  );
                }
              : null,
        ),
        whenSlot: WalkWhenDisplay(
          isHidden: event.isWhenHidden,
          whenLabel: event.whenLabel,
          iconColor: whenColor,
          textStyle: AppTextStyles.text14_550(color: whenColor),
        ),
      ),
    );
  }
}
