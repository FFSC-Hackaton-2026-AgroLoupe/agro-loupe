import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/second_opinion_service.dart';
import '../models/second_opinion.dart';

sealed class SecondOpinionState {
  const SecondOpinionState();
}

/// Rien n'a encore été demandé : le bouton est proposé.
class SecondOpinionIdle extends SecondOpinionState {
  const SecondOpinionIdle();
}

class SecondOpinionAsking extends SecondOpinionState {
  const SecondOpinionAsking();
}

class SecondOpinionReady extends SecondOpinionState {
  const SecondOpinionReady(this.opinion);

  final SecondOpinion opinion;
}

class SecondOpinionError extends SecondOpinionState {
  const SecondOpinionError(this.message);

  final String message;
}

/// Pilote le deuxième avis en ligne.
///
/// Il n'est **jamais** déclenché automatiquement : l'utilisateur appuie sur un
/// bouton. Le modèle embarqué répond toujours, en 200 ms et hors connexion ;
/// basculer en ligne dans son dos donnerait deux réponses différentes au même
/// symptôme selon l'état du réseau, sans qu'il puisse comprendre pourquoi.
class SecondOpinionProvider extends ChangeNotifier {
  SecondOpinionProvider(this._service);

  /// `null` quand aucun accès en ligne n'est configuré. L'interface masque
  /// alors le bouton plutôt que de proposer une action vouée à échouer.
  final SecondOpinionService? _service;

  bool get isAvailable => _service != null;

  SecondOpinionState _state = const SecondOpinionIdle();

  /// Photo à laquelle se rapporte [_state].
  String? _imagePath;

  /// État du deuxième avis **pour cette photo**.
  ///
  /// Un nouveau diagnostic repart donc de zéro sans qu'il faille penser à
  /// remettre l'état à plat : un avis rendu sur la photo précédente ne peut
  /// pas rester affiché sous la suivante.
  SecondOpinionState stateFor(String imagePath) =>
      _imagePath == imagePath ? _state : const SecondOpinionIdle();

  Future<void> ask({
    required String imagePath,
    required String cropName,
    required List<CatalogEntry> catalog,
  }) async {
    final service = _service;
    if (service == null || _state is SecondOpinionAsking) return;

    _imagePath = imagePath;
    _publier(const SecondOpinionAsking());

    try {
      final opinion = await service.ask(
        imagePath: imagePath,
        cropName: cropName,
        catalog: catalog,
      );
      _publier(SecondOpinionReady(opinion));
    } on AppException catch (error) {
      _publier(SecondOpinionError(error.userMessage));
    }
  }

  /// Efface l'avis courant, par exemple pour réessayer après une erreur.
  void reset() {
    _imagePath = null;
    _publier(const SecondOpinionIdle());
  }

  void _publier(SecondOpinionState etat) {
    _state = etat;
    notifyListeners();
  }
}
