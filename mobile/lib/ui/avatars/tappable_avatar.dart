import 'package:flutter/material.dart';

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
      child: Image.asset(
        avatarAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (onTap == null) return image;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: image,
      ),
    );
  }
}
