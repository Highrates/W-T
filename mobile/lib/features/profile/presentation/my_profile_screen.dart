import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../core/theme/app_glass_tokens.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../ui/layout/hero_detail_scaffold.dart';
import '../../../ui/media/cover_carousel.dart';
import '../../event/presentation/widgets/event_glass_back_button.dart';
import '../../event/presentation/widgets/event_glass_icon_button.dart';
import '../application/my_page_provider.dart';
import 'widgets/my_profile_sheet_content.dart';
import 'widgets/profile_avatar_edit_button.dart';

/// «Моя страница» — кабинет текущего пользователя (не публичный профиль).
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(myPageDataProvider);

    return pageAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Не удалось загрузить профиль: $error')),
      ),
      data: (page) {
        final profile = page.profile;

        return HeroDetailScaffold(
          heroBuilder: (context, heroHeight, dotsBottomInset) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CoverCarousel(
                  height: heroHeight,
                  coverAssets: profile.heroPhotoAssets,
                  dotsBottomInset: dotsBottomInset,
                  dotsVariant: CoverPageDotsVariant.pill,
                ),
                Positioned(
                  right: AppSpacing.paddingGlobal,
                  bottom: dotsBottomInset + AppSpacing.s12,
                  child: const ProfileAvatarEditButton(),
                ),
              ],
            );
          },
          sheetBuilder: (context, scrollController, bottomPadding) {
            return MyProfileSheetContent(
              profile: profile,
              hostingUpcoming: page.hostingUpcoming,
              hostingPast: page.hostingPast,
              goingUpcoming: page.goingUpcoming,
              goingPast: page.goingPast,
              routeDraft: page.routeDraft,
              templates: page.templates,
              scrollController: scrollController,
              bottomPadding: bottomPadding,
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
                        icon: Icons.settings_outlined,
                        semanticLabel: 'Настройки',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Настройки — скоро')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
