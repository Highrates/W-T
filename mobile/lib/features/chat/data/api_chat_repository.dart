import 'dart:async';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_session.dart';
import '../domain/chat_message.dart';
import 'chat_realtime.dart';
import 'chat_repository.dart';

class ApiChatRepository implements ChatRepository {
  ApiChatRepository(this._api, this._readAuth);

  final ApiClient _api;
  final AuthSession Function() _readAuth;

  ChatRealtime? _realtime;

  void _requireAuth() {
    if (!_readAuth().isAuthenticated) {
      throw StateError('Auth required');
    }
  }

  @override
  Future<List<ChatMessage>> loadMessages(String occurrenceId) async {
    _requireAuth();

    final json = await _api.getJson(
      '/occurrences/$occurrenceId/chat/messages',
      auth: true,
      query: {'limit': '50'},
    );

    final items = json['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage(String occurrenceId, String body) async {
    _requireAuth();

    final json = await _api.postJson(
      '/occurrences/$occurrenceId/chat/messages',
      auth: true,
      body: {'body': body.trim()},
    );

    return ChatMessage.fromJson(json);
  }

  @override
  Stream<ChatMessage> watchMessages(String occurrenceId) {
    _requireAuth();
    final token = _readAuth().accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Auth required');
    }

    _realtime?.dispose();
    final realtime = ChatRealtime(
      accessToken: token,
      occurrenceId: occurrenceId,
    );
    _realtime = realtime;
    unawaited(realtime.connect());
    return realtime.messages;
  }

  Future<void> dispose() async {
    await _realtime?.dispose();
    _realtime = null;
  }
}
