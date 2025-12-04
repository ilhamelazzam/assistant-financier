import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifs = [
      'Dépense élevée détectée hier.',
      'Nouvelle recommandation IA disponible.',
      'Objectif "Épargne" atteint à 80 %.',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifs.length,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            leading:
                const Icon(Icons.notifications, color: Color(0xFF4A90E2)),
            title: Text(notifs[i]),
          ),
        ),
      ),
    );
  }
}
