import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testing_app/models/favoris_model.dart';
import 'package:testing_app/ui/favoris_screen.dart';

class PageAccueil extends StatelessWidget {
  const PageAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Éléments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PageFavoris()),
              );
            },
          ),
        ],
      ),
      body: const ListeElements(),
    );
  }
}

class ListeElements extends StatelessWidget {
  const ListeElements({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 50,
      itemBuilder: (context, index) {
        return ElementListe(index);
      },
    );
  }
}

class ElementListe extends StatelessWidget {
  final int numeroElement;
  const ElementListe(this.numeroElement, {super.key});

  @override
  Widget build(BuildContext context) {
    final favoris = context.watch<Favoris>();
    final estFavori = favoris.elements.contains(numeroElement);
    return ListTile(
      title: Text('Élément $numeroElement'),
      trailing: IconButton(
        icon: Icon(
          estFavori ? Icons.favorite : Icons.favorite_border,
          color: estFavori ? Colors.red : null,
        ),
        onPressed: () {
          if (estFavori) {
            favoris.supprimer(numeroElement);
          } else {
            favoris.ajouter(numeroElement);
          }
        },
      ),
    );
  }
}
