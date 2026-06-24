import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../../core/theme/app_glass_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../ui/chips/glass_chip_button.dart';
import '../../../../ui/dropdown/chip_dropdown.dart';
import '../../../../ui/icons/location_icon.dart';
import '../../../../ui/layout/app_global_padding.dart';
import '../../data/location_filter_mock.dart';

/// Стиль строки локации и фильтра.
enum ShellLocationFilterStyle {
  /// Лента: текст + иконка фильтра по краям.
  plain,

  /// Люди / карта: glass-чипы по краям.
  chips,
}

/// Локация слева, фильтр справа ([MainAxisAlignment.spaceBetween]).
class ShellLocationFilterRow extends StatelessWidget {
  const ShellLocationFilterRow({
    super.key,
    required this.style,
    required this.location,
    required this.onLocationChanged,
    required this.onFilterTap,
    this.filterActive = false,
    this.simulatedGlass = false,
  });

  final ShellLocationFilterStyle style;
  final LocationFilterOption location;
  final ValueChanged<LocationFilterOption> onLocationChanged;
  final VoidCallback onFilterTap;
  final bool filterActive;

  /// Карта: без [LiquidGlassLayer] — platform view ломает backdrop.
  final bool simulatedGlass;

  /// Высота plain-строки в ленте (без safe area).
  static double get plainContentHeight => AppSpacing.s4 * 2 + 20;

  /// Высота ряда glass-чипов.
  static double get chipRowHeight => GlassChipButton.headerHeight;

  static LiquidGlassSettings get _glassSettings => AppGlassTokens.navBarGlass;

  static const _chipPadding = GlassChipButton.headerPadding;

  static const _filterAsset = 'assets/icons/actions/filter.svg';

  static List<ChipDropdownEntry> get _radiusEntries => [
        for (final o in LocationFilterMock.radiusOptions)
          ChipDropdownEntry(id: o.id, label: o.label),
      ];

  static List<ChipDropdownEntry> get _cityEntries => [
        for (final o in LocationFilterMock.cityOptions)
          ChipDropdownEntry(id: o.id, label: o.label),
      ];

  Widget _filterIcon({required Color color, double size = 20}) {
    return SvgPicture.asset(
      _filterAsset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  Widget _locationDropdown({
    required BuildContext context,
    required Widget Function(VoidCallback open) chipBuilder,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final menuWidth = screenWidth - AppSpacing.paddingGlobal * 2;

    return ChipDropdown(
      mode: ChipDropdownMode.single,
      selectedId: location.id,
      searchPlaceholder: 'Город',
      sections: [
        ChipDropdownSection(entries: _radiusEntries),
        ChipDropdownSection(entries: _cityEntries, searchable: true),
      ],
      menuWidth: menuWidth,
      onSingleSelected: (entry) {
        final option = LocationFilterMock.all.firstWhere(
          (o) => o.id == entry.id,
        );
        onLocationChanged(option);
      },
      chipBuilder: chipBuilder,
    );
  }

  Widget _plainLocation(BuildContext context) {
    final colors = context.appColors;

    return _locationDropdown(
      context: context,
      chipBuilder: (open) => Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: open,
            borderRadius: BorderRadius.circular(AppSpacing.s8),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LocationIcon(
                    color: colors.text,
                    variant: LocationIconVariant.line,
                  ),
                  const SizedBox(width: AppSpacing.gap6),
                  Text(
                    location.label,
                    style: AppTextStyles.text14_550(color: colors.text),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipLocation(BuildContext context) {
    return _locationDropdown(
      context: context,
      chipBuilder: (open) => GlassChipButton(
        label: location.label,
        contentPadding: _chipPadding,
        simulatedGlass: simulatedGlass,
        icon: const LocationIcon(
          variant: LocationIconVariant.line,
          color: AppGlassTokens.chipText,
        ),
        onPressed: open,
      ),
    );
  }

  Widget _plainFilter(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onFilterTap,
        borderRadius: BorderRadius.circular(AppSpacing.s8),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
          child: _filterIcon(color: colors.text),
        ),
      ),
    );
  }

  Widget _chipFilter() {
    return GlassChipButton(
      label: '',
      iconOnly: true,
      contentPadding: _chipPadding,
      simulatedGlass: simulatedGlass,
      icon: _filterIcon(
        color: AppGlassTokens.chipText,
        size: GlassChipButton.iconSize,
      ),
      selected: filterActive,
      onPressed: onFilterTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPlain = style == ShellLocationFilterStyle.plain;
    if (isPlain) {
      return AppGlobalPadding(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _plainLocation(context),
            _plainFilter(context),
          ],
        ),
      );
    }

    final chips = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _chipLocation(context),
        _chipFilter(),
      ],
    );

    if (simulatedGlass) {
      return AppGlobalPadding(child: chips);
    }

    return AppGlobalPadding(
      child: LiquidGlassLayer(
        settings: _glassSettings,
        useBackdropGroup: true,
        child: chips,
      ),
    );
  }
}
