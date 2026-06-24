import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../core/theme/app_glass_tokens.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../shared/models/user_profile_data.dart';
import '../../../ui/navigation/app_menu_sheet.dart';
import '../../event/data/mock_event_repository.dart';
import '../../event/presentation/event_screen.dart';
import '../../event/presentation/widgets/event_glass_back_button.dart';
import '../../event/presentation/widgets/event_glass_icon_button.dart';
import 'widgets/profile_actions_sheet.dart';
import 'widgets/profile_hero_carousel.dart';
import 'widgets/profile_sheet_content.dart';

/// Публичный профиль организатора / участника.
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, required this.profile});

  final UserProfileData profile;

  /// Как hero обложки на [EventScreen].
  static const double _heroVisibleFraction = 0.70;
  static const double _sheetOverlap = 30;
  static const double _sheetMaxSize = 1.0;

  static double _initialSheetSize(double screenHeight) {
    final sheetTop = screenHeight * _heroVisibleFraction - _sheetOverlap;
    final sheetHeight = screenHeight - sheetTop;
    return (sheetHeight / screenHeight).clamp(0.28, 0.52);
  }

  void _openEvent(BuildContext context, String eventId, {bool isPast = false}) {
    if (isPast) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Событие завершено')),
      );
      return;
    }
    final detail = eventRepository.getDetail(eventId);
    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Событие недоступно')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventScreen(data: detail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final initialSheetSize = _initialSheetSize(screenHeight);
    final heroHeight = screenHeight * _heroVisibleFraction;
    final dotsBottomInset = _sheetOverlap + AppSpacing.s12;
    final scrollBottomPad = bottom + AppSpacing.s24;

    return Scaffold(
      backgroundColor: colors.heroBackdrop,
      body: BackdropGroup(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroHeight,
              child: ProfileHeroCarousel(
                height: heroHeight,
                photoAssets: profile.heroPhotoAssets,
                dotsBottomInset: dotsBottomInset,
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
                    child: ProfileSheetContent(
                      profile: profile,
                      scrollController: scrollController,
                      bottomPadding: scrollBottomPad,
                      onUpcomingEventTap: (eventId) =>
                          _openEvent(context, eventId),
                      onPastEventTap: (eventId) => _openEvent(
                        context,
                        eventId,
                        isPast: true,
                      ),
                    ),
                  ),
                );
              },
            ),
            LiquidGlassLayer(
              settings: AppGlassTokens.settingsFor(context),
              useBackdropGroup: true,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: top + AppSpacing.s8,
                    left: AppSpacing.paddingGlobal,
                    child: EventGlassBackButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Positioned(
                    top: top + AppSpacing.s8,
                    right: AppSpacing.paddingGlobal,
                    child: EventGlassIconButton(
                      icon: Icons.more_horiz_rounded,
                      semanticLabel: 'Действия',
                      onPressed: () => showProfileActionsSheet(
                        context: context,
                        profileName: profile.name,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
