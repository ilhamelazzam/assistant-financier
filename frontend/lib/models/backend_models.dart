class StartSessionResponse {
  final int sessionId;
  final String sessionStatus;
  final String focusGoal;
  final String userName;
  final String message;

  StartSessionResponse({
    required this.sessionId,
    required this.sessionStatus,
    required this.focusGoal,
    required this.userName,
    required this.message,
  });

  factory StartSessionResponse.fromJson(Map<String, dynamic> json) {
    return StartSessionResponse(
      sessionId: json['sessionId'] as int,
      sessionStatus: json['sessionStatus'] as String,
      focusGoal: json['focusGoal'] as String,
      userName: json['userName'] as String,
      message: json['message'] as String,
    );
  }
}

class InteractionSummary {
  final DateTime timestamp;
  final String userInput;
  final String assistantReply;

  InteractionSummary({
    required this.timestamp,
    required this.userInput,
    required this.assistantReply,
  });

  factory InteractionSummary.fromJson(Map<String, dynamic> json) {
    return InteractionSummary(
      timestamp: DateTime.parse(json['timestamp'] as String),
      userInput: json['userInput'] as String,
      assistantReply: json['assistantReply'] as String,
    );
  }
}

class VoiceResponse {
  final int sessionId;
  final String reply;
  final String sessionStatus;
  final String focusGoal;
  final List<InteractionSummary> recentInteractions;
  final String? fallbackNotice;
  final List<String> quickReplies;

  VoiceResponse({
    required this.sessionId,
    required this.reply,
    required this.sessionStatus,
    required this.focusGoal,
    required this.recentInteractions,
    this.fallbackNotice,
    List<String>? quickReplies,
  }) : quickReplies = List.unmodifiable(quickReplies ?? const []);

  factory VoiceResponse.fromJson(Map<String, dynamic> json) {
    final interactionsJson = json['recentInteractions'] as List<dynamic>?;
    final interactions = interactionsJson == null
        ? <InteractionSummary>[]
        : interactionsJson
            .map((interaction) =>
                InteractionSummary.fromJson(interaction as Map<String, dynamic>))
            .toList();
    return VoiceResponse(
      sessionId: json['sessionId'] as int,
      reply: json['reply'] as String,
      sessionStatus: json['sessionStatus'] as String,
      focusGoal: json['focusGoal'] as String,
      recentInteractions: interactions,
      fallbackNotice: json['fallbackNotice'] as String?,
      quickReplies: (json['quickReplies'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

class PasswordResetRequestResult {
  final bool emailSent;
  final String? code;
  final DateTime? expiresAt;

  const PasswordResetRequestResult({
    required this.emailSent,
    this.code,
    this.expiresAt,
  });

  factory PasswordResetRequestResult.fromJson(Map<String, dynamic> json) {
    final expiresAt = json['expiresAt'] as String?;
    return PasswordResetRequestResult(
      emailSent: json['emailSent'] as bool? ?? true,
      code: json['code'] as String?,
      expiresAt: expiresAt == null ? null : DateTime.tryParse(expiresAt),
    );
  }
}
