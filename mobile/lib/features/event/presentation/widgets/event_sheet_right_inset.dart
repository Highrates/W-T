import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Правый отступ шторки — не применяется к горизонтальной ленте аватаров.
class EventSheetRightInset extends StatelessWidget {
  const EventSheetRightInset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.paddingGlobal),
      child: child,
    );
  }
}
