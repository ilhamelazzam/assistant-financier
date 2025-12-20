import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:testing_app/models/favoris_model.dart';
import 'package:testing_app/ui/accueil.dart';
import 'package:testing_app/ui/favoris_screen.dart';

Widget _appUnderTest() {
  return ChangeNotifierProvider(
    create: (_) => Favoris(),
    child: const MaterialApp(
      home: PageAccueil(),
    ),
  );
}

void main() {
  testWidgets('Affichage de la page d’accueil', (tester) async {
    await tester.pumpWidget(_appUnderTest());

    expect(find.text('Liste des Éléments'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
  });

  testWidgets('Interaction avec le bouton Favoris', (tester) async {
    await tester.pumpWidget(_appUnderTest());

    final favorisBorder = find.byIcon(Icons.favorite_border).first;
    await tester.tap(favorisBorder);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite), findsWidgets);
  });

  testWidgets('Navigation vers la page Favoris', (tester) async {
    await tester.pumpWidget(_appUnderTest());

    final navButton = find.byIcon(Icons.favorite);
    await tester.tap(navButton);
    await tester.pumpAndSettle();

    expect(find.byType(PageFavoris), findsOneWidget);
    expect(find.text('Mes Favoris'), findsOneWidget);
  });

  testWidgets('Vérification du défilement dans PageAccueil', (tester) async {
    await tester.pumpWidget(_appUnderTest());

    // Scroll jusqu’à l’élément 49.
    await tester.fling(find.byType(ListView), const Offset(0, -1000), 3000);
    await tester.pumpAndSettle();

    expect(find.text('Élément 49'), findsOneWidget);
  });
}
