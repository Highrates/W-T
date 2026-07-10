import 'dart:io';

import 'package:flutter/material.dart';

/// Путь к обложке: asset (`assets/...`) или локальный файл на устройстве.
bool coverRefIsAsset(String ref) => ref.startsWith('assets/');

/// Обложка из asset или файла на диске.
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.ref,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String ref;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (coverRefIsAsset(ref)) {
      return Image.asset(
        ref,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    return Image.file(
      File(ref),
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}
