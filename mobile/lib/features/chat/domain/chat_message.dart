class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.occurrenceId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String occurrenceId;
  final String senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final String body;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>? ?? {};
    return ChatMessage(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      occurrenceId: json['occurrenceId'] as String,
      senderId: sender['id'] as String? ?? '',
      senderName: sender['name'] as String?,
      senderAvatarUrl: sender['avatarUrl'] as String?,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
