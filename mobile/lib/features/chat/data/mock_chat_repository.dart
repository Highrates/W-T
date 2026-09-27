import '../domain/chat_message.dart';
import 'chat_repository.dart';

class MockChatRepository implements ChatRepository {
  const MockChatRepository();

  @override
  Future<List<ChatMessage>> loadMessages(String occurrenceId) async {
    return const [];
  }

  @override
  Future<ChatMessage> sendMessage(String occurrenceId, String body) async {
    throw UnsupportedError('Chat mock: enable API');
  }

  @override
  Stream<ChatMessage> watchMessages(String occurrenceId) {
    return const Stream.empty();
  }
}
