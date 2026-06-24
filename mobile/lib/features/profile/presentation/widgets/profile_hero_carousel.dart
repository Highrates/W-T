import 'package:flutter/material.dart';

import '../../../../ui/media/cover_carousel.dart';

/// Hero-фото профиля: свайп по нескольким снимкам.
class ProfileHeroCarousel extends StatelessWidget {
  const ProfileHeroCarousel({
    super.key,
    required this.height,
    required this.photoAssets,
    this.dotsBottomInset = 24,
  });

  final double height;
  final List<String> photoAssets;
  final double dotsBottomInset;

  @override
  Widget build(BuildContext context) {
    return CoverCarousel(
      height: height,
      coverAssets: photoAssets,
      dotsBottomInset: dotsBottomInset,
      dotsVariant: CoverPageDotsVariant.pill,
    );
  }
}
