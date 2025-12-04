import 'package:flutter/material.dart';

class FinancialGoalsScreen extends StatelessWidget {
  const FinancialGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = [
      {'label': 'Économiser 10 000 MAD', 'progress': 0.4},
      {'label': 'Payer une dette', 'progress': 0.7},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Objectifs financiers')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: goals
              .map(
                (g) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g['label'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: g['progress'] as double,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF00B8A9),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
