import 'package:flutter/material.dart';

import '../media/cover_image.dart';

/// Круглый аватар с переходом в профиль.
class TappableAvatar extends StatelessWidget {
  const TappableAvatar({
    super.key,
    required this.avatarAsset,
    required this.size,
    this.onTap,
  });

  final String avatarAsset;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final image = ClipOval(
      child: coverRefIsAsset(avatarAsset) || coverRefIsNetwork(avatarAsset)
          ? CoverImage(
              ref: avatarAsset,
              fit: BoxFit.cover,
            )
          : Image.asset(
              avatarAsset,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
    );

    final sized = SizedBox(width: size, height: size, child: image);

    if (onTap == null) return sized;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: sized,
      ),
    );
  }
}
