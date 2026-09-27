import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/require_auth.dart';
import '../../event/presentation/open_event.dart';
import '../../participation/application/participation_controller.dart';
import '../../profile/presentation/open_user_profile.dart';
import '../../shell/application/feed_controller.dart';
import '../../shell/application/feed_query_controller.dart';
import '../../shell/presentation/feed_hot_filters_row.dart';
import '../../shell/presentation/widgets/shell_location_filter_row.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../ui/layout/app_global_padding.dart';
import '../../../ui/navigation/app_bottom_nav_bar.dart';
import 'widgets/cards_road_background.dart';
import 'widgets/walk_card.dart';
import 'widgets/walk_card_participants_sheet.dart';

/// Лента вкладки «Карточки».
class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({
    super.key,
    required this.onNavCompactChanged,
  });

  final ValueChanged<bool> onNavCompactChanged;

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  final _scrollController = ScrollController();
  var _stickyChips = false;
  double _lastScrollOffset = 0;
  var _navCompact = false;
  String? _submittingEventId;

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

  Future<void> _submitJoin(String eventId) async {
    if (!await requireAuth(context)) return;
    setState(() => _submittingEventId = eventId);
    try {
      await ref.read(participationControllerProvider.notifier).submitJoin(eventId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
    if (mounted) setState(() => _submittingEventId = null);
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
    final feedAsync = ref.watch(feedControllerProvider);
    final query = ref.watch(feedQueryControllerProvider);
    final queryController = ref.read(feedQueryControllerProvider.notifier);
    final bottomPadding = AppBottomNavBar.barHeight +
        AppBottomNavBar.barBottomMinimum +
        AppSpacing.s24;

    final chipsRow = FeedHotFiltersRow(
      selectedIds: query.hotFilterIds,
      onToggle: queryController.toggleHotFilter,
    );

    return feedAsync.when(
      loading: () => ColoredBox(
        color: colors.feedBackground,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ColoredBox(
        color: colors.feedBackground,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Text(
              'Не удалось загрузить ленту\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (feed) => ColoredBox(
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
                    location: query.location,
                    onLocationChanged: queryController.setLocation,
                    onFilterTap: () {},
                    filterActive: query.hasActiveFilters,
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
                      ? SizedBox(height: feedHotFilterChipRowHeight())
                      : chipsRow,
                ),
              ),
              if (feed.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Нет событий по выбранным фильтрам',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: feed.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.s12),
                  itemBuilder: (context, index) {
                    final card = feed[index];
                    return AppGlobalPadding(
                      child: RepaintBoundary(
                        child: WalkCard(
                          data: card,
                          isJoinSubmitting: _submittingEventId == card.id,
                          onJoinTap: () => _submitJoin(card.id),
                          onCardTap: () => openEvent(context, card.id),
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
    ),
    );
  }
}
