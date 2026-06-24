import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../ui/ui_kit.dart';

/// Превью UI-kit для проверки компонентов.
class UiKitPreviewScreen extends StatefulWidget {
  const UiKitPreviewScreen({super.key});

  @override
  State<UiKitPreviewScreen> createState() => _UiKitPreviewScreenState();
}

class _UiKitPreviewScreenState extends State<UiKitPreviewScreen> {
  int _selectedTab = 0;
  static const _tabs = ['Пешком', 'Авто', 'Меню', 'Люди'];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppGlobalPadding.padding(),
          children: [
            Text('UI-kit', style: context.text18_600),
            const SizedBox(height: AppSpacing.s24),
            Text('PrimaryButtonBlack', style: context.text14_550),
            const SizedBox(height: AppSpacing.s8),
            PrimaryButtonBlack(
              label: '+ Хочу с вами',
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.s16),
            Text('PrimaryButtonSmoke', style: context.text14_550),
            const SizedBox(height: AppSpacing.s8),
            PrimaryButtonSmoke(
              label: 'Продолжить',
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.s24),
            Text('SecondaryButton', style: context.text14_550),
            const SizedBox(height: AppSpacing.s8),
            SecondaryButton(
              label: 'Сочи 🌴',
              icon: const Icon(Icons.location_on_outlined),
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.s8),
            SecondaryButton(
              label: 'Все',
              style: SecondaryButtonStyle.whiteOutlined,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.s24),
            Text('CategoryTab', style: context.text14_550),
            const SizedBox(height: AppSpacing.s8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < _tabs.length - 1 ? AppSpacing.s8 : 0,
                    ),
                    child: CategoryTab(
                      label: _tabs[index],
                      selected: _selectedTab == index,
                      onTap: () => setState(() => _selectedTab = index),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              'padding-global: ${AppSpacing.paddingGlobal}px',
              style: AppTextStyles.text13_400(color: colors.caption),
            ),
          ],
        ),
      ),
    );
  }
}
