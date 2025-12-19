import 'package:flutter/material.dart';

import 'services/app_session.dart';
import 'services/backend_api.dart';
import 'models/voice_session_models.dart';
import 'models/chat_message.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  final BackendApi _api = BackendApi();
  final TextEditingController _customGoalCtrl = TextEditingController();

  String? _selectedGoalId;
  String? _selectedLabel;
  bool _submitting = false;

  final List<_GoalOption> options = const [
    _GoalOption('emergency_fund', 'Construire un matelas de sécurité'),
    _GoalOption('spending_cut', 'Réduire mes dépenses'),
    _GoalOption('debt_repayment', 'Rembourser une dette'),
    _GoalOption('target_purchase', 'Épargner pour un achat'),
    _GoalOption('monthly_budget', 'Gérer mon budget mensuel'),
    _GoalOption('invest_beginner', 'Commencer à investir'),
    _GoalOption('other_goal', 'Autre...'),
  ];

  @override
  void dispose() {
    _customGoalCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final user = AppSession.instance.currentUser;
    if (user == null) {
      _showSnack('Veuillez vous connecter pour demarrer une session.');
      return;
    }
    final goalId = _selectedGoalId;
    if (goalId == null) {
      _showSnack('Choisissez un objectif pour commencer.');
      return;
    }
    String label = _selectedLabel ?? '';
    if (goalId == 'other_goal') {
      if (_customGoalCtrl.text.trim().isEmpty) {
        _showSnack('Décrivez votre objectif personnalisé.');
        return;
      }
      label = _customGoalCtrl.text.trim();
    }
    if (label.isEmpty) {
      label = options.firstWhere((element) => element.id == goalId).label;
    }
    setState(() => _submitting = true);
    try {
      final VoiceSessionStartResponse response = await _api.startGoalChatSession(
        userId: user.userId,
        goalId: goalId,
        goalLabel: label,
      );
      AppSession.instance.beginGoalChatSession(
        goalId: goalId,
        goalLabel: label,
        session: response,
        initialMessages: [
          ChatMessage(
            role: 'assistant',
            text: response.assistantMessage,
            quickReplies: response.quickReplies,
          ),
        ],
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/voice',
        arguments: VoiceScreenArgs(
          goalId: goalId,
          goalLabel: label,
          sessionId: response.sessionId,
          initialSession: response,
          initialMessages: [
            ChatMessage(
              role: 'assistant',
              text: response.assistantMessage,
              quickReplies: response.quickReplies,
            ),
          ],
          initialFallbackNotice: response.fallbackNotice,
        ),
      );
    } catch (error) {
      _showSnack('Impossible de démarrer la session: $error');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un objectif')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sur quoi voulez-vous travailler ?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final selected = option.id == _selectedGoalId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selected ? const Color(0xFF00A4E1) : Colors.grey.shade200,
                          ),
                        ),
                        leading: Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: selected ? const Color(0xFF00A4E1) : Colors.grey,
                        ),
                        title: Text(option.label),
                        onTap: () {
                          setState(() {
                            _selectedGoalId = option.id;
                            _selectedLabel = option.label;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              if (_selectedGoalId == 'other_goal') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _customGoalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Décrivez votre objectif',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _continue,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continuer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalOption {
  final String id;
  final String label;

  const _GoalOption(this.id, this.label);
}

class VoiceScreenArgs {
  final String goalId;
  final String goalLabel;
  final String sessionId;
  final List<ChatMessage> initialMessages;
  final VoiceSessionStartResponse? initialSession;
  final String? initialFallbackNotice;

  VoiceScreenArgs({
    required this.goalId,
    required this.goalLabel,
    required this.sessionId,
    required this.initialMessages,
    this.initialSession,
    this.initialFallbackNotice,
  });
}
