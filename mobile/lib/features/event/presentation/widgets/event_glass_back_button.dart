import 'package:flutter/material.dart';

import 'event_glass_icon_button.dart';

/// Круглая glass-кнопка «назад».
class EventGlassBackButton extends StatelessWidget {
  const EventGlassBackButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return EventGlassIconButton(
      icon: Icons.chevron_left_rounded,
      onPressed: onPressed,
      semanticLabel: 'Назад',
    );
  }
}
