import 'package:flutter_test/flutter_test.dart';

import 'package:coaching_financier/main.dart';

void main() {
  testWidgets('affiche l’écran d’authentification par défaut', (tester) async {
    await tester.pumpWidget(const FinanceCoachApp());
    await tester.pump();

    expect(find.text('Authentification'), findsOneWidget);
    expect(find.textContaining('Mot de passe'), findsWidgets);
  });

  testWidgets('bascule vers le formulaire de création de compte', (tester) async {
    await tester.pumpWidget(const FinanceCoachApp());
    await tester.pump();

    await tester.tap(find.text("S'inscrire"));
    await tester.pump(const Duration(milliseconds: 300));

    // Le champ de confirmation apparaît et le CTA passe à la création de compte.
    expect(find.text('Confirmer le mot de passe'), findsWidgets);
    expect(find.text('Créer mon compte'), findsOneWidget);
  });
}
