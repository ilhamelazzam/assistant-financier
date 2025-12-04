import 'package:flutter/material.dart';

class VoiceAssistantScreen extends StatelessWidget {
  const VoiceAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant vocal IA'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // zone messages
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListView(
                  children: const [
                    _Bubble(
                      fromUser: false,
                      text:
                          'Bonjour, je suis votre coach financier IA. Posez-moi une question !',
                    ),
                    _Bubble(
                      fromUser: true,
                      text:
                          'Comment optimiser mes dépenses ce mois-ci avec un budget de 5000 MAD ?',
                    ),
                    _Bubble(
                      fromUser: false,
                      text:
                          'Vous pouvez limiter les dépenses variables à 30 %, réduire les abonnements inutiles et fixer un objectif d’épargne de 15 %…',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                const Text(
                  'Appuyez pour parler',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF00B8A9)],
                    ),
                  ),
                  child: IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.mic, color: Colors.white),
                    onPressed: () {
                      // TODO: intégration STT/LLM
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool fromUser;
  final String text;

  const _Bubble({required this.fromUser, required this.text});

  @override
  Widget build(BuildContext context) {
    final align =
        fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = fromUser
        ? const Color(0xFF4A90E2)
        : Colors.grey.shade200;
    final textColor = fromUser ? Colors.white : Colors.black87;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                fromUser ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight:
                fromUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: textColor, fontSize: 13.5),
        ),
      ),
    );
  }
}
