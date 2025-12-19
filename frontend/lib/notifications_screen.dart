import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

enum _NotifCategory { alerts, opportunities, info }
enum _NotifFilter { all, alerts, opportunities, info }

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotifFilter _activeFilter = _NotifFilter.all;
  late List<_Notif> _notifications;
  String? _lastAction;

  @override
  void initState() {
    super.initState();
    _notifications = [
      _Notif(
        title: 'Budget dépassé',
        body: 'Votre budget alimentation a dépassé la limite de 5% cette semaine.',
        time: 'Il y a 2h',
        color: const Color(0xFFE53935),
        icon: Icons.error_outline,
        highlight: true,
        category: _NotifCategory.alerts,
      ),
      _Notif(
        title: 'Dépenses inhabituelles',
        body: 'Vos dépenses en shopping ont augmenté de 45% ce mois-ci.',
        time: 'Il y a 5h',
        color: const Color(0xFFFF8A00),
        icon: Icons.trending_up,
        highlight: true,
        category: _NotifCategory.alerts,
      ),
      _Notif(
        title: 'Objectif atteint',
        body: 'Félicitations ! Vous avez atteint 65% de votre objectif vacances.',
        time: 'Hier',
        color: const Color(0xFF00BFA5),
        icon: Icons.check_circle_outline,
        category: _NotifCategory.info,
        read: true,
      ),
      _Notif(
        title: "Opportunité d'économies",
        body: 'Économisez jusqu\'à 400 MAD en utilisant les transports en commun.',
        time: 'Hier',
        color: const Color(0xFF00A4E1),
        icon: Icons.lightbulb_outline,
        category: _NotifCategory.opportunities,
      ),
      _Notif(
        title: 'Facture à venir',
        body: "Votre facture d'électricité est prévue dans 3 jours (450 MAD).",
        time: 'Il y a 2 jours',
        color: const Color(0xFF8E24AA),
        icon: Icons.receipt_long,
        category: _NotifCategory.info,
      ),
      _Notif(
        title: 'Bon contrôle budgétaire',
        body: 'Excellent ! Vous êtes en dessous de votre budget ce mois-ci.',
        time: 'Il y a 3 jours',
        color: const Color(0xFF00C853),
        icon: Icons.trending_down,
        category: _NotifCategory.info,
      ),
      _Notif(
        title: 'Conseil IA',
        body:
            'Activez les notifications push pour recevoir des alertes en temps réel et ne jamais manquer une opportunité.',
        time: 'Il y a 4 jours',
        color: const Color(0xFFFFC107),
        icon: Icons.tips_and_updates,
        category: _NotifCategory.opportunities,
      ),
    ];
  }

  int get _unreadCount => _notifications.where((n) => !n.read).length;

  List<_Notif> get _filtered {
    switch (_activeFilter) {
      case _NotifFilter.all:
        return _notifications;
      case _NotifFilter.alerts:
        return _notifications.where((n) => n.category == _NotifCategory.alerts).toList();
      case _NotifFilter.opportunities:
        return _notifications.where((n) => n.category == _NotifCategory.opportunities).toList();
      case _NotifFilter.info:
        return _notifications.where((n) => n.category == _NotifCategory.info).toList();
    }
  }

  void _markAllRead() {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(read: true, highlight: false)).toList();
      _lastAction = 'Toutes les notifications marquées comme lues';
    });
  }

  void _markRead(_Notif notif, {String? reason}) {
    setState(() {
      final idx = _notifications.indexOf(notif);
      if (idx >= 0) {
        _notifications[idx] = notif.copyWith(read: true, highlight: false);
        _lastAction = reason;
        if (_lastAction != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_lastAction!)),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2C3A4B),
        titleSpacing: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: _unreadCount == 0 ? null : _markAllRead,
            child: Text(
              'Marquer tout',
              style: TextStyle(
                color: _unreadCount == 0 ? const Color(0xFF9BA7B3) : const Color(0xFF00A4E1),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              _HeroHeader(unread: _unreadCount),
              const SizedBox(height: 14),
              _Tabs(
                active: _activeFilter,
                counts: (
                  all: _notifications.length,
                  alerts: _notifications.where((n) => n.category == _NotifCategory.alerts).length,
                  opportunities: _notifications
                      .where((n) => n.category == _NotifCategory.opportunities)
                      .length,
                  info: _notifications.where((n) => n.category == _NotifCategory.info).length,
                ),
                onChanged: (f) => setState(() => _activeFilter = f),
              ),
              const SizedBox(height: 6),
              if (notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Aucune notification dans cet onglet.',
                    style: TextStyle(color: Color(0xFF5B6772)),
                  ),
                )
              else
                ...notifications.map((n) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: _NotifCard(
                        notif: n,
                        onView: () => _markRead(n, reason: 'Notification ouverte'),
                        onIgnore: () => _markRead(n, reason: 'Notification ignorée'),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final int unread;

  const _HeroHeader({required this.unread});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DA1F0), Color(0xFF00BFA5)],
        ),
        boxShadow: [
          BoxShadow(
        color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.notifications_none, color: Colors.white70),
              SizedBox(width: 10),
              Text(
                'Notifications non lues',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$unread',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final _NotifFilter active;
  final ValueChanged<_NotifFilter> onChanged;
  final ({int all, int alerts, int opportunities, int info}) counts;

  const _Tabs({required this.active, required this.onChanged, required this.counts});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (label: 'Toutes', value: _NotifFilter.all, count: counts.all),
      (label: 'Alertes', value: _NotifFilter.alerts, count: counts.alerts),
      (label: 'Opportunités', value: _NotifFilter.opportunities, count: counts.opportunities),
      (label: 'Infos', value: _NotifFilter.info, count: counts.info),
    ];
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = active == tab.value;
          return GestureDetector(
            onTap: () => onChanged(tab.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF00BFA5) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isActive ? 0.12 : 0.06),
                    blurRadius: isActive ? 14 : 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab.label,
                      style: TextStyle(
                        color: isActive ? Colors.white : const Color(0xFF5B6772),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (tab.count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFEFF3F7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${tab.count}',
                          style: TextStyle(
                            color: isActive ? Colors.white : const Color(0xFF5B6772),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Notif {
  final String title;
  final String body;
  final String time;
  final Color color;
  final IconData icon;
  final bool highlight;
  final bool read;
  final _NotifCategory category;

  const _Notif({
    required this.title,
    required this.body,
    required this.time,
    required this.color,
    required this.icon,
    this.highlight = false,
    this.read = false,
    required this.category,
  });

  _Notif copyWith({bool? read, bool? highlight}) {
    return _Notif(
      title: title,
      body: body,
      time: time,
      color: color,
      icon: icon,
      highlight: highlight ?? this.highlight,
      read: read ?? this.read,
      category: category,
    );
  }
}

class _NotifCard extends StatelessWidget {
  final _Notif notif;
  final VoidCallback onView;
  final VoidCallback onIgnore;

  const _NotifCard({
    required this.notif,
    required this.onView,
    required this.onIgnore,
  });

  @override
  Widget build(BuildContext context) {
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
        border: notif.highlight && !notif.read
            ? Border(left: BorderSide(color: notif.color, width: 3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(color: notif.color, icon: notif.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3A4B),
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: notif.read ? const Color(0xFF9BA7B3) : notif.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.body,
                      style: const TextStyle(
                        color: Color(0xFF5B6772),
                        height: 1.35,
                      ),
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
                notif.time,
                style: const TextStyle(color: Color(0xFF9BA7B3), fontSize: 12),
              ),
              const Spacer(),
              if (!notif.read) ...[
                _ActionPill(label: 'Voir détails', primary: true, onTap: onView),
                const SizedBox(width: 8),
                _ActionPill(label: 'Ignorer', primary: false, onTap: onIgnore),
              ] else
            _ActionPill(label: 'Marquer lu', primary: false, onTap: onView),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _IconBadge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _ActionPill({required this.label, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(colors: [Color(0xFF00BFA5), Color(0xFF4DA1F0)])
                : null,
            color: primary ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: primary ? 0.12 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: primary ? Colors.white : const Color(0xFF2C3A4B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
