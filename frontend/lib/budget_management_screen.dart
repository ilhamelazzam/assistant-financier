import 'package:flutter/material.dart';

class BudgetManagementScreen extends StatelessWidget {
  const BudgetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'category': 'Logement', 'amount': '2000 MAD'},
      {'category': 'Nourriture', 'amount': '1200 MAD'},
      {'category': 'Transport', 'amount': '600 MAD'},
      {'category': 'Loisirs', 'amount': '400 MAD'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion du budget')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: const [
                  Text(
                    'Budget mensuel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('5000 MAD définis • 3800 MAD utilisés'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.category,
                            color: Color(0xFF4A90E2)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item['category']!),
                        ),
                        Text(item['amount']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
