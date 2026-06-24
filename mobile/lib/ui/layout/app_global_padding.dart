import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Обёртка с [AppSpacing.paddingGlobal] по горизонтали.
class AppGlobalPadding extends StatelessWidget {
  const AppGlobalPadding({
    super.key,
    required this.child,
    this.includeVertical = false,
  });

  final Widget child;
  final bool includeVertical;

  static EdgeInsets padding({bool vertical = false}) {
    if (vertical) {
      return const EdgeInsets.all(AppSpacing.paddingGlobal);
    }
    return const EdgeInsets.symmetric(
      horizontal: AppSpacing.paddingGlobal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding(vertical: includeVertical),
      child: child,
    );
  }
}
