import 'package:flutter/material.dart';

class FinancialAnalysisScreen extends StatelessWidget {
  const FinancialAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyse financière IA')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _AnalysisCard(
              title: 'Répartition des dépenses',
              description:
                  'Vos dépenses sont concentrées à 45 % sur le logement et 25 % sur la nourriture.',
            ),
            const SizedBox(height: 12),
            _AnalysisCard(
              title: 'Score de stabilité',
              description:
                  'Votre score financier est de 7,5 / 10. L’IA recommande de diminuer les dépenses variables.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final String description;

  const _AnalysisCard({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 13.5)),
        ],
      ),
    );
  }
}
