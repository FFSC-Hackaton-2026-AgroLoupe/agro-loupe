/// Erreur métier de l'application.
///
/// Toute erreur remontée par la couche `data/` est traduite en `AppException`
/// portant un [userMessage] en français, directement affichable. Les providers
/// attrapent ces exceptions et les transforment en état d'erreur ; l'interface
/// n'a jamais à interpréter une erreur technique.
sealed class AppException implements Exception {
  const AppException(this.userMessage, {this.cause});

  /// Message destiné à l'utilisateur : en français, sans jargon.
  final String userMessage;

  /// Erreur d'origine, conservée pour les journaux. Jamais affichée.
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType: $userMessage${cause == null ? '' : ' (cause : $cause)'}';
}

/// Le modèle de diagnostic n'a pas pu être chargé ou exécuté.
final class ModelException extends AppException {
  const ModelException(super.userMessage, {super.cause});

  /// Cas courant : le fichier `.tflite` est absent ou illisible.
  const ModelException.unavailable({Object? cause})
    : this(
        "Le module de diagnostic n'a pas pu démarrer. "
        'Réinstallez l\'application si le problème persiste.',
        cause: cause,
      );
}

/// La photo n'a pas pu être prise ou lue.
final class PhotoException extends AppException {
  const PhotoException(super.userMessage, {super.cause});

  /// Cas courant : l'utilisateur refuse l'accès à la caméra ou à la galerie.
  const PhotoException.permissionDenied({Object? cause})
    : this(
        "L'application a besoin d'accéder à la caméra pour analyser une feuille. "
        'Autorisez-la dans les réglages du téléphone.',
        cause: cause,
      );
}

/// Lecture ou écriture impossible sur le stockage local.
final class StorageException extends AppException {
  const StorageException(super.userMessage, {super.cause});

  /// Cas courant : la base locale est corrompue ou la mémoire est pleine.
  const StorageException.unavailable({Object? cause})
    : this(
        "L'historique n'est pas accessible pour le moment. "
        'Vérifiez l\'espace libre sur le téléphone.',
        cause: cause,
      );
}

/// Une donnée distante était nécessaire mais le réseau manque.
///
/// Ne concerne jamais le diagnostic, qui fonctionne toujours hors-ligne.
final class NetworkException extends AppException {
  const NetworkException(super.userMessage, {super.cause});

  /// Cas courant : la fiche demandée n'a jamais été mise en cache.
  const NetworkException.offline({Object? cause})
    : this(
        'Cette fiche de traitement n\'a pas encore été téléchargée. '
        'Reconnectez-vous une fois pour la consulter hors-ligne ensuite.',
        cause: cause,
      );
}
