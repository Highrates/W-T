import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../core/theme/app_glass_tokens.dart';
import '../../core/theme/app_spacing.dart';
import 'app_nav_tab.dart';

/// Нижняя навигация: [menu] · [people | feed | map] · [profile].
///
/// [liquid_glass_renderer](https://pub.dev/packages/liquid_glass_renderer) поверх ленты.
class AppBottomNavBar {
  AppBottomNavBar._();

  static const double circleSize = 48;

  /// Glass-обёртка trio: px/py 4px, radius 100 (капсула).
  static const double trioGlassPaddingX = AppSpacing.s4;
  static const double trioGlassPaddingY = AppSpacing.s4;

  /// Подложка вкладки: круг [trioTabItemSize], иконка 28px по центру.
  static const double trioTabPadding = AppSpacing.s12;
  static const double trioTabRadius = 100;
  static const double trioGap = AppSpacing.s12;
  static const double trioTabIconSize = 28;

  static const double barHeight = 64;
  /// Доп. отступ над safe area; 0 — максимально низко.
  static const double barBottomMinimum = 0;

  /// Масштаб nav при скролле ленты вниз (~−15%). Позиции фиксированы по углам/центру.
  static const double feedScrollCompactScale = 0.85;

  static const Duration feedScrollScaleDuration = Duration(milliseconds: 220);

  static const String _iconBase = 'assets/icons/nav';

  static String _navIcon(String name, {required bool active}) =>
      '$_iconBase/$name (${active ? 'bold' : 'line'}).svg';

  static double get trioTabItemSize => trioTabPadding * 2 + trioTabIconSize;

  static double get trioRowWidth => trioTabItemSize * 3 + trioGap * 2;

  static double get trioRowHeight => trioTabItemSize;

  static double get pillHeight => trioRowHeight + trioGlassPaddingY * 2;

  static double get pillWidth => trioRowWidth + trioGlassPaddingX * 2;

  /// Бургер 24×12 (viewBox 20×11, contain → scale 12/11).
  static const double menuIconWidth = 24;
  static const double menuIconHeight = 12;

  static LiquidGlassSettings get _glassSettings => AppGlassTokens.navBarGlass;

  /// Сохраняет анимацию кружка при смене вкладок (в т.ч. карта).
  static final GlobalKey _trioTabsKey = GlobalKey();

  static _NavBarLayout _layout({
    required double screenWidth,
    required double safeAreaBottom,
  }) {
    final horizontal = AppSpacing.paddingGlobal;
    final barBottom = safeAreaBottom + barBottomMinimum;
    final circleBottom = barBottom;
    final pillBottom = barBottom;
    return _NavBarLayout(
      horizontal: horizontal,
      circleBottom: circleBottom,
      pillBottom: pillBottom,
      pillLeft: (screenWidth - pillWidth) / 2,
    );
  }

