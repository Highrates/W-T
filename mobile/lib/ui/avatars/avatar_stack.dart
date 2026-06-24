import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';

/// Стек круглых аватаров с наложением (до [maxCount] штук).
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.assets,
    this.size = 16,
    this.overlap = 10,
    this.maxCount = 3,
    this.ringColor,
    this.onAvatarTap,
  });

  final List<String> assets;
  final double size;
  final double overlap;
  final int maxCount;
  final Color? ringColor;
  final ValueChanged<int>? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ring = ringColor ?? colors.background;
    final shown = assets.take(maxCount).toList(growable: false);
    final width = size + (shown.length - 1) * overlap;

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * overlap,
              child: GestureDetector(
                onTap: onAvatarTap != null ? () => onAvatarTap!(i) : null,
                behavior: HitTestBehavior.opaque,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ring,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: ClipOval(
                      child: Image.asset(
                        shown[i],
                        width: size - 2,
                        height: size - 2,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
