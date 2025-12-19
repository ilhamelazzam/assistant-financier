import 'package:flutter/material.dart';

import 'goal_selection_screen.dart';
import 'models/goal_chat_conversation.dart';
import 'models/goal_chat_history.dart';
import 'services/app_session.dart';
import 'services/backend_api.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final BackendApi _api = BackendApi();
  late Future<List<GoalChatHistoryItem>> _historyFuture;
  _HistoryFilter _activeFilter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<GoalChatHistoryItem>> _loadHistory() {
    final userId = AppSession.instance.currentUser?.userId;
    if (userId == null) {
      return Future.error('Veuillez vous connecter.');
    }
    return _api.fetchGoalChatHistory(userId: userId, limit: 40);
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _loadHistory();
    });
    await _historyFuture;
  }

  Future<void> _openConversation(GoalChatHistoryItem item) async {
    final userId = _requireUserId();
    if (userId == null) return;
    try {
      final GoalChatConversation conversation =
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
        SnackBar(content: Text('Impossible de reprendre la discussion: $error')),
      );
    }
  }

  Future<void> _toggleStar(GoalChatHistoryItem item) async {
    final userId = _requireUserId();
    if (userId == null) return;
    try {
      await _api.saveGoalChatSession(
        userId: userId,
        sessionId: item.sessionId,
        starred: !item.starred,
      );
      if (!mounted) return;
      _showSnack(item.starred ? 'Discussion retiree des favoris' : 'Discussion ajoutee aux favoris');
      await _refresh();
    } catch (error) {
      _showSnack('Impossible de mettre a jour les favoris: $error');
    }
  }

  Future<void> _renameSession(GoalChatHistoryItem item) async {
    final newLabel = await _promptRename(item.goalLabel);
    if (newLabel == null || newLabel.trim().isEmpty || newLabel == item.goalLabel) {
      return;
    }
    final userId = _requireUserId();
    if (userId == null) return;
    try {
      await _api.renameGoalChatSession(
        userId: userId,
        sessionId: item.sessionId,
        newLabel: newLabel.trim(),
      );
      if (!mounted) return;
      _showSnack('Discussion renommee');
      await _refresh();
    } catch (error) {
      _showSnack('Renommage impossible: $error');
    }
  }

  Future<void> _deleteSession(GoalChatHistoryItem item) async {
    final confirmed = await _confirmDelete(item.goalLabel);
    if (confirmed != true) return;
    final userId = _requireUserId();
    if (userId == null) return;
    try {
      await _api.deleteGoalChatSession(userId: userId, sessionId: item.sessionId);
      if (!mounted) return;
      _showSnack('Discussion supprimee');
      await _refresh();
    } catch (error) {
      _showSnack('Suppression impossible: $error');
    }
  }

  Future<String?> _promptRename(String currentLabel) async {
    final controller = TextEditingController(text: currentLabel);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renommer la discussion'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nouveau titre',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmDelete(String label) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la discussion ?'),
        content: Text('La conversation "$label" sera supprimee definitivement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
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

  List<GoalChatHistoryItem> _applyFilter(List<GoalChatHistoryItem> history) {
    switch (_activeFilter) {
      case _HistoryFilter.all:
        return history;
      case _HistoryFilter.starred:
        return history.where((item) => item.starred).toList();
      case _HistoryFilter.recent:
        final now = DateTime.now();
        final recent = history.where(
          (item) => now.difference(item.timestamp).inDays <= 3,
        );
        final list = recent.toList();
        return list.isEmpty ? history.take(5).toList() : list;
      case _HistoryFilter.budget:
        return history
            .where(
              (item) =>
                  item.goalId.toLowerCase().contains('budget') ||
                  item.goalId.toLowerCase().contains('spending'),
            )
            .toList();
      case _HistoryFilter.objectives:
        return history
            .where(
              (item) =>
                  item.goalId.toLowerCase().contains('goal') ||
                  item.goalLabel.toLowerCase().contains('objectif'),
            )
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: FutureBuilder<List<GoalChatHistoryItem>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _HistoryError(
                error: snapshot.error,
                onRetry: _refresh,
              );
            }
            final history = snapshot.data ?? const <GoalChatHistoryItem>[];
            final filteredHistory = _applyFilter(history);
            final starredRecommendations = history
                .where(
                  (item) =>
                      item.starred &&
                      ((item.recommendations.isNotEmpty)
                          ? true
                          : item.assistantReply.trim().isNotEmpty),
                )
                .toList();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeroHeader(),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: const _SearchBar(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _FilterTabs(
                        active: _activeFilter,
                        onChanged: (filter) => setState(() => _activeFilter = filter),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (starredRecommendations.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _RecommendationsSection(
                          items: starredRecommendations,
                          onOpen: (item) => _openConversation(item),
                        ),
                      ),
                    if (starredRecommendations.isNotEmpty) const SizedBox(height: 12),
                    if (history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 40),
                        child: _EmptyHistoryState(),
                      )
                    else if (filteredHistory.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 40),
                        child: _NoResultsState(),
                      )
                    else
                  ...filteredHistory.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          child: _ChatCard(
                            item: item,
                            onListen: () => _openConversation(item),
                            onContinue: () => _openConversation(item),
                            onToggleStar: () => _toggleStar(item),
                            onRename: () => _renameSession(item),
                            onDelete: () => _deleteSession(item),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _HistoryFilter { all, starred, recent, budget, objectives }

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DA1F0), Color(0xFF00BFA5)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 24,
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
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).maybePop(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: const [
                      Icon(Icons.arrow_back_ios, color: Colors.white70, size: 16),
                      SizedBox(width: 10),
                      Text(
                        'Historique IA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Rechercher dans l'historique...",
              style: TextStyle(color: Color(0xFF9BA7B3)),
            ),
          ),
          Icon(Icons.filter_list, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.active, required this.onChanged});

  final _HistoryFilter active;
  final ValueChanged<_HistoryFilter> onChanged;

  static const _filterOrder = [
    _HistoryFilter.all,
    _HistoryFilter.starred,
    _HistoryFilter.recent,
    _HistoryFilter.budget,
    _HistoryFilter.objectives,
  ];

  String _labelFor(_HistoryFilter filter) {
    switch (filter) {
      case _HistoryFilter.all:
        return 'Tout';
      case _HistoryFilter.starred:
        return 'Sauvegardes';
      case _HistoryFilter.recent:
        return 'Recents';
      case _HistoryFilter.budget:
        return 'Budget';
      case _HistoryFilter.objectives:
        return 'Objectifs';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOrder.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final filter = _filterOrder[index];
          final isActive = filter == active;
          return GestureDetector(
            onTap: () => onChanged(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF00BFA5) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isActive ? 0.10 : 0.05),
                    blurRadius: isActive ? 14 : 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _labelFor(filter),
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF5B6772),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final GoalChatHistoryItem item;
  final VoidCallback? onListen;
  final VoidCallback? onContinue;
  final VoidCallback? onToggleStar;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const _ChatCard({
    required this.item,
    this.onListen,
    this.onContinue,
    this.onToggleStar,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle();
    final dateLabel = _formatDate(item.timestamp);
    final timeLabel = _formatTime(item.timestamp);
    return Container(
      padding: const EdgeInsets.all(14),
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
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4DA1F0), Color(0xFF00BFA5)],
                  ),
                ),
                child: const Icon(Icons.mic_none_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.goalLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3A4B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.starred)
                          const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                        const SizedBox(width: 6),
                        PopupMenuButton<_CardMenuAction>(
                          icon: const Icon(Icons.more_horiz, color: Color(0xFF9BA7B3)),
                          onSelected: (action) {
                            switch (action) {
                              case _CardMenuAction.toggleStar:
                                onToggleStar?.call();
                                break;
                              case _CardMenuAction.rename:
                                onRename?.call();
                                break;
                              case _CardMenuAction.delete:
                                onDelete?.call();
                                break;
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: _CardMenuAction.toggleStar,
                              child: Text(item.starred ? 'Retirer des favoris' : 'Ajouter aux favoris'),
                            ),
                            const PopupMenuItem(
                              value: _CardMenuAction.rename,
                              child: Text('Renommer'),
                            ),
                            const PopupMenuItem(
                              value: _CardMenuAction.delete,
                              child: Text('Supprimer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF5B6772),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                dateLabel,
                style: const TextStyle(color: Color(0xFF9BA7B3), fontSize: 12),
              ),
              const SizedBox(width: 10),
              Text(
                timeLabel,
                style: const TextStyle(color: Color(0xFF9BA7B3), fontSize: 12),
              ),
              const Spacer(),
              _PillButton(
                label: 'Ecouter',
                icon: Icons.play_arrow_rounded,
                onTap: onListen,
              ),
              const SizedBox(width: 8),
              _PillButton(
                label: 'Continuer',
                icon: Icons.arrow_forward_ios,
                dense: true,
                onTap: onContinue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    final normalized = item.normalizedUserInput?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    final candidate = item.userInput?.trim();
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
    return item.assistantReply;
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool dense;
  final VoidCallback? onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    this.dense = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 12 : 14, vertical: dense ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4DA1F0)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2C3A4B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Aucun resultat pour ce filtre',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3A4B),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Essayez un autre onglet ou lancez une nouvelle session.',
          style: TextStyle(
            color: Color(0xFF5B6772),
          ),
        ),
      ],
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  final List<GoalChatHistoryItem> items;
  final void Function(GoalChatHistoryItem) onOpen;

  const _RecommendationsSection({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final recos = <(GoalChatHistoryItem item, String title, String category)>[];
    for (final item in items) {
      if (item.recommendations.isNotEmpty) {
        for (final reco in item.recommendations) {
          if (reco.trim().isEmpty) continue;
          recos.add((item, reco, item.goalLabel));
        }
      } else if (item.assistantReply.trim().isNotEmpty) {
        recos.add((item, item.assistantReply, item.goalLabel));
      }
    }
    if (recos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommandations sauvegardees',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3A4B),
          ),
        ),
        const SizedBox(height: 10),
        ...recos.map(
          (r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _RecoCard(
              title: r.$2,
              category: r.$3,
              onTap: () => onOpen(r.$1),
            ),
          ),
        ),
      ],
    );
  }
}

enum _CardMenuAction { toggleStar, rename, delete }

class _RecoCard extends StatelessWidget {
  final String title;
  final String category;
  final VoidCallback? onTap;

  const _RecoCard({required this.title, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF4DA1F0), Color(0xFF00BFA5)],
              ),
            ),
            child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3A4B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF7A8794),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Color(0xFF9BA7B3), size: 16),
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Aucun echange enregistre',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3A4B),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Commencez une session vocale pour voir vos conversations ici.',
          style: TextStyle(
            color: Color(0xFF5B6772),
          ),
        ),
      ],
    );
  }
}

class _HistoryError extends StatelessWidget {
  final Object? error;
  final Future<void> Function()? onRetry;

  const _HistoryError({this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 40, color: Color(0xFFEE6C4D)),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger l\'historique.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              error?.toString() ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry == null ? null : () => onRetry!(),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  const monthLabels = [
    'janv',
    'fev',
    'mars',
    'avr',
    'mai',
    'juin',
    'juil',
    'aout',
    'sept',
    'oct',
    'nov',
    'dec',
  ];
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = monthLabels[dateTime.month - 1];
  final year = dateTime.year;
  return '$day $month $year';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
