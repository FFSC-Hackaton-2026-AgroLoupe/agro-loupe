/// Formatage des dates en français, sans paquet supplémentaire.
///
/// `intl` ferait l'affaire, mais chaque dépendance ajoutée est un risque de
/// plus le jour de la démo, et nous n'avons besoin que d'un seul format.
abstract final class DateFr {
  static const List<String> _mois = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  /// Par exemple : `26 sept. 2026 à 14:30`.
  static String dateEtHeure(DateTime date) {
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${_mois[date.month - 1]} ${date.year} '
        'à $heure:$minute';
  }
}
