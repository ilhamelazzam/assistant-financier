import 'package:flutter/material.dart';

import 'goal_selection_screen.dart';
import 'models/goal_chat_conversation.dart';
import 'models/goal_chat_history.dart';
import 'services/app_session.dart';
import 'services/backend_api.dart';

class FinancialGoalsScreen extends StatefulWidget {
  const FinancialGoalsScreen({super.key});

  @override
  State<FinancialGoalsScreen> createState() => _FinancialGoalsScreenState();
}

class _FinancialGoalsScreenState extends State<FinancialGoalsScreen> {
  final BackendApi _api = BackendApi();
  final List<_Goal> _goals = [
    _Goal(
      title: 'Economiser pour vacances',
      icon: Icons.flight_takeoff,
      saved: 6500,
      target: 10000,
      months: 3,
    ),
    _Goal(
      title: "Fonds d'urgence",
      icon: Icons.shield_outlined,
      saved: 8200,
      target: 15000,
      months: 6,
    ),
    _Goal(
      title: 'Nouvelle voiture',
      icon: Icons.directions_car_filled,
      saved: 12000,
      target: 50000,
      months: 18,
    ),
  ];
  bool _iaLoading = false;
  String? _iaError;
  List<_GoalReco> _iaRecos = const [];

  Future<void> _showAddGoalDialog() async {
    final draft = await showDialog<_GoalDraft>(
      context: context,
      builder: (_) => const _AddGoalDialog(),
    );
    if (draft == null || !mounted) return;

    setState(() {
      _goals.add(
        _Goal(
          title: draft.title,
          icon: Icons.flag_outlined,
          saved: 0,
          target: draft.amount,
          months: draft.months,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Objectif "${draft.title}" cree.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const headerSaved = 26700.0;
    const headerTarget = 75000.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2C3A4B),
        titleSpacing: 0,
        title: const Text(
          'Objectifs Financiers',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroHeader(
                saved: headerSaved,
                target: headerTarget,
                onAddGoal: _showAddGoalDialog,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mes Objectifs',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3A4B),
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${_goals.length} actifs',
                          style: const TextStyle(
                            color: Color(0xFF7A8794),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: _showAddGoalDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ajouter objectif'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ..._goals.map((g) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: _GoalCard(goal: g),
                  )),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: _IAAdviceCard(
                  loading: _iaLoading,
                  error: _iaError,
                  recos: _iaRecos,
                  onRetry: _loadIaAdvice,
                  onOpen: _openConversation,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadIaAdvice();
  }

  Future<void> _loadIaAdvice() async {
    final user = AppSession.instance.currentUser;
    if (user == null) {
      setState(() {
        _iaRecos = const [];
        _iaError = 'Veuillez vous connecter pour voir les recommandations IA.';
      });
      return;
    }
    setState(() {
      _iaLoading = true;
      _iaError = null;
    });
    try {
      final history = await _api.fetchGoalChatHistory(userId: user.userId, limit: 12);
      final starred = history.where((h) => h.starred).toList();
      final recos = <_GoalReco>[];
      for (final item in starred) {
        if (item.recommendations.isNotEmpty) {
          for (final reco in item.recommendations) {
            if (reco.trim().isEmpty) continue;
            recos.add(_GoalReco(item: item, text: reco));
          }
        } else if (item.assistantReply.trim().isNotEmpty) {
          recos.add(_GoalReco(item: item, text: item.assistantReply));
        }
      }
      setState(() {
        _iaRecos = recos;
        _iaLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _iaError = error.toString();
        _iaLoading = false;
      });
    }
  }

  Future<void> _openConversation(GoalChatHistoryItem item) async {
    final userId = AppSession.instance.currentUser?.userId;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour ouvrir cette session.')),
      );
      return;
    }
    try {
      final conversation =
          await _api.fetchGoalChatConversation(userId: userId, sessionId: item.sessionId);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/voice',
        arguments: VoiceScreenArgs(
          goalId: conversation.goalId,
          goalLabel: conversation.goalLabel,
          sessionId: conversation.sessionId,
          initialMessages: conversation.messages,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger la session : $error')),
      );
    }
  }
}

class _HeroHeader extends StatelessWidget {
  final double saved;
  final double target;
  final VoidCallback onAddGoal;

  const _HeroHeader({
    required this.saved,
    required this.target,
    required this.onAddGoal,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (saved / target).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DA1F0), Color(0xFF00BFA5)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.arrow_back_ios, color: Colors.white70, size: 16),
                  SizedBox(width: 10),
                  Text(
                    'Objectifs Financiers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.white.withOpacity(0.18),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onAddGoal,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Total economise',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      'Objectif total',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${saved.toStringAsFixed(0)} MAD',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${target.toStringAsFixed(0)} MAD',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 8,
                    color: Colors.white.withOpacity(0.25),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percent,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFE0F7FA)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Goal {
  final String title;
  final IconData icon;
  final double saved;
  final double target;
  final int months;

  const _Goal({
    required this.title,
    required this.icon,
    required this.saved,
    required this.target,
    required this.months,
  });

  double get percent => (saved / target).clamp(0.0, 1.0);
  double get remaining => target - saved;
}

class _GoalCard extends StatelessWidget {
  final _Goal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final percent = goal.percent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4DA1F0).withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(goal.icon, color: const Color(0xFF00BFA5), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3A4B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 14, color: Color(0xFF9BA7B3)),
                        const SizedBox(width: 6),
                        Text(
                          '${goal.months} mois',
                          style: const TextStyle(
                            color: Color(0xFF7A8794),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00BFA5), width: 1.4),
                  color: Colors.white,
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF00BFA5), size: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.saved.toStringAsFixed(0)} MAD',
                style: const TextStyle(
                  color: Color(0xFF2C3A4B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${goal.target.toStringAsFixed(0)} MAD',
                style: const TextStyle(
                  color: Color(0xFF2C3A4B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 8,
              color: const Color(0xFFEFF3F7),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF00BFA5), const Color(0xFF4DA1F0).withOpacity(0.7)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(percent * 100).round()}% atteint',
                style: const TextStyle(
                  color: Color(0xFF5B6772),
                  fontSize: 12,
                ),
              ),
              Text(
                'Reste ${goal.remaining.toStringAsFixed(0)} MAD',
                style: const TextStyle(
                  color: Color(0xFF00A4E1),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IAAdviceCard extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<_GoalReco> recos;
  final Future<void> Function() onRetry;
  final void Function(GoalChatHistoryItem) onOpen;

  const _IAAdviceCard({
    required this.loading,
    required this.error,
    required this.recos,
    required this.onRetry,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Color(0xFF00BFA5)),
              SizedBox(width: 8),
              Text(
                'Conseil IA',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3A4B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error!,
                  style: const TextStyle(color: Color(0xFFE53935)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              ],
            )
          else if (recos.isEmpty)
            const Text(
              'Aucune recommandation IA disponible pour vos objectifs. Sauvegardez une session chatbot pour les voir ici.',
              style: TextStyle(color: Color(0xFF5B6772)),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recos
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _RecoRow(
                        text: r.text,
                        subtitle: r.item.goalLabel,
                        onTap: () => onOpen(r.item),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _RecoRow extends StatelessWidget {
  final String text;
  final String subtitle;
  final VoidCallback onTap;

  const _RecoRow({
    required this.text,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5FAFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF00BFA5)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3A4B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF7A8794), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF9BA7B3), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalReco {
  final GoalChatHistoryItem item;
  final String text;

  const _GoalReco({required this.item, required this.text});
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF5B6772), fontSize: 12),
        ),
      ],
    );
  }
}

class _GoalDraft {
  final String title;
  final double amount;
  final int months;

  const _GoalDraft({required this.title, required this.amount, required this.months});
}

class _AddGoalDialog extends StatefulWidget {
  const _AddGoalDialog();

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _monthsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final draft = _GoalDraft(
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      months: int.parse(_monthsCtrl.text.trim()),
    );
    Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un objectif'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: "Nom de l'objectif"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Indique un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant cible (MAD)'),
                validator: (value) {
                  final parsed = double.tryParse(value?.replaceAll(',', '.') ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _monthsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duree (mois)'),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Duree invalide';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Creer'),
        ),
      ],
    );
  }
}
