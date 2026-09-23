import '../../../core/constants/app_constants.dart';

/// Une hypothèse rendue par le modèle, avec son niveau de confiance.
class Prediction {
  const Prediction({required this.label, required this.confidence});

  /// Étiquette brute du modèle, par exemple `cmd` ou `Tomato___Late_blight`.
  ///
  /// C'est la clé qui relie le résultat à sa fiche de traitement ; elle n'est
  /// jamais affichée telle quelle à l'utilisateur.
  final String label;

  /// Probabilité entre 0 et 1, après filtrage sur la culture choisie.
  final double confidence;

  /// Sous le seuil, le résultat est présenté comme incertain.
  bool get isUncertain => confidence < AppConstants.confidenceThreshold;

  /// Pourcentage arrondi, prêt à être affiché.
  int get percent => (confidence * 100).round();

  @override
  String toString() => '$label ($percent%)';
}
