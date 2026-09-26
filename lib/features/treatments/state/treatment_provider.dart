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
}
