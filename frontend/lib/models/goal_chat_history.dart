class GoalChatHistoryItem {
  final int id;
  final String sessionId;
  final String goalId;
  final String goalLabel;
  final String? userInput;
  final String? normalizedUserInput;
  final String assistantReply;
  final DateTime timestamp;
  final bool starred;
  final List<String> recommendations;

  GoalChatHistoryItem({
    required this.id,
    required this.sessionId,
    required this.goalId,
    required this.goalLabel,
    required this.userInput,
    required this.normalizedUserInput,
    required this.assistantReply,
    required this.timestamp,
    required this.starred,
    required this.recommendations,
  });

  factory GoalChatHistoryItem.fromJson(Map<String, dynamic> json) {
    final recosRaw = json['recommendations'] as List<dynamic>?;
    final recos = recosRaw == null
        ? const <String>[]
        : recosRaw.map((entry) => entry.toString()).where((text) => text.trim().isNotEmpty).toList();
    return GoalChatHistoryItem(
      id: (json['id'] as num).toInt(),
      sessionId: json['sessionId'] as String,
      goalId: json['goalId'] as String,
      goalLabel: json['goalLabel'] as String,
      userInput: json['userInput'] as String?,
      normalizedUserInput: json['normalizedUserInput'] as String?,
      assistantReply: json['assistantReply'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      starred: json['starred'] as bool? ?? false,
      recommendations: recos,
    );
  }
}
