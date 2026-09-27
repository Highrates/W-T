import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../profile/application/user_profile_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../ui/navigation/app_bottom_nav_bar.dart';
import '../../../ui/navigation/app_menu_sheet.dart';
import '../../../ui/navigation/app_nav_tab.dart';
import '../../cards/presentation/cards_screen.dart';
import '../../map/presentation/map_screen.dart';
import '../../people/presentation/people_screen.dart';
import '../../profile/presentation/open_my_profile.dart';
import '../application/feed_query_controller.dart';
import '../../../core/map/map_kit_visibility.dart';
import 'widgets/shell_location_filter_row.dart';

/// Оболочка приложения с нижней навигацией (liquid glass).
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  AppNavTab _tab = AppNavTab.feed;

  var _feedNavCompact = false;

  /// Карта в дереве после первого открытия — не пересоздаём GL-view.
  var _mapLayerInserted = false;

  double get _navScale =>
      _tab == AppNavTab.feed && _feedNavCompact
          ? AppBottomNavBar.feedScrollCompactScale
          : 1;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final auth = ref.watch(authSessionProvider);
    final currentUserId = ApiConfig.useApi
        ? auth.userId
        : ref.read(userProfileRepositoryProvider).currentUserId;
    final profileAsync = currentUserId != null
        ? ref.watch(userProfileProvider(currentUserId))
        : null;
    final profileAvatar = profileAsync?.valueOrNull?.avatarAsset ??
        'assets/images/people/02.jpg';
    final query = ref.watch(feedQueryControllerProvider);
    final queryController = ref.read(feedQueryControllerProvider.notifier);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return BackdropGroup(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_tab == AppNavTab.people)
                  const Positioned.fill(child: PeopleScreen()),
                if (_tab == AppNavTab.feed)
                  Positioned.fill(
                    child: CardsScreen(
                      onNavCompactChanged: _onFeedNavCompactChanged,
                    ),
                  ),
                if (_mapLayerInserted)
                  Positioned.fill(
                    child: Visibility(
                      visible: _tab == AppNavTab.map,
                      maintainState: true,
                      maintainAnimation: true,
                      child: const MapScreen(),
                    ),
                  ),
                ...AppBottomNavBar.buildNavShadowLayer(
                  context: context,
                  screenWidth: constraints.maxWidth,
                  safeAreaBottom: safeBottom,
                  scale: _navScale,
                ),
                AppBottomNavBar.buildGlassNavOverlay(
                  context: context,
                  screenWidth: constraints.maxWidth,
                  safeAreaBottom: safeBottom,
                  currentTab: _tab,
                  onTabChanged: _onTabChanged,
                  onMenuTap: _onMenuTap,
                  onProfileTap: _onProfileTap,
                  profileAvatarAsset: profileAvatar,
                  scale: _navScale,
                ),
                if (_tab == AppNavTab.people)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s8),
                        child: ShellLocationFilterRow(
                          style: ShellLocationFilterStyle.chips,
                          location: query.location,
                          onLocationChanged: queryController.setLocation,
                          onFilterTap: () {},
                          filterActive: query.hasActiveFilters,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onFeedNavCompactChanged(bool compact) {
    if (_feedNavCompact == compact) return;
    setState(() => _feedNavCompact = compact);
  }

  void _onTabChanged(AppNavTab tab) {
    final wasMap = _tab == AppNavTab.map;
    final isMap = tab == AppNavTab.map;

    if (isMap) {
      _mapLayerInserted = true;
      if (!wasMap) {
        MapKitVisibility.setMapTabActive(true);
      }
    } else if (wasMap) {
      MapKitVisibility.setMapTabActive(false);
    }

    setState(() {
      _tab = tab;
      if (tab != AppNavTab.feed) {
        _feedNavCompact = false;
      }
    });
  }

  void _onMenuTap() {
    showAppMenuSheet(context: context);
  }

  Future<void> _onProfileTap() async {
    await openMyProfile(context);
  }
}
