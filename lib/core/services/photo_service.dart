import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import '../errors/app_exception.dart';

/// Origine de la photo à analyser.
enum PhotoSource { camera, gallery }

/// Récupère une photo depuis l'appareil.
///
/// Aucune logique métier : ce service ne sait pas ce qu'on fera de l'image.
class PhotoService {
  /// [picker] n'est fourni que par les tests.
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Renvoie `null` si l'utilisateur annule — ce n'est pas une erreur.
  ///
  /// L'image est réduite dès la capture : le modèle ne travaille qu'en
  /// 224 × 224, et décoder une photo de 12 Mpx coûterait plusieurs secondes
  /// sur un téléphone d'entrée de gamme.
  Future<XFile?> pick(PhotoSource source) async {
    try {
      return await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 88,
      );
    } on PlatformException catch (error) {
      if (error.code.contains('access_denied') ||
          error.code.contains('permission')) {
        throw PhotoException.permissionDenied(cause: error);
      }
      throw PhotoException(
        "La photo n'a pas pu être récupérée. Réessayez.",
        cause: error,
      );
    }
  }
}
