import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../media/cover_image.dart';

/// Рендер bitmap-меток для Yandex MapKit (кружки с фото / номер вехи).
abstract final class MapMarkerRenderer {
  static Future<ui.Image> eventPhotoMarker({
    required String imageRef,
    double size = 108,
    String fallbackAsset = 'assets/images/cards/01.jpg',
  }) async {
    final photo = await _loadImage(imageRef, fallbackAsset: fallbackAsset);
    return _drawPhotoCircle(
      photo: photo,
      size: size,
      borderWidth: 4,
      ringColor: Colors.white,
      shadowOpacity: 0.2,
    );
  }

  static Future<ui.Image> routeWaypointMarker({
    required int index,
    String? photoAsset,
    double size = 80,
    String fallbackAsset = 'assets/images/cards/01.jpg',
  }) async {
    if (photoAsset != null && photoAsset.isNotEmpty) {
      final photo = await _loadImage(photoAsset, fallbackAsset: fallbackAsset);
      return _drawPhotoCircle(
        photo: photo,
        size: size,
        borderWidth: 3,
        ringColor: Colors.white,
        badgeText: '$index',
      );
    }
    return _drawNumberBadge(index: index, size: size);
  }

  static Future<ui.Image> _loadImage(
    String ref, {
    required String fallbackAsset,
  }) async {
    try {
      if (coverRefIsNetwork(ref)) {
        return await _loadNetworkImage(ref);
      }
      if (coverRefIsAsset(ref)) {
        return await _loadAssetImage(ref);
      }
      if (ref.isNotEmpty) {
        final file = File(ref);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          return frame.image;
        }
      }
    } catch (_) {}
    return _loadAssetImage(fallbackAsset);
  }

  static Future<ui.Image> _loadAssetImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<ui.Image> _loadNetworkImage(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw StateError('HTTP ${response.statusCode}');
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      client.close();
    }
  }

  static Future<ui.Image> _drawPhotoCircle({
    required ui.Image photo,
    required double size,
    required double borderWidth,
    required Color ringColor,
    double shadowOpacity = 0,
    String? badgeText,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 2;

    if (shadowOpacity > 0) {
      canvas.drawCircle(
        center + const Offset(0, 2),
        radius - 1,
        Paint()
          ..color = Colors.black.withValues(alpha: shadowOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = ringColor,
    );

    final innerRadius = radius - borderWidth;
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)),
    );

    final src = Rect.fromLTWH(
      0,
      0,
      photo.width.toDouble(),
      photo.height.toDouble(),
    );
    final dst = Rect.fromCircle(center: center, radius: innerRadius);
    canvas.drawImageRect(photo, src, dst, Paint());
    canvas.restore();
    photo.dispose();

    if (badgeText != null) {
      _drawIndexBadge(canvas, badgeText, size);
    }

    return _applyCircleAlphaMask(
      await recorder.endRecording().toImage(size.ceil(), size.ceil()),
      size,
    );
  }

  static Future<ui.Image> _drawNumberBadge({
    required int index,
    required double size,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 2;

    canvas.drawCircle(
      center + const Offset(0, 1.5),
      radius - 1,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      center,
      radius - 1.5,
      Paint()
        ..color = AppPalette.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final fontSize = size >= 120 ? 34.0 : 28.0;
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$index',
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    return _applyCircleAlphaMask(
      await recorder.endRecording().toImage(size.ceil(), size.ceil()),
      size,
    );
  }

  /// Убирает квадратную подложку: прозрачность только внутри круга.
  static Future<ui.Image> _applyCircleAlphaMask(ui.Image image, double size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    canvas.drawImage(image, Offset.zero, Paint());
    canvas.drawCircle(
      center,
      size / 2,
      Paint()..blendMode = BlendMode.dstIn,
    );
    image.dispose();

    return recorder.endRecording().toImage(size.ceil(), size.ceil());
  }

  static void _drawIndexBadge(Canvas canvas, String text, double size) {
    const badgeSize = 26.0;
    final badgeCenter = Offset(size - badgeSize / 2 - 4, badgeSize / 2 + 4);

    canvas.drawCircle(
      badgeCenter,
      badgeSize / 2,
      Paint()..color = AppPalette.blue,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      badgeCenter - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  static Future<ui.Image> draftSelectionMarker({double size = 56}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 2;

    canvas.drawCircle(
      center + const Offset(0, 2),
      radius - 1,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius - 3,
      Paint()..color = AppPalette.blue,
    );

    return _applyCircleAlphaMask(
      await recorder.endRecording().toImage(size.ceil(), size.ceil()),
      size,
    );
  }

  static double markerScale(
    double markerSize, {
    required bool isEventPhoto,
    bool largeRoute = false,
  }) {
    if (isEventPhoto) {
      return (markerSize / 90).clamp(1.0, 1.35);
    }
    if (largeRoute) {
      return (markerSize / 72).clamp(1.35, 1.75);
    }
    return (markerSize / 110).clamp(0.75, 1.0);
  }

  static math.Point<double> centerAnchor() => const math.Point(0.5, 0.5);
}
