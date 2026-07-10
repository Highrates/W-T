import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';

/// Волнистая «дорога» на фоне ленты карточек — без видимого начала и конца.
class CardsRoadBackground extends StatelessWidget {
  const CardsRoadBackground({super.key});

  /// Период изгиба по вертикали (px).
  static const double waveLength = 320;

  /// Амплитуда горизонтального изгиба — доля ширины экрана.
  static const double amplitudeFactor = 0.22;

  @override
  Widget build(BuildContext context) {
    final caption = context.appColors.caption;

    return IgnorePointer(
      child: CustomPaint(
        painter: _CardsRoadPathPainter(
          lineColor: caption.withValues(alpha: 0.14),
          haloColor: caption.withValues(alpha: 0.05),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CardsRoadPathPainter extends CustomPainter {
  _CardsRoadPathPainter({
    required this.lineColor,
    required this.haloColor,
  });

  final Color lineColor;
  final Color haloColor;

  static const double _overscanY = 96;
  static const double _step = 5;

  Path _buildRoadPath(Size size) {
    final centerX = size.width * 0.54;
    final amplitude = size.width * CardsRoadBackground.amplitudeFactor;
    final path = Path();

    var started = false;
    for (
      var y = -_overscanY;
      y <= size.height + _overscanY;
      y += _step
    ) {
      final phase = y / CardsRoadBackground.waveLength * math.pi * 2;
      final x = centerX + math.sin(phase) * amplitude;
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashLength = 14.0;
    const gapLength = 10.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final road = _buildRoadPath(size);

    canvas.drawPath(
      road,
      Paint()
        ..color = haloColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    _drawDashedPath(
      canvas,
      road,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _CardsRoadPathPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.haloColor != haloColor;
  }
}
