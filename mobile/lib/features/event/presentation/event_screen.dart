import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../core/theme/app_glass_tokens.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../shared/models/event_join_status.dart';
import '../../../ui/layout/hero_detail_scaffold.dart';
import '../../../ui/media/cover_carousel.dart';
import '../../../ui/navigation/app_bottom_nav_bar.dart';
import '../../../ui/navigation/app_glass_footer_bar.dart';
import '../../cards/presentation/widgets/walk_card_join_effects.dart';
import '../../create_route/presentation/widgets/published_route_sheet.dart';
import '../application/event_detail_provider.dart';
import '../../participation/application/participation_controller.dart';
import '../../profile/presentation/open_user_profile.dart';
import 'open_event.dart';
import 'widgets/event_actions_sheet.dart';
import 'widgets/event_footer_overlay.dart';
import 'widgets/event_glass_back_button.dart';
import 'widgets/event_glass_icon_button.dart';
import 'widgets/event_sheet_content.dart';

/// Страница мероприятия.
class EventScreen extends ConsumerStatefulWidget {
  const EventScreen({
    super.key,
    required this.eventId,
    this.justPublished = false,
  });

  final String eventId;
  final bool justPublished;

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen> {
  static const double _pillRadius = 100;
  static const double _goingAvatarSize = 100;

  bool _showSuccessBanner = false;
  var _isJoinSubmitting = false;
  var _publishedSheetShown = false;

  @override
  void initState() {
    super.initState();
    if (widget.justPublished) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPublishedSheet());
    }
  }

  Future<void> _maybeShowPublishedSheet() async {
    if (_publishedSheetShown || !mounted) return;
    _publishedSheetShown = true;
    await showPublishedRouteSheet(
      context: context,
      eventId: widget.eventId,
    );
  }

  bool get _routeChatEnabled {
    final joinStatuses = ref.watch(participationControllerProvider);
    final detail = ref.watch(eventDetailProvider(widget.eventId));
    if (detail == null) return false;
    final status = joinStatuses[widget.eventId] ?? detail.event.joinStatus;
    return status == EventJoinStatus.approved;
  }

  EventJoinStatus get _joinStatus {
    final joinStatuses = ref.watch(participationControllerProvider);
    final detail = ref.watch(eventDetailProvider(widget.eventId));
    if (detail == null) return EventJoinStatus.canJoin;
    return joinStatuses[widget.eventId] ?? detail.event.joinStatus;
  }

  static double _listBottomPadding(double safeBottom) {
    final footer = AppBottomNavBar.barHeight +
        AppBottomNavBar.barBottomMinimum +
        safeBottom +
        AppSpacing.s16;
    return footer + AppSpacing.s16;
  }

  Future<void> _submitJoin() async {
    setState(() => _isJoinSubmitting = true);
    await ref
        .read(participationControllerProvider.notifier)
        .submitJoin(widget.eventId);
    if (mounted) setState(() => _isJoinSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(eventDetailProvider(widget.eventId));
    if (data == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Событие не найдено')),
      );
    }

    final event = data.event;
    final joinStatus = _joinStatus;
    final colors = context.appColors;
    final top = MediaQuery.paddingOf(context).top;

    return HeroDetailScaffold(
      sheetBottomPadding: _listBottomPadding,
      heroBuilder: (context, heroHeight, dotsBottomInset) {
        if (event.coverAssets.isEmpty) {
          return ColoredBox(color: colors.secondBackground);
        }
        return CoverCarousel(
          height: heroHeight,
          coverAssets: event.coverAssets,
          dotsBottomInset: dotsBottomInset,
          dotsVariant: CoverPageDotsVariant.pill,
        );
      },
      sheetBuilder: (context, scrollController, bottomPadding) {
        return EventSheetContent(
          data: data,
          scrollController: scrollController,
          bottomPadding: bottomPadding,
          goingAvatarSize: _goingAvatarSize,
          onOrganizerTap: () => openUserProfile(context, event.organizerId),
        );
      },
      topOverlay: _showSuccessBanner
          ? Positioned(
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
            )
          : null,
      chromeBuilder: (context, top) {
        return BackdropGroup(
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
                    onPressed: () => closeEventScreen(context),
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
                    joinStatus: joinStatus,
                    isJoinSubmitting: _isJoinSubmitting,
                    routeChatEnabled: _routeChatEnabled,
                    onJoinTap: _submitJoin,
                    onSuccessBannerChanged: (visible) {
                      setState(() => _showSuccessBanner = visible);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
