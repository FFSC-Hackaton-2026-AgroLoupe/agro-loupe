import 'package:flutter/foundation.dart';

/// Permet de relancer le tutoriel depuis n'importe quel écran.
///
/// Le tutoriel est affiché une seule fois, au premier lancement. Le bouton
/// « Revoir le tutoriel » vit dans la barre de titre de l'accueil, alors que
/// le voile est posé par la coquille : les deux ne se voient pas. Ce petit
/// contrôleur fait le lien sans les coupler.
///
/// C'est un compteur et non un booléen, pour qu'une deuxième demande
/// fonctionne aussi bien que la première.
class CoachController extends ChangeNotifier {
  int _demandes = 0;

  /// Nombre de relances demandées depuis le démarrage.
  int get demandes => _demandes;

  void replay() {
    _demandes++;
    notifyListeners();
  }
}
