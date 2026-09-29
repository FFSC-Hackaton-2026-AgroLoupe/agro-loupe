import '../../../core/constants/app_constants.dart';

/// Culture choisie par l'utilisateur.
///
/// [other] n'est pas une culture : c'est le choix « une autre culture », pour
/// laquelle aucun modèle n'est embarqué. Gemini nomme alors la plante *et* le
/// problème, ce qui évite une liste de cultures supplémentaires — il en
/// manquerait toujours une — et un champ de saisie, que notre utilisateur
/// cible remplit mal.
enum Crop { cassava, tomato, maize, other }

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
    required this.imageAsset,
    this.inputSize = AppConstants.modelInputSize,
  });

  final Crop crop;

  /// Nom affiché à l'utilisateur.
  final String displayName;

  /// `null` pour une culture sans modèle embarqué : le diagnostic passe alors
  /// entièrement par le service en ligne.
  final String? modelAsset;
  final String? labelsAsset;

  /// Peut-on diagnostiquer cette culture hors connexion ?
  bool get hasLocalModel => modelAsset != null && labelsAsset != null;

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

  /// Photo de la culture, affichée dans le sélecteur. `null` quand il n'y a
  /// pas de plante précise à montrer.
  ///
  /// On y montre le produit récolté — tubercules, fruits, épi — plutôt que la
  /// feuille : c'est à cela qu'un producteur reconnaît sa culture d'un coup
  /// d'œil, sans avoir à lire. La consigne de photographier une feuille est
  /// donnée juste en dessous, à l'étape suivante.
  final String? imageAsset;

  /// Côté du carré attendu en entrée, en pixels.
  final int inputSize;

  /// Tous les choix proposés, y compris « une autre culture ».
  static const List<CropProfile> all = [cassava, tomato, maize, other];

  /// Les seules cultures diagnostiquables hors connexion.
  static const List<CropProfile> withLocalModel = [cassava, tomato, maize];

  static const CropProfile cassava = CropProfile(
    crop: Crop.cassava,
    displayName: 'Manioc',
    modelAsset: AppConstants.cassavaModelAsset,
    labelsAsset: AppConstants.cassavaLabelsAsset,
    labelPrefix: null,
    hasUnknownClass: true,
    imageAsset: 'assets/images/manioc.jpg',
  );

  static const CropProfile tomato = CropProfile(
    crop: Crop.tomato,
    displayName: 'Tomate',
    modelAsset: AppConstants.plantVillageModelAsset,
    labelsAsset: AppConstants.plantVillageLabelsAsset,
    labelPrefix: 'Tomato',
    hasUnknownClass: false,
    imageAsset: 'assets/images/tomate.jpg',
  );

  static const CropProfile maize = CropProfile(
    crop: Crop.maize,
    displayName: 'Maïs',
    modelAsset: AppConstants.plantVillageModelAsset,
    labelsAsset: AppConstants.plantVillageLabelsAsset,
    labelPrefix: 'Corn_',
    hasUnknownClass: false,
    imageAsset: 'assets/images/mais.jpg',
  );

  /// Choix « une autre culture » : aucun modèle, aucune image, et le
  /// diagnostic exige internet — ce que l'interface doit dire clairement.
  static const CropProfile other = CropProfile(
    crop: Crop.other,
    displayName: 'Une autre culture',
    modelAsset: null,
    labelsAsset: null,
    labelPrefix: null,
    hasUnknownClass: false,
    imageAsset: null,
  );

  static CropProfile of(Crop crop) =>
      all.firstWhere((profile) => profile.crop == crop);
}
