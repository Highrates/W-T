import 'dart:io';

import 'package:flutter/material.dart';

/// Путь к обложке: asset, http(s) URL или локальный файл.
bool coverRefIsAsset(String ref) => ref.startsWith('assets/');

bool coverRefIsNetwork(String ref) =>
    ref.startsWith('http://') || ref.startsWith('https://');

/// Обложка из asset, сети или файла на диске.
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

    if (coverRefIsNetwork(ref)) {
      return Image.network(
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
