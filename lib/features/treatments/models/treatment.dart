/// Fiche d'une maladie : ce qu'on observe, ce qu'on fait, ce qu'on évite.
///
/// Reliée au diagnostic par [modelLabel], qui est l'étiquette brute rendue par
/// le modèle. C'est la seule clé de jointure entre l'IA et le contenu rédigé.
class Treatment {
  const Treatment({
    required this.id,
    required this.modelLabel,
    required this.crop,
    required this.name,
    required this.severity,
    required this.symptoms,
    required this.confusions,
    required this.culturalPractices,
    required this.chemicalTreatment,
    required this.prevention,
    required this.whenToConsult,
    this.note,
    this.source,
  });

  final String id;

  /// Étiquette du modèle, par exemple `cmd` ou `Tomato___Late_blight`.
  final String modelLabel;

  /// `manioc`, `tomate` ou `maïs`.
  final String crop;

  /// Nom affiché, en français courant.
  final String name;

  /// `aucune`, `moyenne` ou `élevée`.
  final String severity;

  /// Ce que l'utilisateur devrait voir sur son plant. Sert à la confirmation.
  final List<String> symptoms;

  /// Affections voisines, pour éviter une erreur d'interprétation.
  final List<String> confusions;

  /// Gestes à faire sans produit : ce sont les plus sûrs et souvent les plus
  /// efficaces.
  final List<String> culturalPractices;

  /// Matières actives, sans nom commercial ni dose : les homologations et les
  /// formulations varient d'un pays à l'autre.
  final List<String> chemicalTreatment;

  final List<String> prevention;

  /// Le seuil à partir duquel il faut cesser de bricoler et demander de l'aide.
  final String whenToConsult;

  /// Mise en garde particulière à cette maladie, affichée en évidence.
  final String? note;

  /// Référence agronomique. Vide tant que la fiche n'a pas été relue.
  final String? source;

  /// La plante est saine : rien à traiter.
  bool get isHealthy => severity == 'aucune' && symptoms.isNotEmpty;

  static List<String> _strings(Object? value) =>
      (value as List?)?.cast<String>().toList(growable: false) ?? const [];

  factory Treatment.fromJson(Map<String, Object?> json) => Treatment(
    id: json['id']! as String,
    modelLabel: json['modelLabel']! as String,
    crop: json['crop']! as String,
    name: json['name']! as String,
    severity: json['severity']! as String,
    symptoms: _strings(json['symptoms']),
    confusions: _strings(json['confusions']),
    culturalPractices: _strings(json['culturalPractices']),
    chemicalTreatment: _strings(json['chemicalTreatment']),
    prevention: _strings(json['prevention']),
    whenToConsult: json['whenToConsult'] as String? ?? '',
    note: json['note'] as String?,
    source: json['source'] as String?,
  );
}
