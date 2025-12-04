import 'package:flutter/material.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = [
      'Bilan mensuel - 01/12',
      'Préparation vacances - 20/11',
      'Optimisation abonnement - 05/11',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Historique des conversations')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (_, i) => Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ListTile(
            title: Text(sessions[i]),
            subtitle: const Text('Conseils IA enregistrés'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
