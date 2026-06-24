import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/event_route_point.dart';

/// Точка маршрута с раскрытием: описание и фото.
class EventExpandableRoutePoint extends StatefulWidget {
  const EventExpandableRoutePoint({
    super.key,
    required this.index,
    required this.point,
    required this.isLast,
    this.initiallyExpanded = false,
  });

  final int index;
  final EventRoutePoint point;
  final bool isLast;
  final bool initiallyExpanded;

  @override
  State<EventExpandableRoutePoint> createState() =>
      _EventExpandableRoutePointState();
}

class _EventExpandableRoutePointState extends State<EventExpandableRoutePoint> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  bool get _hasExpandableContent =>
      (widget.point.description != null &&
          widget.point.description!.isNotEmpty) ||
      widget.point.photoAssets.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const indexSize = 28.0;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.isLast ? 0 : AppSpacing.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: indexSize,
                  height: indexSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.secondBackground,
                  ),
                  child: Text(
                    '${widget.index}',
                    style: AppTextStyles.text14_550(color: colors.text),
                  ),
                ),
                if (!widget.isLast) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 2,
                    height: 24,
                    color: colors.caption.withValues(alpha: 0.25),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _hasExpandableContent
                    ? () => setState(() => _expanded = !_expanded)
                    : null,
                borderRadius: BorderRadius.circular(AppRadius.r8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.s4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.point.title,
                                  style: AppTextStyles.text18_600(
                                    color: colors.text,
                                  ),
                                ),
                                if (widget.point.detail != null) ...[
                                  const SizedBox(height: AppSpacing.s4),
                                  Text(
                                    widget.point.detail!,
                                    style: AppTextStyles.text14_550(
                                      color: colors.caption,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_hasExpandableContent) ...[
                            const SizedBox(width: AppSpacing.s8),
                            AnimatedRotation(
                              turns: _expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: colors.caption,
                              ),
                            ),
                          ],
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        alignment: Alignment.topLeft,
                        clipBehavior: Clip.hardEdge,
                        child: _expanded && _hasExpandableContent
                            ? _ExpandedBody(point: widget.point)
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
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

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({required this.point});

  final EventRoutePoint point;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (point.description != null) ...[
          const SizedBox(height: AppSpacing.s12),
          Text(
            point.description!,
            style: AppTextStyles.text14_550(color: colors.text),
          ),
        ],
        for (var i = 0; i < point.photoAssets.length; i++) ...[
          const SizedBox(height: AppSpacing.s12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r8),
            child: Image.asset(
              point.photoAssets[i],
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ],
    );
  }
}
