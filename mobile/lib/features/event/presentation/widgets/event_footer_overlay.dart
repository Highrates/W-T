import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/walk_card_data.dart';
import '../../../../shared/models/walk_card_join_status.dart';
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
    required this.routeChatEnabled,
    required this.onSuccessBannerChanged,
    required this.onJoinStatusChanged,
  });

  final WalkCardData event;
  final WalkCardJoinStatus joinStatus;
  final bool routeChatEnabled;
  final ValueChanged<bool> onSuccessBannerChanged;
  final ValueChanged<WalkCardJoinStatus> onJoinStatusChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final whenColor = colors.background;

    return AppGlassFooterBar(
      positioned: false,
      child: WalkCardJoinSection(
        initialStatus: joinStatus,
        layout: WalkJoinSectionLayout.eventFooter,
        showBalloons: false,
        onSuccessBannerChanged: onSuccessBannerChanged,
        onJoinStatusChanged: onJoinStatusChanged,
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
