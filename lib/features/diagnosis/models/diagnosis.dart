import 'crop_profile.dart';
import 'prediction.dart';

/// Résultat complet d'une analyse : la photo, la culture, et les hypothèses
/// du modèle classées de la plus probable à la moins probable.
class Diagnosis {
  const Diagnosis({
    required this.crop,
    required this.imagePath,
    required this.predictions,
    required this.createdAt,
  });

  final Crop crop;

  /// Chemin de la photo sur l'appareil. L'image ne quitte jamais le téléphone.
  final String imagePath;

  /// Au moins une hypothèse, triée par confiance décroissante.
  final List<Prediction> predictions;

  final DateTime createdAt;

  /// Hypothèse principale.
  Prediction get best => predictions.first;

  /// Le modèle a répondu qu'il ne reconnaissait pas l'image.
  ///
  /// Seul CropNet, pour le manioc, sait produire cette réponse.
  bool get isUnknown => best.label == 'unknown';

  Map<String, Object?> toJson() => {
    'crop': crop.name,
    'imagePath': imagePath,
    'predictions': predictions.map((p) => p.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Diagnosis.fromJson(Map<String, Object?> json) => Diagnosis(
    crop: Crop.values.byName(json['crop']! as String),
    imagePath: json['imagePath']! as String,
    predictions: (json['predictions']! as List)
        .cast<Map<String, Object?>>()
        .map(Prediction.fromJson)
        .toList(growable: false),
    createdAt: DateTime.parse(json['createdAt']! as String),
  );
}
