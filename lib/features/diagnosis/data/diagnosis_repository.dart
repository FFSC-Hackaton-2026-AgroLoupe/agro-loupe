import '../../../core/services/photo_service.dart';
import '../models/crop_profile.dart';
import '../models/diagnosis.dart';
import 'classifier_service.dart';

/// Enchaîne la prise de photo et l'analyse.
///
/// C'est le seul endroit qui connaît l'ordre des opérations ; le provider ne
/// sait rien de `image_picker` ni de TFLite.
class DiagnosisRepository {
  DiagnosisRepository(this._classifier, this._photos);

  final ClassifierService _classifier;
  final PhotoService _photos;

  /// Prépare le modèle d'une culture pendant que l'utilisateur cadre sa photo.
  Future<void> prepare(Crop crop) => _classifier.warmUp(CropProfile.of(crop));

  /// Renvoie `null` si l'utilisateur renonce à prendre la photo.
  Future<Diagnosis?> diagnose({
    required Crop crop,
    required PhotoSource source,
  }) async {
    final photo = await _photos.pick(source);
    if (photo == null) return null;

    final predictions = await _classifier.classify(
      imageBytes: await photo.readAsBytes(),
      profile: CropProfile.of(crop),
    );

    return Diagnosis(
      crop: crop,
      imagePath: photo.path,
      predictions: predictions,
      createdAt: DateTime.now(),
    );
  }
}
