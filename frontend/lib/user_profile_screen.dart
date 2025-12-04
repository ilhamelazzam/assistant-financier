import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil utilisateur')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 12),
            const Text('Utilisateur Démo',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 24),
            _field('Revenu mensuel', '8000 MAD'),
            _field('Tolérance au risque', 'Faible'),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
