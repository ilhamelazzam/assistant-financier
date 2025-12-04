import 'package:flutter/material.dart';

class AIReportsScreen extends StatelessWidget {
  const AIReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      'Rapport hebdomadaire',
      'Rapport mensuel',
      'Analyse spéciale vacances',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Rapports IA')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (_, i) => Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ListTile(
            title: Text(reports[i]),
            subtitle: const Text('Résumé généré par l’IA'),
            trailing: const Icon(Icons.picture_as_pdf),
          ),
        ),
      ),
    );
  }
}
