import 'package:flutter/material.dart';

import '../../../../ui/media/cover_carousel.dart';

/// Hero-карусель обложек на странице мероприятия.
class EventHeroCarousel extends StatelessWidget {
  const EventHeroCarousel({
    super.key,
    required this.height,
    required this.coverAssets,
    this.dotsBottomInset = 24,
  });

  final double height;
  final List<String> coverAssets;
  final double dotsBottomInset;

  @override
  Widget build(BuildContext context) {
    return CoverCarousel(
      height: height,
      coverAssets: coverAssets,
      dotsBottomInset: dotsBottomInset,
      dotsVariant: CoverPageDotsVariant.pill,
    );
  }
}
