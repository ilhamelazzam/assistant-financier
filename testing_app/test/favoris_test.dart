import 'package:flutter_test/flutter_test.dart';
import 'package:testing_app/models/favoris_model.dart';

void main() {
  group('Tests de la classe Favoris', () {
    test('Ajout d’un élément', () {
      final favoris = Favoris();
      favoris.ajouter(1);
      expect(favoris.elements, contains(1));
      expect(favoris.elements.length, 1);
    });

    test('Suppression d’un élément existant', () {
      final favoris = Favoris()..ajouter(2);
      favoris.supprimer(2);
      expect(favoris.elements, isNot(contains(2)));
      expect(favoris.elements.length, 0);
    });

    test('Ajout dupliqué n’ajoute pas deux fois', () {
      final favoris = Favoris();
      favoris
        ..ajouter(3)
        ..ajouter(3);
      expect(favoris.elements.where((e) => e == 3).length, 1);
    });

    test('Suppression d’un élément absent ne jette pas', () {
      final favoris = Favoris();
      expect(() => favoris.supprimer(99), returnsNormally);
      expect(favoris.elements, isEmpty);
    });

    test('Ordre préservé lors des ajouts', () {
      final favoris = Favoris();
      favoris
        ..ajouter(1)
        ..ajouter(5)
        ..ajouter(3);
      expect(favoris.elements, [1, 5, 3]);
    });
  });
}
