import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/photo_service.dart';
import '../data/diagnosis_repository.dart';
import '../models/crop_profile.dart';
import '../models/diagnosis.dart';
import '../models/prediction.dart';

/// État de l'écran de diagnostic.
sealed class DiagnosisState {
  const DiagnosisState();
}

/// Aucune analyse en cours : on attend une photo.
class DiagnosisIdle extends DiagnosisState {
  const DiagnosisIdle();
}

class DiagnosisAnalyzing extends DiagnosisState {
  const DiagnosisAnalyzing();
}

/// Une hypothèse est proposée à l'utilisateur, qui doit la confirmer.
///
/// [shownIndex] avance à chaque rejet : c'est la confirmation par symptômes
/// exigée par le cahier des charges. Elle existe parce que le modèle des
/// cultures tomate et maïs peut se tromper avec une très forte confiance.
class DiagnosisSuccess extends DiagnosisState {
  const DiagnosisSuccess(this.diagnosis, {this.shownIndex = 0});

  final Diagnosis diagnosis;
  final int shownIndex;

  Prediction get prediction => diagnosis.predictions[shownIndex];

  /// Reste-t-il une hypothèse à proposer après celle-ci ?
  bool get hasNext => shownIndex + 1 < diagnosis.predictions.length;

  /// Vrai dès la deuxième hypothèse : l'utilisateur a rejeté la précédente.
  bool get isFallback => shownIndex > 0;
}

/// L'utilisateur a reconnu les symptômes : le traitement peut être affiché.
///
/// Tant qu'il n'a pas confirmé, on ne conseille rien — une hypothèse rejetée
/// ne doit pas conduire à traiter la mauvaise maladie.
class DiagnosisConfirmed extends DiagnosisState {
  const DiagnosisConfirmed(this.diagnosis, {this.shownIndex = 0});

  final Diagnosis diagnosis;

  /// Conservé pour pouvoir revenir sur la bonne hypothèse.
  final int shownIndex;

  Prediction get prediction => diagnosis.predictions[shownIndex];
}

/// Toutes les hypothèses ont été rejetées par l'utilisateur.
class DiagnosisExhausted extends DiagnosisState {
  const DiagnosisExhausted(this.diagnosis);

  final Diagnosis diagnosis;
}

class DiagnosisError extends DiagnosisState {
  const DiagnosisError(this.message);

  /// Message en français, directement affichable.
  final String message;
}

/// Pilote le diagnostic : choix de la culture, analyse, puis confirmation.
class DiagnosisProvider extends ChangeNotifier {
  DiagnosisProvider(this._repository);

  final DiagnosisRepository _repository;

  DiagnosisState _state = const DiagnosisIdle();
  DiagnosisState get state => _state;

  Crop _crop = Crop.cassava;

  /// Culture choisie par l'utilisateur, toujours définie.
  Crop get crop => _crop;

  CropProfile get profile => CropProfile.of(_crop);

  /// Change de culture et efface le résultat précédent, qui ne s'y applique plus.
  void selectCrop(Crop crop) {
    if (crop == _crop) return;
    _crop = crop;
    _state = const DiagnosisIdle();
    notifyListeners();
    // Chargement anticipé : l'utilisateur va probablement photographier.
    _repository.prepare(crop).ignore();
  }

  /// Prend une photo puis l'analyse. Sans effet si une analyse est en cours.
  Future<void> analyze(PhotoSource source) async {
    if (_state is DiagnosisAnalyzing) return;
    _setState(const DiagnosisAnalyzing());
    try {
      final diagnosis = await _repository.diagnose(crop: _crop, source: source);
      // L'utilisateur a refermé la caméra sans photographier.
      if (diagnosis == null) {
        _setState(const DiagnosisIdle());
        return;
      }
      _setState(DiagnosisSuccess(diagnosis));
    } on AppException catch (error) {
      _setState(DiagnosisError(error.userMessage));
    }
  }

  /// L'utilisateur indique que les symptômes décrits ne correspondent pas.
  ///
  /// On passe à l'hypothèse suivante, et s'il n'en reste aucune on l'oriente
  /// vers un agent agricole plutôt que d'insister.
  void rejectCurrent() {
    final current = _state;
    if (current is! DiagnosisSuccess) return;
    _setState(
      current.hasNext
          ? DiagnosisSuccess(
              current.diagnosis,
              shownIndex: current.shownIndex + 1,
            )
          : DiagnosisExhausted(current.diagnosis),
    );
  }

  /// L'utilisateur reconnaît les symptômes décrits.
  void confirmCurrent() {
    final current = _state;
    if (current is! DiagnosisSuccess) return;
    _setState(
      DiagnosisConfirmed(current.diagnosis, shownIndex: current.shownIndex),
    );
  }

  /// Revient d'une étape en arrière.
  ///
  /// Renvoie `false` quand il n'y a plus d'étape précédente : l'appelant laisse
  /// alors le système fermer l'application.
  bool goBack() {
    final current = _state;
    switch (current) {
      // Depuis la fiche, on retrouve l'hypothèse qu'on venait de confirmer.
      case DiagnosisConfirmed():
        _setState(
          DiagnosisSuccess(current.diagnosis, shownIndex: current.shownIndex),
        );
        return true;
      case DiagnosisSuccess():
      case DiagnosisExhausted():
      case DiagnosisError():
        _setState(const DiagnosisIdle());
        return true;
      // Une analyse en cours ne s'interrompt pas à mi-chemin.
      case DiagnosisIdle():
      case DiagnosisAnalyzing():
        return false;
    }
  }

  /// Revient à l'écran de départ.
  void reset() => _setState(const DiagnosisIdle());

  void _setState(DiagnosisState state) {
    _state = state;
    notifyListeners();
  }
}
