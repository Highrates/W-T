import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../shared/models/user_profile.dart';
import '../../../ui/navigation/app_bottom_nav_bar.dart';
import '../../profile/presentation/open_user_profile.dart';
import '../data/people_mock.dart';
import 'widgets/people_profile_overlay.dart';

/// Вкладка «Люди»: вертикальный свайп по фото + мета внизу.
class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen>
    with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom +
        AppBottomNavBar.barHeight +
        AppBottomNavBar.barBottomMinimum;

    final profiles = [
      for (final id in PeopleMock.profileIds)
        ref.read(userProfileRepositoryProvider).getProfile(id),
    ].whereType<UserProfile>().toList();

    if (profiles.isEmpty) {
      return Center(
        child: Text(
          'Никого не найдено',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return GestureDetector(
              onTap: () => openUserProfile(context, profile.id),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ProfilePhoto(profile: profile),
                  PeopleProfileOverlay(
                    profile: profile,
                    bottomInset: bottomInset,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      profile.heroPhotoAssets.first,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        final tint = profile.id.hashCode.abs();
        return ColoredBox(
          color: Color.fromARGB(
            255,
            38 + tint % 28,
            42 + (tint >> 4) % 28,
            48 + (tint >> 8) % 28,
          ),
          child: Center(
            child: Icon(
              Icons.person_outline_rounded,
              size: 96,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
        );
      },
    );
  }
}
