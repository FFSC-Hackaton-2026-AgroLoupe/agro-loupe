/// Valeurs fixes partagées par toute l'application.
///
/// Classe non instanciable : on accède aux membres directement,
/// par exemple `AppConstants.confidenceThreshold`.
abstract final class AppConstants {
  /// Nom affiché de l'application.
  static const String appName = 'AgroLoupe';

  /// Modèle du manioc (CropNet, Google) : sorties déjà en probabilités.
  static const String cassavaModelAsset =
      'assets/models/cassava_cropnet.tflite';
  static const String cassavaLabelsAsset = 'assets/models/cassava_labels.txt';

  /// Modèle tomate et maïs (PlantVillage, 38 classes).
  ///
  /// Sorties déjà en probabilités, malgré une documentation qui annonce des
  /// logits : la somme mesurée sur le modèle converti vaut 1,000. Ne pas
  /// appliquer de softmax, cela écraserait les scores sous le seuil.
  static const String plantVillageModelAsset =
      'assets/models/plantvillage.tflite';
  static const String plantVillageLabelsAsset =
      'assets/models/plantvillage_labels.txt';

  /// Taille d'entrée commune aux deux modèles, en pixels.
  static const int modelInputSize = 224;

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
