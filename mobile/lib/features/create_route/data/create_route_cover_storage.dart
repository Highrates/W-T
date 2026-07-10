import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

/// Копирует выбранные фото в documents, чтобы черновик пережил перезапуск.
abstract final class CreateRouteCoverStorage {
  static Future<String> persistPickedFile(String sourcePath) async {
    final source = File(sourcePath);
    final dir = await getApplicationDocumentsDirectory();
    final coversDir = Directory('${dir.path}/create_route_covers');
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }

    final ext = _extension(sourcePath);
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}$ext';
    final dest = File('${coversDir.path}/$name');
    await source.copy(dest.path);
    return dest.path;
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= 0 || dot >= path.length - 1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.heic') {
      return ext == '.jpeg' ? '.jpg' : ext;
    }
    return '.jpg';
  }
}
