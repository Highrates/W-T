import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_colors.dart';

/// Стиль индикатора страниц на обложке.
enum CoverPageDotsVariant {
  /// Точки без подложки (лента карточек).
  inline,

  /// Точки в тёмной pill-подложке (hero мероприятия).
  pill,
}

/// Индикатор страниц карусели обложек.
class CoverPageDots extends StatelessWidget {
  const CoverPageDots({
    super.key,
    required this.count,
    required this.index,
    this.variant = CoverPageDotsVariant.inline,
  });

  final int count;
  final int index;
  final CoverPageDotsVariant variant;

  static const double _dotSize = 6;
  static const double _activeDotWidth = 16;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: i == index ? _activeDotWidth : _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              color: colors.onImagePrimary.withValues(
                alpha: i == index ? 1 : 0.45,
              ),
              borderRadius: BorderRadius.circular(_dotSize / 2),
            ),
          ),
        ],
      ],
    );

    if (variant == CoverPageDotsVariant.inline) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [dots],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.heroBackdrop.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        child: dots,
      ),
    );
  }
}

/// Карусель обложек с опциональным оверлеем и точками.
class CoverCarousel extends StatefulWidget {
  const CoverCarousel({
    super.key,
    required this.coverAssets,
    this.height,
    this.dotsBottomInset = AppSpacing.s12,
    this.dotsVariant = CoverPageDotsVariant.inline,
    this.overlayBottomLeft,
    this.overlayBottomLeftOffset,
  });

  final List<String> coverAssets;
  final double? height;
  final double dotsBottomInset;
  final CoverPageDotsVariant dotsVariant;
  final Widget? overlayBottomLeft;

  /// Смещение оверлея снизу (для карточки с точками).
  final double? overlayBottomLeftOffset;

  @override
  State<CoverCarousel> createState() => _CoverCarouselState();
}

class _CoverCarouselState extends State<CoverCarousel> {
  late final PageController _pageController;
  int _pageIndex = 0;

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
    final assets = widget.coverAssets;
    final showDots = assets.length > 1;
    final overlayBottom = widget.overlayBottomLeftOffset ??
        (showDots ? AppSpacing.s32 : AppSpacing.s8) -
            AppSpacing.s4;

    final carousel = Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _pageIndex = index),
          itemCount: assets.length,
          itemBuilder: (context, index) {
            return Image.asset(assets[index], fit: BoxFit.cover);
          },
        ),
        if (widget.overlayBottomLeft != null)
          Positioned(
            left: AppSpacing.s8,
            bottom: overlayBottom,
            child: widget.overlayBottomLeft!,
          ),
        if (showDots)
          Positioned(
            left: 0,
            right: 0,
            bottom: widget.dotsBottomInset,
            child: widget.dotsVariant == CoverPageDotsVariant.pill
                ? Center(
                    child: CoverPageDots(
                      count: assets.length,
                      index: _pageIndex,
                      variant: widget.dotsVariant,
                    ),
                  )
                : CoverPageDots(
                    count: assets.length,
                    index: _pageIndex,
                    variant: widget.dotsVariant,
                  ),
          ),
      ],
    );

    if (widget.height != null) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: carousel,
      );
    }

    return carousel;
  }
}
