import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/treatment_repository.dart';
import '../models/treatment.dart';

sealed class TreatmentsState {
  const TreatmentsState();
}

class TreatmentsLoading extends TreatmentsState {
  const TreatmentsLoading();
}

class TreatmentsReady extends TreatmentsState {
  const TreatmentsReady(this.byLabel);

  final Map<String, Treatment> byLabel;
}

class TreatmentsError extends TreatmentsState {
  const TreatmentsError(this.message);

  final String message;
}

/// Tient en mémoire les fiches maladies.
///
/// Chargées une fois au démarrage : le fichier est petit, et une fiche doit
/// s'afficher instantanément après un diagnostic, sans attente ni réseau.
class TreatmentProvider extends ChangeNotifier {
  TreatmentProvider(this._repository);

  final TreatmentRepository _repository;

  TreatmentsState _state = const TreatmentsLoading();
  TreatmentsState get state => _state;

  Future<void> load() async {
    try {
      final byLabel = await _repository.loadAll();
      _state = TreatmentsReady(byLabel);
    } on AppException catch (error) {
      _state = TreatmentsError(error.userMessage);
    }
    notifyListeners();
  }

  /// Fiche correspondant à une étiquette de modèle, ou `null` si elle manque.
  Treatment? forLabel(String label) => switch (_state) {
    TreatmentsReady(:final byLabel) => byLabel[label],
    _ => null,
  };

  /// Fiches d'une culture, triées par nom.
  ///
  /// [crop] est la valeur telle qu'elle figure dans les fiches : `manioc`,
  /// `tomate` ou `maïs`. La comparaison ignore la casse, pour accepter aussi
  /// le nom affiché d'un `CropProfile`.
  ///
  /// Liste vide tant que les fiches ne sont pas chargées : un écran qui
  /// n'affiche rien pendant un instant vaut mieux qu'un écran qui plante.
  List<Treatment> forCrop(String crop) {
    final state = _state;
    if (state is! TreatmentsReady) return const [];

    final recherche = crop.toLowerCase();
    final fiches = state.byLabel.values
        .where((fiche) => fiche.crop.toLowerCase() == recherche)
        .toList();
    fiches.sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(fiches);
  }
}
