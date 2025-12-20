import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testing_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Lancement affiche la page d’accueil', (tester) async {
    await tester.pumpWidget(const ApplicationTest());
    await tester.pumpAndSettle();

    expect(find.text('Liste des Éléments'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
  });

  testWidgets('Ajout d’un favori puis navigation vers la page Favoris', (tester) async {
    await tester.pumpWidget(const ApplicationTest());
    await tester.pumpAndSettle();

    // Ajoute le premier élément aux favoris.
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();

    // Ouvre la page Favoris via le bouton AppBar.
    final navButton = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.favorite),
    );
    await tester.tap(navButton);
    await tester.pumpAndSettle();

    expect(find.text('Mes Favoris'), findsOneWidget);
    expect(find.text('Élément 0'), findsOneWidget);
  });
}
