import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'goal_selection_screen.dart';
import 'models/chat_message.dart';
import 'services/app_session.dart';
import 'services/backend_api.dart';
import 'services/backend_factory.dart';
import 'models/voice_session_models.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final BackendApi _api = BackendFactory.create();
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _inputCtrl = TextEditingController();

  String? _sessionId;
  String? _goalLabel;
  bool _loading = false;
  bool _listening = false;
  bool _savingHistory = false;
  bool _initializedFromRouteArgs = false; // prevent re-initializing when dependencies rebuild

  final List<ChatMessage> _messages = [];
  List<String> _quickReplies = const [];

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('fr-FR');
    _tts.setSpeechRate(0.45);
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromRouteArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is VoiceScreenArgs) {
      _initializeFromArgs(args);
    } else if (AppSession.instance.hasGoalChatSession) {
      _initializeFromStore();
    }
    _initializedFromRouteArgs = true;
  }

  void _initializeFromArgs(VoiceScreenArgs args) {
    final fallbackSession = VoiceSessionStartResponse(
      sessionId: args.sessionId,
      assistantMessage: _lastAssistantMessage(args.initialMessages),
      fallbackNotice: args.initialFallbackNotice,
    );
    final session = args.initialSession ?? fallbackSession;
    setState(() {
      _sessionId = args.sessionId;
      _goalLabel = args.goalLabel;
      _messages
        ..clear()
        ..addAll(args.initialMessages);
      _quickReplies = _latestAssistantQuickReplies();
    });
    AppSession.instance.beginGoalChatSession(
      goalId: args.goalId,
      goalLabel: args.goalLabel,
      session: session,
      initialMessages: args.initialMessages,
    );
    _maybeShowFallbackNotice(args.initialFallbackNotice);
  }

  void _initializeFromStore() {
    final store = AppSession.instance;
    final storedSession = store.activeGoalChatSession;
    if (storedSession == null) {
      return;
    }
    setState(() {
      _sessionId = storedSession.sessionId;
      _goalLabel = store.goalChatGoalLabel;
      _messages
        ..clear()
        ..addAll(store.goalChatMessages);
      _quickReplies = _latestAssistantQuickReplies();
    });
    _maybeShowFallbackNotice(storedSession.fallbackNotice);
  }

  Future<void> _sendTextMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sessionId == null) return;
    final userId = _requireUserId();
    if (userId == null) return;
    setState(() {
      final userMessage = ChatMessage(role: 'user', text: text);
      _messages.add(userMessage);
      _inputCtrl.clear();
      _loading = true;
      _quickReplies = const [];
      AppSession.instance.appendGoalChatMessage(userMessage);
    });
    try {
      final VoiceMessageResponse response = await _api.sendGoalChatMessage(
        userId: userId,
        sessionId: _sessionId!,
        message: text,
      );
      if (!mounted) return;
      final message = ChatMessage(
        role: 'assistant',
        text: response.assistantMessage,
        quickReplies: response.quickReplies,
      );
      setState(() {
        _messages.add(message);
        _loading = false;
        _quickReplies = message.quickReplies;
      });
      AppSession.instance.appendGoalChatMessage(message);
      await _tts.speak(message.text);
      _maybeShowFallbackNotice(response.fallbackNotice);
    } catch (error) {
      _showSnack('Erreur IA: $error');
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _stt.stop();
      if (!mounted) return;
      setState(() => _listening = false);
      await _sendTextMessage();
      return;
    }
    final available = await _stt.initialize();
    if (!available) {
      _showSnack('Micro non disponible.');
      return;
    }
    if (!mounted) return;
    setState(() => _listening = true);
    await _stt.listen(
      localeId: 'fr_FR',
      onResult: (result) {
        _inputCtrl.text = result.recognizedWords;
        _inputCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _inputCtrl.text.length),
        );
      },
    );
  }

  void _changeGoal() {
    AppSession.instance.clearGoalChatSession();
    Navigator.pushReplacementNamed(context, '/voice-start');
  }

  Future<void> _saveConversation() async {
    if (_sessionId == null || _savingHistory) return;
    final userId = _requireUserId();
    if (userId == null) return;
    setState(() => _savingHistory = true);
    try {
      await _api.saveGoalChatSession(userId: userId, sessionId: _sessionId!);
      if (!mounted) return;
      _showSnack('Conversation enregistree dans l\'historique.');
    } catch (error) {
      _showSnack('Enregistrement impossible: $error');
    } finally {
      if (mounted) {
        setState(() => _savingHistory = false);
      }
    }
  }

  void _handleQuickReplyTap(String value) {
    if (_loading || value.isEmpty) {
      return;
    }
    _inputCtrl.text = value;
    _inputCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputCtrl.text.length),
    );
    _sendTextMessage();
  }

  List<String> _latestAssistantQuickReplies() {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final message = _messages[i];
      if (message.role == 'assistant' && message.quickReplies.isNotEmpty) {
        return message.quickReplies;
      }
    }
    return const [];
  }

  String _lastAssistantMessage(List<ChatMessage> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == 'assistant') {
        return messages[i].text;
      }
    }
    return messages.isNotEmpty ? messages.last.text : '';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  int? _requireUserId() {
    final user = AppSession.instance.currentUser;
    if (user == null) {
      _showSnack('Veuillez vous connecter.');
      return null;
    }
    return user.userId;
  }

  void _maybeShowFallbackNotice(String? notice) {
    final trimmed = notice?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    debugPrint('Fallback notice: $trimmed');
  }

  @override
  Widget build(BuildContext context) {
    final goal = _goalLabel ?? 'objectif';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _changeGoal,
        ),
        title: const Text('Assistant vocal IA'),
        actions: [
          IconButton(
            tooltip: 'Enregistrer cette session',
            onPressed: (_sessionId == null || _savingHistory) ? null : _saveConversation,
            icon: _savingHistory
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bookmark_add_outlined),
          ),
          TextButton(
            onPressed: _changeGoal,
            child: const Text('Changer d’objectif'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(goal: goal),
            Expanded(
              child: Container(
                color: const Color(0xFFF4F6FB),
                child: _messages.isEmpty
                    ? _Placeholder(goal: goal)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _ChatBubble(message: message);
                        },
                      ),
              ),
            ),
            _InputArea(
              controller: _inputCtrl,
              onSend: _loading ? null : _sendTextMessage,
              listening: _listening,
              loading: _loading,
              onMicTap: _loading ? null : _toggleListening,
              quickReplies: _quickReplies,
              onQuickReplyTap: _loading ? null : _handleQuickReplyTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String goal;

  const _ChatHeader({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF21C7A8), Color(0xFF00A4E1)]),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assistant Vocal IA', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            goal,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text('Session active · Pose une question à la fois', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String goal;

  const _Placeholder({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 48, color: Color(0xFF00A4E1)),
          const SizedBox(height: 12),
          Text('Parlons de $goal', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Réponds à la première question pour avancer.', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final gradient = isUser
        ? const LinearGradient(colors: [Color(0xFF21C7A8), Color(0xFF00A4E1)])
        : null;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          gradient: gradient,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15),
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final bool listening;
  final bool loading;
  final VoidCallback? onMicTap;
  final List<String> quickReplies;
  final ValueChanged<String>? onQuickReplyTap;

  const _InputArea({
    required this.controller,
    required this.onSend,
    required this.listening,
    required this.loading,
    required this.onMicTap,
    required this.quickReplies,
    this.onQuickReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (quickReplies.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: quickReplies
                    .map(
                      (label) => ActionChip(
                        label: Text(label),
                        onPressed: (loading || onQuickReplyTap == null) ? null : () => onQuickReplyTap!(label),
                        backgroundColor: const Color(0xFFF0F4FA),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tapez votre message...',
                    filled: true,
                    fillColor: const Color(0xFFF4F6FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onMicTap,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: listening
                      ? const [Color(0xFF00A4E1), Color(0xFF21C7A8)]
                      : const [Color(0xFF21C7A8), Color(0xFF00A4E1)],
                ),
              ),
              child: Icon(
                listening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            listening ? 'Écoute en cours...' : (loading ? 'Réponse en préparation...' : 'Appuyez pour parler'),
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
