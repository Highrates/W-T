import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../core/theme/app_glass_tokens.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../shared/models/event_detail_data.dart';
import '../../../shared/models/walk_card_join_status.dart';
import '../../../ui/navigation/app_bottom_nav_bar.dart';
import '../../../ui/navigation/app_glass_footer_bar.dart';
import '../../../ui/navigation/app_menu_sheet.dart';
import '../../cards/presentation/widgets/walk_card_join_effects.dart';
import '../../profile/presentation/open_user_profile.dart';
import 'widgets/event_actions_sheet.dart';
import 'widgets/event_footer_overlay.dart';
import 'widgets/event_glass_back_button.dart';
import 'widgets/event_glass_icon_button.dart';
import 'widgets/event_hero_carousel.dart';
import 'widgets/event_sheet_content.dart';

/// Страница мероприятия (переход с карточки ленты).
class EventScreen extends StatefulWidget {
  const EventScreen({super.key, required this.data});

  final EventDetailData data;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  static const double _pillRadius = 100;
  static const double _heroVisibleFraction = 0.70;
  static const double _sheetOverlap = 30;
  static const double _goingAvatarSize = 100;
  static const double _sheetMaxSize = 1.0;

  bool _showSuccessBanner = false;
  late WalkCardJoinStatus _joinStatus;

  EventDetailData get data => widget.data;

  @override
  void initState() {
    super.initState();
    _joinStatus = widget.data.event.joinStatus;
  }

  bool get _routeChatEnabled => _joinStatus == WalkCardJoinStatus.approved;

  static double _footerOverlayHeight(double safeBottom) =>
      AppBottomNavBar.barHeight +
      AppBottomNavBar.barBottomMinimum +
      safeBottom +
      AppSpacing.s16;

  static double _listBottomPadding(double safeBottom) =>
      _footerOverlayHeight(safeBottom) + AppSpacing.s16;

  static double _initialSheetSize(double screenHeight) {
    final sheetTop = screenHeight * _heroVisibleFraction - _sheetOverlap;
    final sheetHeight = screenHeight - sheetTop;
    return (sheetHeight / screenHeight).clamp(0.28, 0.52);
  }

  @override
  Widget build(BuildContext context) {
    final event = data.event;
    final colors = context.appColors;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final initialSheetSize = _initialSheetSize(screenHeight);
    final scrollBottomPad = _listBottomPadding(bottom);
    final heroHeight = screenHeight * _heroVisibleFraction;
    final dotsBottomInset = _sheetOverlap + AppSpacing.s12;

    return Scaffold(
      backgroundColor: colors.heroBackdrop,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: event.coverAssets.isNotEmpty
                ? EventHeroCarousel(
                    height: heroHeight,
                    coverAssets: event.coverAssets,
                    dotsBottomInset: dotsBottomInset,
                  )
                : ColoredBox(
                    color: colors.secondBackground,
                  ),
          ),
          DraggableScrollableSheet(
            initialChildSize: initialSheetSize,
            minChildSize: initialSheetSize,
            maxChildSize: _sheetMaxSize,
            snap: true,
            snapSizes: [initialSheetSize, _sheetMaxSize],
            builder: (context, scrollController) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kAppMenuSheetTopRadius),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(kAppMenuSheetTopRadius),
                    ),
                  ),
                  child: EventSheetContent(
                    data: data,
                    scrollController: scrollController,
                    bottomPadding: scrollBottomPad,
                    goingAvatarSize: _goingAvatarSize,
                    onOrganizerTap: () =>
                        openUserProfile(context, event.organizerId),
                  ),
                ),
              );
            },
          ),
          if (_showSuccessBanner)
            Positioned(
              top: top + AppSpacing.s8,
              left: 0,
              right: 0,
              child: Center(
                child: WalkJoinSuccessBanner(
                  colors: colors,
                  borderRadius: _pillRadius,
                  hugContent: true,
                  textColor: colors.background,
                ),
              ),
            ),
          // LiquidGlassLayer только на кнопках/футере — полноэкранный слой
          // размывает platform view карты в шторке.
          BackdropGroup(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: top + AppSpacing.s8,
                  left: AppSpacing.paddingGlobal,
                  child: LiquidGlassLayer(
                    settings: AppGlassTokens.settingsFor(context),
                    useBackdropGroup: true,
                    child: EventGlassBackButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Positioned(
                  top: top + AppSpacing.s8,
                  right: AppSpacing.paddingGlobal,
                  child: LiquidGlassLayer(
                    settings: AppGlassTokens.settingsFor(context),
                    useBackdropGroup: true,
                    child: EventGlassIconButton(
                      icon: Icons.more_horiz_rounded,
                      semanticLabel: 'Действия',
                      onPressed: () => showEventActionsSheet(
                        context: context,
                        eventTitle: event.title,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.paddingGlobal,
                  right: AppSpacing.paddingGlobal,
                  bottom: AppGlassFooterBar.bottomInset(context),
                  child: LiquidGlassLayer(
                    settings: AppGlassTokens.settingsFor(context),
                    useBackdropGroup: true,
                    child: EventFooterOverlay(
                      event: event,
                      joinStatus: _joinStatus,
                      routeChatEnabled: _routeChatEnabled,
                      onSuccessBannerChanged: (visible) {
                        setState(() => _showSuccessBanner = visible);
                      },
                      onJoinStatusChanged: (status) {
                        setState(() => _joinStatus = status);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
