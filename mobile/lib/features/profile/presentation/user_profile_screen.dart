import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../app/app_router.dart';
import '../../../core/providers/repository_providers.dart';

import '../../../core/theme/app_glass_tokens.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../ui/layout/hero_detail_scaffold.dart';
import '../../../ui/media/cover_carousel.dart';
import '../application/user_profile_provider.dart';
import '../../event/presentation/open_event.dart';
import '../../event/presentation/widgets/event_glass_back_button.dart';
import '../../event/presentation/widgets/event_glass_icon_button.dart';
import 'widgets/profile_actions_sheet.dart';
import 'widgets/profile_sheet_content.dart';

/// Профиль пользователя (свой или чужой — по [userId]).
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  void _openEvent(
    BuildContext context,
    String eventId, {
    bool isPast = false,
  }) {
    if (isPast) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Событие завершено')),
      );
      return;
    }
    openEvent(context, eventId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(userProfileRepositoryProvider).currentUserId;
    if (userId == currentUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.me);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = ref.watch(userProfileProvider(userId));
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Профиль не найден')),
      );
    }

    return HeroDetailScaffold(
      heroBuilder: (context, heroHeight, dotsBottomInset) {
        return CoverCarousel(
          height: heroHeight,
          coverAssets: profile.heroPhotoAssets,
          dotsBottomInset: dotsBottomInset,
          dotsVariant: CoverPageDotsVariant.pill,
        );
      },
      sheetBuilder: (context, scrollController, bottomPadding) {
        return ProfileSheetContent(
          profile: profile,
          scrollController: scrollController,
          bottomPadding: bottomPadding,
          onUpcomingEventTap: (eventId) => _openEvent(context, eventId),
          onPastEventTap: (eventId) =>
              _openEvent(context, eventId, isPast: true),
        );
      },
      chromeBuilder: (context, topInset) {
        return BackdropGroup(
          child: LiquidGlassLayer(
            settings: AppGlassTokens.settingsFor(context),
            useBackdropGroup: true,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: topInset + AppSpacing.s8,
                  left: AppSpacing.paddingGlobal,
                  child: EventGlassBackButton(
                    onPressed: () => context.pop(),
                  ),
                ),
                Positioned(
                  top: topInset + AppSpacing.s8,
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
        );
      },
    );
  }
}
