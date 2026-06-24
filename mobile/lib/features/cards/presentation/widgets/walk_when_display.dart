import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_spacing.dart';

/// Время события: дата или анимированные точки, если скрыто.
class WalkWhenDisplay extends StatelessWidget {
  const WalkWhenDisplay({
    super.key,
    required this.isHidden,
    required this.whenLabel,
    required this.iconColor,
    required this.textStyle,
  });

  final bool isHidden;
  final String? whenLabel;
  final Color iconColor;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/common/time.svg',
          width: 14,
          height: 14,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
        const SizedBox(width: AppSpacing.s4),
        if (isHidden)
          WalkHiddenWhenDots(color: iconColor)
        else
          Flexible(
            child: Text(
              whenLabel ?? '',
              style: textStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

/// Плавающие точки вместо скрытой даты.
class WalkHiddenWhenDots extends StatefulWidget {
  const WalkHiddenWhenDots({super.key, required this.color});

  final Color color;

  @override
  State<WalkHiddenWhenDots> createState() => _WalkHiddenWhenDotsState();
}

class _WalkHiddenWhenDotsState extends State<WalkHiddenWhenDots>
    with SingleTickerProviderStateMixin {
  static const double _dotSize = 5;
  static const double _gap = 5;
  static const int _dotCount = 3;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _dotCount; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              Opacity(
                opacity: 0.35 +
                    0.55 *
                        ((math.sin((_controller.value * math.pi * 2) +
                                    (i * math.pi * 2 / _dotCount)) +
                                1) /
                            2),
                child: Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
