import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool biometric = false;
  bool micAuth = true;
  bool notifAuth = true;
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2C3A4B),
        titleSpacing: 0,
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroHeader(),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Sécurité',
                children: [
                  _ItemRow(
                    icon: Icons.lock_outline,
                    color: const Color(0xFF00BFA5),
                    title: 'Changer le mot de passe',
                    subtitle: 'Dernière modification: 12 Nov 2024',
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF9BA7B3)),
                  ),
                  _ItemSwitch(
                    icon: Icons.phonelink_lock,
                    color: const Color(0xFF4A90E2),
                    title: 'Authentification biométrique',
                    subtitle: 'Touch ID / Face ID',
                    value: biometric,
                    onChanged: (v) => setState(() => biometric = v),
                  ),
                  _ItemRow(
                    icon: Icons.security,
                    color: const Color(0xFF00ACC1),
                    title: 'Confidentialité des données',
                    subtitle: 'Gérer vos données personnelles',
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF9BA7B3)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Autorisations',
                children: [
                  _ItemSwitch(
                    icon: Icons.mic_none_rounded,
                    color: const Color(0xFF00A4E1),
                    title: 'Autorisation microphone',
                    subtitle: "Pour l'assistant vocal",
                    value: micAuth,
                    onChanged: (v) => setState(() => micAuth = v),
                  ),
                  _ItemSwitch(
                    icon: Icons.notifications_none,
                    color: const Color(0xFF4DA1F0),
                    title: 'Notifications',
                    subtitle: 'Alertes et rappels',
                    value: notifAuth,
                    onChanged: (v) => setState(() => notifAuth = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Préférences',
                children: [
                  _ItemSwitch(
                    icon: Icons.dark_mode_outlined,
                    color: const Color(0xFF7B92FF),
                    title: 'Mode sombre',
                    subtitle: "Thème de l'application",
                    value: darkMode,
                    onChanged: (v) => setState(() => darkMode = v),
                  ),
                  _ItemRow(
                    icon: Icons.language,
                    color: const Color(0xFF00BFA5),
                    title: 'Langue',
                    subtitle: 'Français',
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF9BA7B3)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Rapports et Données',
                children: const [
                  _ItemRow(
                    icon: Icons.picture_as_pdf_outlined,
                    color: Color(0xFF4DA1F0),
                    title: 'Exporter PDF des rapports',
                    subtitle: 'Télécharger vos analyses financières',
                    trailing: Icon(Icons.cloud_download_outlined, color: Color(0xFF9BA7B3)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: "À propos de l'application",
                children: const [
                  _LinkRow(text: "Conditions d'utilisation"),
                  _LinkRow(text: 'Politique de confidentialité'),
                  _LinkRow(text: 'Centre d\'aide'),
                  _LinkRow(text: 'Version 1.0.0', muted: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

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
            color: Colors.black.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'Paramètres',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Icon(Icons.settings, color: Colors.white),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3A4B),
              ),
            ),
            const SizedBox(height: 12),
            ..._withDividers(children),
          ],
        ),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final list = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      list.add(items[i]);
      if (i != items.length - 1) {
        list.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Color(0xFFE9EEF3)),
        ));
      }
    }
    return list;
  }
}

class _ItemRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _ItemRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBadge(color: color, icon: icon),
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
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF5B6772),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ItemSwitch extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ItemSwitch({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ItemRow(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        activeColor: Colors.white,
        activeTrackColor: color,
        onChanged: onChanged,
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.24),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String text;
  final bool muted;

  const _LinkRow({required this.text, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              color: muted ? const Color(0xFF9BA7B3) : const Color(0xFF2C3A4B),
              fontWeight: muted ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
          if (!muted)
            const Icon(Icons.chevron_right, color: Color(0xFF9BA7B3)),
        ],
      ),
    );
  }
}