  /// Слой glass-навигации (Stack поверх [MainShellScreen] body).
  static Widget buildGlassNavOverlay({
    required BuildContext context,
    required double screenWidth,
    required double safeAreaBottom,
    required AppNavTab currentTab,
    required ValueChanged<AppNavTab> onTabChanged,
    VoidCallback? onMenuTap,
    VoidCallback? onProfileTap,
    required String profileAvatarAsset,
    double scale = 1,
  }) {
    final layout = _layout(
      screenWidth: screenWidth,
      safeAreaBottom: safeAreaBottom,
    );
    const iconColor = AppGlassTokens.navInactiveIcon;
    const activeIconColor = AppGlassTokens.navActiveIcon;

    // Platform view карты ломает backdrop-blur — всегда fake glass, иначе при
    // переключении fake/real срывается анимация кружка.
    return Positioned.fill(
      child: LiquidGlassLayer(
        key: const ValueKey<String>('app-bottom-nav-glass'),
        settings: _glassSettings,
        fake: true,
        useBackdropGroup: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: layout.horizontal,
              bottom: layout.circleBottom,
              child: _NavScaleWrapper(
                scale: scale,
                alignment: Alignment.bottomLeft,
                child: _NavGlassTile(
                  width: circleSize,
                  height: circleSize,
                  shape: LiquidRoundedSuperellipse(
                    borderRadius: circleSize / 2,
                  ),
                  onTap: onMenuTap,
                  child: _NavSvgIcon(
                    asset: '$_iconBase/menu.svg',
                    width: menuIconWidth,
                    height: menuIconHeight,
                    color: iconColor,
                  ),
                ),
              ),
            ),
            Positioned(
              left: layout.pillLeft,
              bottom: layout.pillBottom,
              child: _NavScaleWrapper(
                scale: scale,
                alignment: Alignment.bottomCenter,
                child: _NavGlassTile(
                  width: pillWidth,
                  height: pillHeight,
                  clipBehavior: Clip.none,
                  shape: LiquidRoundedSuperellipse(
                    borderRadius: trioTabRadius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: trioGlassPaddingX,
                      vertical: trioGlassPaddingY,
                    ),
                    child: _NavTrioTabs(
                      key: _trioTabsKey,
                      currentTab: currentTab,
                      iconColor: iconColor,
                      activeIconColor: activeIconColor,
                      onTabChanged: onTabChanged,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: layout.horizontal,
              bottom: layout.circleBottom,
              child: _NavScaleWrapper(
                scale: scale,
                alignment: Alignment.bottomRight,
                child: _NavGlassTile(
                  width: circleSize,
                  height: circleSize,
                  expandChild: true,
                  shape: LiquidRoundedSuperellipse(
                    borderRadius: circleSize / 2,
                  ),
                  onTap: onProfileTap,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        profileAvatarAsset,
                        fit: BoxFit.cover,
                      ),
                      const _NavCircleBorder(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Тени под glass (вне [LiquidGlassLayer], иначе не видны).
  static List<Widget> buildNavShadowLayer({
    required BuildContext context,
    required double screenWidth,
    required double safeAreaBottom,
    double scale = 1,
  }) {
    final layout = _layout(
      screenWidth: screenWidth,
      safeAreaBottom: safeAreaBottom,
    );

    return [
      Positioned.fill(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: layout.horizontal,
              bottom: layout.circleBottom,
              child: _NavScaleWrapper(
                scale: scale,
                alignment: Alignment.bottomLeft,
                child: _NavShadowPlate(
                  width: circleSize,
                  height: circleSize,
                  borderRadius: circleSize / 2,
                ),
              ),
            ),
            Positioned(
              left: layout.pillLeft,
              bottom: layout.pillBottom,
              child: _NavScaleWrapper(
                scale: scale,
                alignment: Alignment.bottomCenter,
                child: _NavShadowPlate(
                  width: pillWidth,
                  height: pillHeight,
                  borderRadius: trioTabRadius,
                ),
              ),
            ),
            Positioned(
              right: layout.horizontal,
              bottom: layout.circleBottom,
              child: _NavScaleWrapper(
                scale: scale,
                alignment: Alignment.bottomRight,
                child: _NavShadowPlate(
                  width: circleSize,
                  height: circleSize,
                  borderRadius: circleSize / 2,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _NavScaleWrapper extends StatelessWidget {
  const _NavScaleWrapper({
    required this.scale,
    required this.child,
    this.alignment = Alignment.bottomCenter,
  });

  final double scale;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: scale,
      duration: AppBottomNavBar.feedScrollScaleDuration,
      curve: Curves.easeOutCubic,
      alignment: alignment,
      child: child,
    );
  }
}

/// Обводка круга nav — как glass rim у бургера.
class _NavCircleBorder extends StatelessWidget {
  const _NavCircleBorder();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppGlassTokens.navCircleBorderColor,
            width: AppGlassTokens.navCircleBorderWidth,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
      ),
    );
  }
}

class _NavBarLayout {
  const _NavBarLayout({
    required this.horizontal,
    required this.circleBottom,
    required this.pillBottom,
    required this.pillLeft,
  });

  final double horizontal;
  final double circleBottom;
  final double pillBottom;
  final double pillLeft;
}

/// Только тень Figma (рисуется под [LiquidGlass]).
class _NavShadowPlate extends StatelessWidget {
  const _NavShadowPlate({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isCircle = borderRadius >= width / 2 - 0.5;

    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: isCircle
              ? null
              : BorderRadius.circular(borderRadius),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          boxShadow: AppGlassTokens.lightNavShadows,
        ),
      ),
    );
  }
}

/// Одна кнопка nav: [LiquidGlass].
class _NavGlassTile extends StatelessWidget {
  const _NavGlassTile({
    required this.width,
    required this.height,
    required this.shape,
    required this.child,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
    this.expandChild = false,
  });

  final double width;
  final double height;
  final LiquidShape shape;
  final Widget child;
  final VoidCallback? onTap;
  final Clip clipBehavior;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      shape: shape,
      clipBehavior: clipBehavior,
      child: SizedBox(
        width: width,
        height: height,
        child: onTap == null
            ? (expandChild
                ? SizedBox(width: width, height: height, child: child)
                : Center(child: child))
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      switch (shape) {
                        LiquidRoundedSuperellipse(:final borderRadius) =>
                          borderRadius,
                        LiquidRoundedRectangle(:final borderRadius) =>
                          borderRadius,
                        LiquidOval() => width / 2,
                      },
                    ),
                  ),
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  child: expandChild
                      ? SizedBox(width: width, height: height, child: child)
                      : Center(child: child),
                ),
              ),
      ),
    );
  }
}

/// Три вкладки с одной подложкой, перетекающей между слотами.
class _NavTrioTabs extends StatefulWidget {
  const _NavTrioTabs({
    super.key,
    required this.currentTab,
    required this.iconColor,
    required this.activeIconColor,
    required this.onTabChanged,
  });

