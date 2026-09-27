import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';
import '../../../ui/media/cover_image.dart';
import '../domain/create_route_draft.dart';

enum UploadMediaPurpose { cover, point, avatar }

/// Presign + PUT локальных файлов в S3 (MinIO).
class MediaUploadService {
  MediaUploadService(this._ref, {http.Client? client})
      : _client = client ?? http.Client();

  final Ref _ref;
  final http.Client _client;

  Future<String> uploadLocalFile(
    String localPath,
    UploadMediaPurpose purpose,
  ) async {
    if (coverRefIsNetwork(localPath)) return localPath;

    final file = File(localPath);
    if (!await file.exists()) {
      throw StateError('File not found: $localPath');
    }

    final contentType = _contentTypeForPath(localPath);
    final json = await _ref.read(apiClientProvider).postJson(
          '/media/presign',
          auth: true,
          body: {
            'contentType': contentType,
            'purpose': purpose.name,
          },
        );

    final uploadUrl = json['uploadUrl'] as String?;
    final readUrl = json['readUrl'] as String?;
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw StateError('Presign response missing uploadUrl');
    }

    final bytes = await file.readAsBytes();
    final response = await _client
        .put(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': contentType},
          body: bytes,
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Upload failed (${response.statusCode})');
    }

    return readUrl ?? uploadUrl.split('?').first;
  }

  Future<List<String>> uploadLocalFiles(
    List<String> paths,
    UploadMediaPurpose purpose,
  ) async {
    if (!ApiConfig.useApi) return paths;

    final result = <String>[];
    for (final path in paths) {
      if (coverRefIsNetwork(path) || path.startsWith('assets/')) {
        result.add(path);
        continue;
      }
      result.add(await uploadLocalFile(path, purpose));
    }
    return result;
  }

  Future<CreateRouteDraft> prepareDraftForPublish(CreateRouteDraft draft) async {
    if (!ApiConfig.useApi) return draft;

    final coverAssets = await uploadLocalFiles(
      draft.coverAssets,
      UploadMediaPurpose.cover,
    );

    final points = <CreateRoutePointDraft>[];
    for (final point in draft.points) {
      final photoAssets = await uploadLocalFiles(
        point.photoAssets,
        UploadMediaPurpose.point,
      );
      points.add(point.copyWith(photoAssets: photoAssets));
    }

    return draft.copyWith(coverAssets: coverAssets, points: points);
  }

  String _contentTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

final mediaUploadServiceProvider = Provider<MediaUploadService>(
  (ref) => MediaUploadService(ref),
);
