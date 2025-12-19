import '../models/auth_response.dart';
import '../models/backend_models.dart';
import '../models/chat_message.dart';
import '../models/voice_session_models.dart';

/// Simple in-memory store for the authenticated user so the UI can reuse it.
class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  AuthResponse? currentUser;
  StartSessionResponse? activeVoiceSession;

  VoiceSessionStartResponse? activeGoalChatSession;
  String? goalChatGoalId;
  String? goalChatGoalLabel;
  List<ChatMessage> goalChatMessages = [];

  void updateUser(AuthResponse? user) {
    currentUser = user;
  }

  void signOut() {
    currentUser = null;
    activeVoiceSession = null;
    activeGoalChatSession = null;
    goalChatGoalId = null;
    goalChatGoalLabel = null;
    goalChatMessages = [];
  }

  void updateVoiceSession(StartSessionResponse? session) {
    activeVoiceSession = session;
  }

  void beginGoalChatSession({
    required String goalId,
    required String goalLabel,
    required VoiceSessionStartResponse session,
    required List<ChatMessage> initialMessages,
  }) {
    goalChatGoalId = goalId;
    goalChatGoalLabel = goalLabel;
    activeGoalChatSession = session;
    goalChatMessages = List<ChatMessage>.from(initialMessages);
  }

  void appendGoalChatMessage(ChatMessage message) {
    goalChatMessages = List<ChatMessage>.from(goalChatMessages)..add(message);
  }

  void clearGoalChatSession() {
    activeGoalChatSession = null;
    goalChatGoalId = null;
    goalChatGoalLabel = null;
    goalChatMessages = [];
  }

  bool get isAuthenticated => currentUser != null;

  bool get hasGoalChatSession => activeGoalChatSession != null;
}
