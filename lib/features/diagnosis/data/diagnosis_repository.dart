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
  ///
  /// Sans effet pour une culture sans modèle embarqué : il n'y a rien à
  /// charger, l'analyse se fera en ligne.
  Future<void> prepare(Crop crop) {
    final profile = CropProfile.of(crop);
    if (!profile.hasLocalModel) return Future.value();
    return _classifier.warmUp(profile);
  }

  /// Prend une photo sans l'analyser, pour les cultures sans modèle embarqué.
  ///
  /// Renvoie `null` si l'utilisateur renonce.
  Future<String?> takePhoto(PhotoSource source) async =>
      (await _photos.pick(source))?.path;

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
