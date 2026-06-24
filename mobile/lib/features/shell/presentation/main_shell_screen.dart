import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../ui/navigation/app_bottom_nav_bar.dart';
import '../../../ui/navigation/app_menu_sheet.dart';
import '../../../ui/navigation/app_nav_tab.dart';
import '../../cards/presentation/cards_screen.dart';
import '../../profile/data/mock_user_profile_repository.dart';
import '../../profile/presentation/open_user_profile.dart';
import '../../map/presentation/map_screen.dart';
import '../../people/presentation/people_screen.dart';
import '../data/location_filter_mock.dart';
import '../../../core/map/map_kit_visibility.dart';
import 'widgets/shell_location_filter_row.dart';

/// Оболочка приложения с нижней навигацией (liquid glass).
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  AppNavTab _tab = AppNavTab.cards;

  Set<String> _feedHotFilterIds = {};

  LocationFilterOption _location = LocationFilterMock.defaultCity;

  var _feedNavCompact = false;

  /// Карта в дереве после первого открытия — не пересоздаём GL-view.
  var _mapLayerInserted = false;

  double get _navScale =>
      _tab == AppNavTab.cards && _feedNavCompact
          ? AppBottomNavBar.feedScrollCompactScale
          : 1;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final currentUser =
        userProfileRepository.getProfile(userProfileRepository.currentUserId);
    final profileAvatar = currentUser?.avatarAsset ??
        'assets/images/people/02.jpg';

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return BackdropGroup(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_tab == AppNavTab.people)
                  const Positioned.fill(child: PeopleScreen()),
                if (_tab == AppNavTab.cards)
                  Positioned.fill(
                    child: CardsScreen(
                      hotFilterIds: _feedHotFilterIds,
                      onHotFilterToggle: _toggleFeedHotFilter,
                      location: _location,
                      onLocationChanged: _onLocationChanged,
                      onFilterTap: _onFilterTap,
                      onNavCompactChanged: _onFeedNavCompactChanged,
                    ),
                  ),
                if (_mapLayerInserted)
                  Positioned.fill(
                    child: Visibility(
                      visible: _tab == AppNavTab.map,
                      maintainState: true,
                      maintainAnimation: true,
                      child: MapScreen(
                        location: _location,
                        onLocationChanged: _onLocationChanged,
                        onFilterTap: _onFilterTap,
                        filterActive: _feedHotFilterIds.isNotEmpty,
                      ),
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
                          location: _location,
                          onLocationChanged: _onLocationChanged,
                          onFilterTap: _onFilterTap,
                          filterActive: _feedHotFilterIds.isNotEmpty,
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

  void _onLocationChanged(LocationFilterOption option) {
    setState(() => _location = option);
  }

  void _onFilterTap() {}

  void _onFeedNavCompactChanged(bool compact) {
    if (_feedNavCompact == compact) return;
    setState(() => _feedNavCompact = compact);
  }

  void _toggleFeedHotFilter(String id) {
    setState(() {
      final next = Set<String>.from(_feedHotFilterIds);
      if (next.contains(id)) {
        next.remove(id);
      } else {
        next.add(id);
      }
      _feedHotFilterIds = next;
    });
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
      if (tab != AppNavTab.cards) {
        _feedNavCompact = false;
      }
    });
  }

  void _onMenuTap() {
    showAppMenuSheet(context: context);
  }

  void _onProfileTap() {
    openCurrentUserProfile(context);
  }
}
