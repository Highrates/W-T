import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_colors.dart';
import '../navigation/app_menu_sheet.dart';

/// Общий каркас экранов с hero-каруселью и draggable sheet.
///
/// Используется на [EventScreen] и [UserProfileScreen].
class HeroDetailScaffold extends StatelessWidget {
  const HeroDetailScaffold({
    super.key,
    required this.heroBuilder,
    required this.sheetBuilder,
    required this.chromeBuilder,
    this.topOverlay,
    this.sheetBottomPadding,
  });

  static const double heroVisibleFraction = 0.70;
  static const double sheetOverlap = 30;
  static const double sheetMaxSize = 1.0;

  final Widget Function(
    BuildContext context,
    double heroHeight,
    double dotsBottomInset,
  ) heroBuilder;

  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    double bottomPadding,
  ) sheetBuilder;

  final Widget Function(BuildContext context, double topInset) chromeBuilder;

  /// Баннер / overlay над hero (например, «Заявка отправлена»).
  final Widget? topOverlay;

  /// Нижний padding контента sheet; по умолчанию safeBottom + 24.
  final double Function(double safeBottom)? sheetBottomPadding;

  static double heroHeightFor(double screenHeight) =>
      screenHeight * heroVisibleFraction;

  static double dotsBottomInsetFor() => sheetOverlap + AppSpacing.s12;

  static double initialSheetSize(double screenHeight) {
    final sheetTop = screenHeight * heroVisibleFraction - sheetOverlap;
    final sheetHeight = screenHeight - sheetTop;
    return (sheetHeight / screenHeight).clamp(0.28, 0.52);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final initialSheetSize = HeroDetailScaffold.initialSheetSize(screenHeight);
    final heroHeight = heroHeightFor(screenHeight);
    final dotsBottomInset = dotsBottomInsetFor();
    final scrollBottomPad =
        sheetBottomPadding?.call(bottom) ?? bottom + AppSpacing.s24;

    return Scaffold(
      backgroundColor: colors.heroBackdrop,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: heroBuilder(context, heroHeight, dotsBottomInset),
          ),
          DraggableScrollableSheet(
            initialChildSize: initialSheetSize,
            minChildSize: initialSheetSize,
            maxChildSize: sheetMaxSize,
            snap: true,
            snapSizes: [initialSheetSize, sheetMaxSize],
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
                  child: sheetBuilder(
                    context,
                    scrollController,
                    scrollBottomPad,
                  ),
                ),
              );
            },
          ),
          if (topOverlay != null) topOverlay!,
          chromeBuilder(context, top),
        ],
      ),
    );
  }
}
