import 'package:flutter/material.dart';

import '../../../features/shell/data/feed_filter_mock.dart';
import '../../../features/shell/data/location_filter_mock.dart';
import '../../../features/shell/presentation/shell_filter_bar.dart';
import '../../../features/shell/presentation/widgets/shell_location_filter_row.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../ui/layout/app_global_padding.dart';
import '../../../ui/navigation/app_bottom_nav_bar.dart';
import '../../event/data/mock_event_repository.dart';
import '../../event/presentation/event_screen.dart';
import '../../profile/presentation/open_user_profile.dart';
import 'widgets/cards_road_background.dart';
import 'widgets/walk_card.dart';
import 'widgets/walk_card_participants_sheet.dart';

/// Лента вкладки «Карточки».
class CardsScreen extends StatefulWidget {
  const CardsScreen({
    super.key,
    required this.hotFilterIds,
    required this.onHotFilterToggle,
    required this.location,
    required this.onLocationChanged,
    required this.onFilterTap,
    required this.onNavCompactChanged,
  });

  final Set<String> hotFilterIds;
  final ValueChanged<String> onHotFilterToggle;
  final LocationFilterOption location;
  final ValueChanged<LocationFilterOption> onLocationChanged;
  final VoidCallback onFilterTap;
  final ValueChanged<bool> onNavCompactChanged;

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _scrollController = ScrollController();
  var _stickyChips = false;
  double _lastScrollOffset = 0;
  var _navCompact = false;

  static const _scrollDirectionThreshold = 6;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;

    final threshold = ShellLocationFilterRow.plainContentHeight + AppSpacing.s8;
    final sticky = offset >= threshold;
    if (sticky != _stickyChips) {
      setState(() => _stickyChips = sticky);
    }

    bool? nextCompact;
    if (offset <= 0) {
      nextCompact = false;
    } else if (delta > _scrollDirectionThreshold) {
      nextCompact = true;
    } else if (delta < -_scrollDirectionThreshold) {
      nextCompact = false;
    }

    if (nextCompact != null && nextCompact != _navCompact) {
      _navCompact = nextCompact;
      widget.onNavCompactChanged(nextCompact);
    }

    _lastScrollOffset = offset;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final safeTop = MediaQuery.paddingOf(context).top;
    final feed = eventRepository.getFeed().where((card) {
      return FeedHotFilterMock.matches(
        selectedIds: widget.hotFilterIds,
        formatIds: card.formatIds,
        themeIds: card.themeIds,
      );
    }).toList();
    final bottomPadding = AppBottomNavBar.barHeight +
        AppBottomNavBar.barBottomMinimum +
        AppSpacing.s24;

    final chipsRow = FeedHotFiltersRow(
      selectedIds: widget.hotFilterIds,
      onToggle: widget.onHotFilterToggle,
    );

    return ColoredBox(
      color: colors.feedBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CardsRoadBackground(),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: safeTop + AppSpacing.s8),
                  child: ShellLocationFilterRow(
                    style: ShellLocationFilterStyle.plain,
                    location: widget.location,
                    onLocationChanged: widget.onLocationChanged,
                    onFilterTap: widget.onFilterTap,
                    filterActive: widget.hotFilterIds.isNotEmpty,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.s8,
                    bottom: AppSpacing.s12,
                  ),
                  child: _stickyChips
                      ? SizedBox(height: shellFilterChipRowHeight())
                      : chipsRow,
                ),
              ),
              SliverList.separated(
                itemCount: feed.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.s12),
                itemBuilder: (context, index) {
                  final card = feed[index];
                  return AppGlobalPadding(
                    child: WalkCard(
                      data: card,
                      onCardTap: () {
                        final detail = eventRepository.getDetail(card.id);
                        if (detail == null) return;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => EventScreen(data: detail),
                          ),
                        );
                      },
                      onOrganizerTap: () =>
                          openUserProfile(context, card.organizerId),
                      onGoingTap: card.participants.isEmpty
                          ? null
                          : () => showWalkCardParticipantsSheet(
                                context: context,
                                goingLabel: card.goingLabel,
                                participants: card.participants,
                              ),
                    ),
                  );
                },
              ),
              SliverPadding(
                padding: EdgeInsets.only(bottom: bottomPadding),
              ),
            ],
          ),
          if (_stickyChips)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.s8,
                    bottom: AppSpacing.s12,
                  ),
                  child: chipsRow,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
