import 'chat_message.dart';

class GoalChatConversation {
  final String sessionId;
  final String goalId;
  final String goalLabel;
  final List<ChatMessage> messages;

  GoalChatConversation({
    required this.sessionId,
    required this.goalId,
    required this.goalLabel,
    required this.messages,
  });

  factory GoalChatConversation.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? const [];
    final messages = rawMessages
        .map(
          (entry) => ChatMessage(
            role: entry['role'] as String,
            text: entry['text'] as String? ?? '',
            createdAt: DateTime.parse(entry['timestamp'] as String),
          ),
        )
        .toList();
    return GoalChatConversation(
      sessionId: json['sessionId'] as String,
      goalId: json['goalId'] as String,
      goalLabel: json['goalLabel'] as String,
      messages: messages,
    );
  }
}
