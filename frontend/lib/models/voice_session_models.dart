class VoiceSessionStartResponse {
  final String sessionId;
  final String assistantMessage;
  final String? fallbackNotice;
  final List<String> quickReplies;

  VoiceSessionStartResponse({
    required this.sessionId,
    required this.assistantMessage,
    this.fallbackNotice,
    List<String>? quickReplies,
  }) : quickReplies = List.unmodifiable(quickReplies ?? const []);

  factory VoiceSessionStartResponse.fromJson(Map<String, dynamic> json) {
    final repliesJson = json['quickReplies'] as List<dynamic>?;
    return VoiceSessionStartResponse(
      sessionId: json['sessionId'] as String,
      assistantMessage: json['assistantMessage'] as String,
      fallbackNotice: json['fallbackNotice'] as String?,
      quickReplies: repliesJson == null ? const [] : repliesJson.cast<String>(),
    );
  }
}

class VoiceMessageResponse {
  final String assistantMessage;
  final String? fallbackNotice;
  final List<String> quickReplies;

  VoiceMessageResponse({
    required this.assistantMessage,
    this.fallbackNotice,
    List<String>? quickReplies,
  }) : quickReplies = List.unmodifiable(quickReplies ?? const []);

  factory VoiceMessageResponse.fromJson(Map<String, dynamic> json) {
    final repliesJson = json['quickReplies'] as List<dynamic>?;
    return VoiceMessageResponse(
      assistantMessage: json['assistantMessage'] as String,
      fallbackNotice: json['fallbackNotice'] as String?,
      quickReplies: repliesJson == null ? const [] : repliesJson.cast<String>(),
    );
  }
}
