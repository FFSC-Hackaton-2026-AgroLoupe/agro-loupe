/// Valeurs fixes partagées par toute l'application.
///
/// Classe non instanciable : on accède aux membres directement,
/// par exemple `AppConstants.confidenceThreshold`.
abstract final class AppConstants {
  /// Nom affiché de l'application.
  static const String appName = 'AgroLoupe';

  /// Modèle de classification embarqué dans l'APK.
  static const String modelAsset = 'assets/models/plant_disease.tflite';

  /// Étiquettes du modèle, une par ligne, dans l'ordre de ses sorties.
  static const String labelsAsset = 'assets/models/labels.txt';

  /// En dessous de ce score, le diagnostic est présenté comme incertain
  /// plutôt que comme un résultat sûr (voir la règle produit du cahier des charges).
  static const double confidenceThreshold = 0.60;

  /// Base SQLite locale qui contient l'historique des diagnostics.
  static const String databaseName = 'agro_loupe.db';

  /// À incrémenter à chaque changement du schéma de la base.
  static const int databaseVersion = 1;

  /// Logo pour fond clair. Sur fond sombre, le bleu de marque tombe à
  /// 1,98:1 de contraste : utiliser [logoOnDarkAsset] à la place.
  static const String logoAsset = 'assets/images/logo.png';

  /// Logo pour fond sombre : même dessin, tracé en bleu clair.
  static const String logoOnDarkAsset = 'assets/images/logo_on_dark.png';

  /// Illustration de l'écran de connexion (1080 × 1350).
  ///
  /// Le master pleine résolution est dans `design/sources/`, hors APK.
  static const String loginBackgroundAsset =
      'assets/images/login_background.jpg';

  /// Collection Firestore des fiches de traitement (lecture seule).
  static const String treatmentsCollection = 'treatments';
}
