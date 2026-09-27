import '../domain/chat_message.dart';

abstract interface class ChatRepository {
  Future<List<ChatMessage>> loadMessages(String occurrenceId);

  Future<ChatMessage> sendMessage(String occurrenceId, String body);

  Stream<ChatMessage> watchMessages(String occurrenceId);
}
