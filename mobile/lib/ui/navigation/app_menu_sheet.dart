import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_colors.dart';

/// Отступ сверху: плашка почти на весь экран, остаётся полоска фона.
const double kAppMenuSheetTopGap = 56;

/// Скругление верхних углов modal bottom sheet (меню).
const double kAppMenuSheetTopRadius = 24;

const String _menuIconBase = 'assets/icons/common';

/// Модальная нижняя плашка (bottom sheet) — меню приложения.
Future<void> showAppMenuSheet({required BuildContext context}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.appColors.background,
    elevation: 0,
    isScrollControlled: true,
    useSafeArea: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(kAppMenuSheetTopRadius),
      ),
    ),
    builder: (sheetContext) {
      final topInset = MediaQuery.paddingOf(sheetContext).top;
      final sheetHeight = MediaQuery.sizeOf(sheetContext).height -
          topInset -
          kAppMenuSheetTopGap;

      return SizedBox(
        height: sheetHeight,
        child: const _AppMenuSheet(),
      );
    },
  );
}

class _MenuItem {
  const _MenuItem({required this.label, this.iconAsset});

  final String label;
  final String? iconAsset;
}

class _AppMenuSheet extends StatelessWidget {
  const _AppMenuSheet();

  static const _mainItems = <_MenuItem>[
    _MenuItem(
      label: 'Профиль',
      iconAsset: '$_menuIconBase/profile-circle.svg',
    ),
    _MenuItem(
      label: 'Мои события',
      iconAsset: '$_menuIconBase/routing.svg',
    ),
    _MenuItem(
      label: 'Приглашения',
      iconAsset: '$_menuIconBase/invite.svg',
    ),
    _MenuItem(
      label: 'Сохранённые',
      iconAsset: '$_menuIconBase/saves.svg',
    ),
    _MenuItem(
      label: 'Настройки',
      iconAsset: '$_menuIconBase/settings.svg',
    ),
    _MenuItem(
      label: 'Помощь',
      iconAsset: '$_menuIconBase/help.svg',
    ),
  ];

  static const _legalItems = <String>[
    'О приложении',
    'Политика конфиденциальности',
    'Условия использования',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.paddingGlobal,
          AppSpacing.s16,
          AppSpacing.paddingGlobal,
          bottom + AppSpacing.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.caption.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (var i = 0; i < _mainItems.length; i++) ...[
                    _MenuRow(
                      label: _mainItems[i].label,
                      iconAsset: _mainItems[i].iconAsset,
                      style: AppTextStyles.text18_600(color: colors.text),
                      iconColor: colors.caption,
                      onTap: () => _onItemTap(context, _mainItems[i].label),
                    ),
                    if (i < _mainItems.length - 1)
                      const SizedBox(height: AppSpacing.s12),
                  ],
                  const SizedBox(height: AppSpacing.s24),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.caption.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  for (var i = 0; i < _legalItems.length; i++) ...[
                    _MenuRow(
                      label: _legalItems[i],
                      style: AppTextStyles.text13_400(color: colors.caption),
                      compact: true,
                      onTap: () => _onItemTap(context, _legalItems[i]),
                    ),
                    if (i < _legalItems.length - 1)
                      const SizedBox(height: AppSpacing.s4),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTap(BuildContext context, String label) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.style,
    required this.onTap,
    this.iconAsset,
    this.iconColor,
    this.compact = false,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTap;
  final String? iconAsset;
  final Color? iconColor;
  final bool compact;

  static const double _iconSize = 24;
  static const double _iconTextGap = 12;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? AppSpacing.s4 : AppSpacing.s8,
          ),
          child: Row(
            children: [
              if (iconAsset != null) ...[
                SvgPicture.asset(
                  iconAsset!,
                  width: _iconSize,
                  height: _iconSize,
                  fit: BoxFit.contain,
                  colorFilter: iconColor != null
                      ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
                      : null,
                ),
                const SizedBox(width: _iconTextGap),
              ],
              Expanded(child: Text(label, style: style)),
            ],
          ),
        ),
      ),
    );
  }
}
