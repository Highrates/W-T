import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/api_config.dart';
import '../domain/chat_message.dart';

class ChatRealtime {
  ChatRealtime({
    required this.accessToken,
    required this.occurrenceId,
  });

  final String accessToken;
  final String occurrenceId;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _controller = StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messages => _controller.stream;

  Future<void> connect() async {
    await disconnect();

    final uri = Uri.parse(
      '${ApiConfig.wsBaseUrl}/chat?token=${Uri.encodeComponent(accessToken)}',
    );
    _channel = WebSocketChannel.connect(uri);
    _subscription = _channel!.stream.listen(
      _onData,
      onError: _controller.addError,
    );

    _channel!.sink.add(
      jsonEncode({
        'type': 'join',
        'occurrenceId': occurrenceId,
      }),
    );
  }

  Future<void> send(String body) async {
    final channel = _channel;
    if (channel == null) return;

    channel.sink.add(
      jsonEncode({
        'type': 'message',
        'body': body,
      }),
    );
  }

  void _onData(dynamic raw) {
    final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
    final type = decoded['type'] as String?;
    if (type == 'message') {
      final messageJson = decoded['message'] as Map<String, dynamic>?;
      if (messageJson != null) {
        _controller.add(ChatMessage.fromJson(messageJson));
      }
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }
}
