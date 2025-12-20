import 'package:flutter/foundation.dart';

class Favoris extends ChangeNotifier {
  final List<int> _elementsFavoris = [];

  List<int> get elements => List.unmodifiable(_elementsFavoris);

  void ajouter(int numeroElement) {
    if (_elementsFavoris.contains(numeroElement)) return;
    _elementsFavoris.add(numeroElement);
    notifyListeners();
  }

  void supprimer(int numeroElement) {
    _elementsFavoris.remove(numeroElement);
    notifyListeners();
  }
}
