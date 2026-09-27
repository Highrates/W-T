import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_profile.dart';
import '../../../ui/media/cover_image.dart';
import '../../../ui/navigation/app_bottom_nav_bar.dart';
import '../../profile/presentation/open_user_profile.dart';
import '../application/people_controller.dart';
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

    final peopleAsync = ref.watch(peopleListProvider);

    return peopleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Не удалось загрузить людей\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (profiles) => _PeoplePager(
        profiles: profiles,
        pageController: _pageController,
        bottomInset: bottomInset,
      ),
    );
  }
}

class _PeoplePager extends StatelessWidget {
  const _PeoplePager({
    required this.profiles,
    required this.pageController,
    required this.bottomInset,
  });

  final List<UserProfile> profiles;
  final PageController pageController;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return Center(
        child: Text(
          'Никого не найдено',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return PageView.builder(
      controller: pageController,
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
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final ref = profile.heroPhotoAssets.first;

    if (coverRefIsAsset(ref) || coverRefIsNetwork(ref)) {
      return CoverImage(
        ref: ref,
        fit: BoxFit.cover,
      );
    }

    return Image.asset(
      ref,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _placeholder(profile.id),
    );
  }

  Widget _placeholder(String id) {
    final tint = id.hashCode.abs();
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
  }
}
