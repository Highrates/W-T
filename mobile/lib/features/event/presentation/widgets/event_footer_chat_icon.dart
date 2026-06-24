import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../cards/presentation/widgets/walk_card_join_effects.dart';

/// Иконка чата маршрута в glass-футере (круг = высота CTA).
class EventFooterChatIcon extends StatelessWidget {
  const EventFooterChatIcon({
    super.key,
    required this.enabled,
    this.onTap,
  });

  final bool enabled;
  final VoidCallback? onTap;

  static const String _asset = 'assets/icons/actions/Chat.svg';
  static const double _iconSize = 18;
  static const double _strokeWidth = 0.3;

  @override
  Widget build(BuildContext context) {
    final size = WalkCardJoinSection.eventFooterJoinHeight;
    final iconColor = Colors.white.withValues(alpha: enabled ? 0.9 : 0.35);
    final strokeColor = Colors.white.withValues(alpha: 0.3);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: strokeColor, width: _strokeWidth),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onTap : null,
            customBorder: const CircleBorder(),
            child: Center(
              child: SvgPicture.asset(
                _asset,
                width: _iconSize,
                height: _iconSize,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
