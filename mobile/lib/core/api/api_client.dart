import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';
import '../config/api_config.dart';
import '../providers/auth_providers.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._ref, {http.Client? client})
      : _client = client ?? http.Client();

  final Ref _ref;
  final http.Client _client;

  AuthSession get _session => _ref.read(authSessionProvider);

  Map<String, String> _headers({bool auth = false, bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (auth) {
      final token = _session.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    bool auth = false,
  }) async {
    return _withAuthRetry(
      auth,
      () async {
        final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
          queryParameters: query?.isNotEmpty == true ? query : null,
        );
        final response = await _client
            .get(uri, headers: _headers(auth: auth))
            .timeout(const Duration(seconds: 12));
        return _decodeObject(response);
      },
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    bool auth = false,
  }) async {
    return _withAuthRetry(
      auth,
      () async {
        final uri = Uri.parse('${ApiConfig.baseUrl}$path');
        final response = await _client
            .post(
              uri,
              headers: _headers(auth: auth),
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));
        return _decodeObject(response);
      },
    );
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Object? body,
    bool auth = false,
  }) async {
    return _withAuthRetry(
      auth,
      () async {
        final uri = Uri.parse('${ApiConfig.baseUrl}$path');
        final response = await _client
            .put(
              uri,
              headers: _headers(auth: auth),
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));
        return _decodeObject(response);
      },
    );
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Object? body,
    bool auth = false,
  }) async {
    return _withAuthRetry(
      auth,
      () async {
        final uri = Uri.parse('${ApiConfig.baseUrl}$path');
        final response = await _client
            .patch(
              uri,
              headers: _headers(auth: auth),
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));
        return _decodeObject(response);
      },
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Object? body,
    bool auth = false,
  }) async {
    return _withAuthRetry(
      auth,
      () async {
        final uri = Uri.parse('${ApiConfig.baseUrl}$path');
        final response = await _client
            .delete(
              uri,
              headers: _headers(auth: auth),
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));
        return _decodeObject(response);
      },
    );
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, String>? query,
    bool auth = false,
  }) async {
    return _withAuthRetry(
      auth,
      () async {
        final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
          queryParameters: query?.isNotEmpty == true ? query : null,
        );
        final response = await _client
            .get(uri, headers: _headers(auth: auth))
            .timeout(const Duration(seconds: 12));

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiException(
            'Request failed (${response.statusCode})',
            statusCode: response.statusCode,
            body: response.body,
          );
        }

        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map<String, dynamic>) {
          final items = decoded['items'];
          if (items is List) return items;
        }
        return const [];
      },
    );
  }

  Future<T> _withAuthRetry<T>(bool auth, Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException catch (error) {
      if (!auth || error.statusCode != 401) rethrow;

      final refreshed = await _ref.read(authSessionProvider.notifier).refreshSession();
      if (!refreshed) rethrow;
      return request();
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _messageFromBody(response.body) ??
            'Request failed (${response.statusCode})',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    if (response.body.isEmpty) return {};

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('Expected JSON object');
  }

  String? _messageFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String) return message;
        if (message is List && message.isNotEmpty) {
          return message.first.toString();
        }
      }
    } catch (_) {}
    return null;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));
