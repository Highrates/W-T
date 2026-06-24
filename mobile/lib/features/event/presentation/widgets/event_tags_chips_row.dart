import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../ui/category_tab.dart';

/// Горизонтальные чипы-теги под заголовком мероприятия.
class EventTagsChipsRow extends StatelessWidget {
  const EventTagsChipsRow({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tags.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s8),
            CategoryTab(
              label: tags[i],
              selected: false,
            ),
          ],
        ],
      ),
    );
  }
}
