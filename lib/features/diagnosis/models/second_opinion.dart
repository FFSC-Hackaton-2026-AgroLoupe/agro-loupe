/// Degré de certitude exprimé par le modèle en ligne.
///
/// Volontairement en mots, jamais en pourcentage. Le seuil de 60 % du modèle
/// embarqué porte sur une probabilité calculée ; une confiance qu'un modèle
/// s'attribue lui-même n'est pas de même nature et n'est pas comparable.
/// Les afficher côte à côte induirait l'utilisateur en erreur.
enum SecondOpinionCertainty {
  high('Correspondance nette'),
  medium('Correspondance possible'),
  low('Simple piste');

  const SecondOpinionCertainty(this.label);

  /// Libellé affiché, en français.
  final String label;

  /// Traduit la valeur renvoyée par le modèle, repli sur [low] si elle est
  /// absente ou inattendue : mieux vaut sous-vendre une réponse juste que
  /// présenter une réponse fausse comme sûre.
  static SecondOpinionCertainty parse(Object? value) => switch (value) {
    'haute' => high,
    'moyenne' => medium,
    _ => low,
  };
}

/// Réponse du deuxième avis en ligne.
///
/// Le modèle **identifie**, il ne soigne pas : cette classe ne porte donc
/// aucun conseil de traitement. Quand [label] correspond à une de nos fiches,
/// c'est la fiche rédigée par l'équipe qui fournit la conduite à tenir.
class SecondOpinion {
  const SecondOpinion({
    required this.label,
    required this.name,
    required this.certainty,
    required this.observation,
    required this.pestRatherThanDisease,
    required this.reasonIfNone,
  });

  /// Étiquette d'une de nos fiches, ou `null` si aucune ne convient.
  ///
  /// `null` est une bonne réponse, et même la plus précieuse : c'est
  /// exactement ce que le modèle embarqué est incapable de dire.
  final String? label;

  /// Nom français de la maladie, ou `null`.
  final String? name;

  final SecondOpinionCertainty certainty;

  /// Ce que le modèle dit voir sur la feuille, en une ou deux phrases.
  final String observation;

  /// Vrai lorsqu'il s'agit d'un ravageur plutôt que d'une maladie.
  ///
  /// Cas fréquent au champ, et angle mort du modèle embarqué : aucune de ses
  /// 38 classes ne décrit un insecte.
  final bool pestRatherThanDisease;

  /// Pourquoi aucune fiche ne convient, quand [label] vaut `null`.
  final String? reasonIfNone;

  /// Vrai si le modèle n'a retenu aucune de nos fiches.
  bool get isInconclusive => label == null;

  factory SecondOpinion.fromJson(Map<String, dynamic> json) {
    final label = _texte(json['etiquette']);
    return SecondOpinion(
      label: label,
      name: _texte(json['nom']),
      certainty: SecondOpinionCertainty.parse(json['certitude']),
      observation: _texte(json['observation']) ?? '',
      pestRatherThanDisease: json['ravageur_plutot_que_maladie'] == true,
      reasonIfNone: _texte(json['raison_si_aucune']),
    );
  }

  /// Le modèle peut renvoyer `null`, la chaîne vide ou le mot « null ».
  /// Les trois veulent dire la même chose ici.
  static String? _texte(Object? valeur) {
    if (valeur is! String) return null;
    final nettoye = valeur.trim();
    if (nettoye.isEmpty || nettoye == 'null') return null;
    return nettoye;
  }
}