  final AppNavTab currentTab;
  final Color iconColor;
  final Color activeIconColor;
  final ValueChanged<AppNavTab> onTabChanged;

  @override
  State<_NavTrioTabs> createState() => _NavTrioTabsState();
}

class _NavTrioTabsState extends State<_NavTrioTabs> {
  static const _indicatorDuration = Duration(milliseconds: 280);

  late int _activeIndex;

  @override
  void initState() {
    super.initState();
    _activeIndex = _indexFor(widget.currentTab);
  }

  @override
  void didUpdateWidget(covariant _NavTrioTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _indexFor(widget.currentTab);
    if (nextIndex != _activeIndex) {
      setState(() => _activeIndex = nextIndex);
    }
  }

  static int _indexFor(AppNavTab tab) => switch (tab) {
        AppNavTab.people => 0,
        AppNavTab.feed => 1,
        AppNavTab.map => 2,
      };

  @override
  Widget build(BuildContext context) {
    final slotSize = AppBottomNavBar.trioTabItemSize;
    final step = slotSize + AppBottomNavBar.trioGap;

    return SizedBox(
      width: AppBottomNavBar.trioRowWidth,
      height: AppBottomNavBar.trioRowHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: _indicatorDuration,
            curve: Curves.easeOutCubic,
            left: _activeIndex * step,
            top: 0,
            width: slotSize,
            height: slotSize,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppGlassTokens.navActiveIndicator,
                shape: BoxShape.circle,
                boxShadow: AppGlassTokens.activeTabIndicatorShadows,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavTabSlot(
                lineAsset: AppBottomNavBar._navIcon('people', active: false),
                boldAsset: AppBottomNavBar._navIcon('people', active: true),
                tab: AppNavTab.people,
                currentTab: widget.currentTab,
                iconColor: widget.iconColor,
                activeIconColor: widget.activeIconColor,
                onTap: () => widget.onTabChanged(AppNavTab.people),
              ),
              const SizedBox(width: AppBottomNavBar.trioGap),
              _NavTabSlot(
                lineAsset: AppBottomNavBar._navIcon('feed', active: false),
                boldAsset: AppBottomNavBar._navIcon('feed', active: true),
                tab: AppNavTab.feed,
                currentTab: widget.currentTab,
                iconColor: widget.iconColor,
                activeIconColor: widget.activeIconColor,
                onTap: () => widget.onTabChanged(AppNavTab.feed),
              ),
              const SizedBox(width: AppBottomNavBar.trioGap),
              _NavTabSlot(
                lineAsset: AppBottomNavBar._navIcon('map', active: false),
                boldAsset: AppBottomNavBar._navIcon('map', active: true),
                tab: AppNavTab.map,
                currentTab: widget.currentTab,
                iconColor: widget.iconColor,
                activeIconColor: widget.activeIconColor,
                onTap: () => widget.onTabChanged(AppNavTab.map),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavTabSlot extends StatelessWidget {
  const _NavTabSlot({
    required this.lineAsset,
    required this.boldAsset,
    required this.tab,
    required this.currentTab,
    required this.iconColor,
    required this.activeIconColor,
    required this.onTap,
  });

  final String lineAsset;
  final String boldAsset;
  final AppNavTab tab;
  final AppNavTab currentTab;
  final Color iconColor;
  final Color activeIconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = tab == currentTab;
    final asset = isActive ? boldAsset : lineAsset;
    final color = isActive ? activeIconColor : iconColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: AppBottomNavBar.trioTabItemSize,
        height: AppBottomNavBar.trioTabItemSize,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _NavSvgIcon(
              key: ValueKey<String>(asset),
              asset: asset,
              width: AppBottomNavBar.trioTabIconSize,
              height: AppBottomNavBar.trioTabIconSize,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSvgIcon extends StatelessWidget {
  const _NavSvgIcon({
    super.key,
    required this.asset,
    required this.color,
    this.width,
    this.height,
  });

  final String asset;
  final Color color;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
