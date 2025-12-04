import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool darkMode = false; // à gérer avec un State si tu veux

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          SwitchListTile(
            value: darkMode,
            onChanged: (_) {},
            title: const Text('Mode sombre'),
          ),
          const ListTile(
            leading: Icon(Icons.language),
            title: Text('Langue'),
            subtitle: Text('Français'),
          ),
          const ListTile(
            leading: Icon(Icons.mic),
            title: Text('Autorisation microphone'),
          ),
        ],
      ),
    );
  }
}
