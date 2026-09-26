import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../models/treatment.dart';

/// Fournit les fiches maladies.
///
/// Elles sont embarquées dans l'application : une fiche doit rester lisible
/// sans réseau, au champ, là où le diagnostic vient d'avoir lieu. Firestore
/// viendra plus tard par-dessus, pour mettre à jour le contenu sans republier
/// l'application ; ce fichier restera le repli.
class TreatmentRepository {
  Map<String, Treatment>? _cache;

  /// Toutes les fiches, indexées par étiquette de modèle.
  Future<Map<String, Treatment>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    try {
      final raw = await rootBundle.loadString(AppConstants.treatmentsAsset);
      final decoded = jsonDecode(raw) as Map<String, Object?>;
      final fiches = (decoded['treatments']! as List)
          .cast<Map<String, Object?>>()
          .map(Treatment.fromJson);

      final byLabel = {for (final fiche in fiches) fiche.modelLabel: fiche};
      _cache = byLabel;
      return byLabel;
    } on Object catch (error) {
      throw StorageException(
        "Les fiches de traitement n'ont pas pu être chargées.",
        cause: error,
      );
    }
  }
}
