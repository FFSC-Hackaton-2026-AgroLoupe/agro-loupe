import '../../../core/constants/app_constants.dart';

/// Culture couverte par l'application.
enum Crop { cassava, tomato, maize }

/// Décrit une culture et le modèle qui la diagnostique.
///
/// Ajouter une culture consiste à écrire un profil de plus, pas à modifier le
/// service de classification.
class CropProfile {
  const CropProfile({
    required this.crop,
    required this.displayName,
    required this.modelAsset,
    required this.labelsAsset,
    required this.labelPrefix,
    required this.hasUnknownClass,
    this.inputSize = AppConstants.modelInputSize,
  });

  final Crop crop;

  /// Nom affiché à l'utilisateur.
  final String displayName;

  final String modelAsset;
  final String labelsAsset;

  /// Préfixe des étiquettes à retenir dans la sortie du modèle.
  ///
  /// `null` quand le modèle est dédié à une seule culture et que toutes ses
  /// sorties sont pertinentes. Sinon, seules les classes correspondantes sont
  /// conservées puis renormalisées : sur une feuille de tomate, cela évite au
  /// modèle partagé de proposer une maladie du pommier, et resserre nettement
  /// la confiance du bon résultat.
  final String? labelPrefix;

  /// Le modèle sait-il répondre « je ne reconnais pas » ?
  ///
  /// CropNet a été entraîné avec des contre-exemples et dispose d'une classe
  /// `unknown`. Le modèle PlantVillage, non : face à une affection absente de
  /// ses classes, il désigne la moins improbable, parfois avec une très forte
  /// confiance. Le seuil de confiance ne protège donc pas dans ce cas, et
  /// l'interface doit faire confirmer le résultat par l'utilisateur.
  final bool hasUnknownClass;

  /// Côté du carré attendu en entrée, en pixels.
  final int inputSize;

  /// Les trois cultures couvertes, et leur modèle respectif.
  static const List<CropProfile> all = [cassava, tomato, maize];

  static const CropProfile cassava = CropProfile(
    crop: Crop.cassava,
    displayName: 'Manioc',
    modelAsset: AppConstants.cassavaModelAsset,
    labelsAsset: AppConstants.cassavaLabelsAsset,
    labelPrefix: null,
    hasUnknownClass: true,
  );

  static const CropProfile tomato = CropProfile(
    crop: Crop.tomato,
    displayName: 'Tomate',
    modelAsset: AppConstants.plantVillageModelAsset,
    labelsAsset: AppConstants.plantVillageLabelsAsset,
    labelPrefix: 'Tomato',
    hasUnknownClass: false,
  );

  static const CropProfile maize = CropProfile(
    crop: Crop.maize,
    displayName: 'Maïs',
    modelAsset: AppConstants.plantVillageModelAsset,
    labelsAsset: AppConstants.plantVillageLabelsAsset,
    labelPrefix: 'Corn_',
    hasUnknownClass: false,
  );

  static CropProfile of(Crop crop) =>
      all.firstWhere((profile) => profile.crop == crop);
}
