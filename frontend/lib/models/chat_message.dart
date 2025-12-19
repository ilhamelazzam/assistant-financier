class ChatMessage {
  final String role; // "user" ou "assistant"
  final String text;
  final DateTime createdAt;
  final List<String> quickReplies;

  ChatMessage({
    required this.role,
    required this.text,
    DateTime? createdAt,
    List<String>? quickReplies,
  })  : createdAt = createdAt ?? DateTime.now(),
        quickReplies = List.unmodifiable(quickReplies ?? const []);
}
