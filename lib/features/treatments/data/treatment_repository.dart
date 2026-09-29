import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../models/treatment.dart';
import 'treatment_remote_source.dart';

/// Fournit les fiches maladies.
///
/// Les fiches sont **embarquées dans l'application** : c'est le chemin normal,
/// pas un plan de secours. Une fiche doit rester lisible sans réseau, au
/// champ, là où le diagnostic vient d'avoir lieu.
///
/// Firestore ne sert qu'à corriger ce contenu sans republier l'application —
/// utile parce qu'une fiche conseille des produits phytosanitaires, et qu'une
/// erreur doit pouvoir partir dans l'heure plutôt que d'attendre une mise à
/// jour de 46 Mo que personne n'installera.
///
/// Conséquence, inscrite dans la forme de cette classe : [loadAll] ne touche
/// jamais au réseau, et [fetchCorrections] est un appel distinct que
/// l'appelant lance quand il veut, sans jamais faire attendre l'affichage.
class TreatmentRepository {
  TreatmentRepository({TreatmentRemoteSource? remote})
    : _remote = remote ?? FirestoreTreatmentSource();

  final TreatmentRemoteSource _remote;

  Map<String, Treatment>? _cache;

  /// Version du catalogue actuellement en mémoire.
  int _version = 0;

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

      final version = decoded['version'];
      _version = version is int ? version : 0;

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

  /// Tente de récupérer une version corrigée des fiches.
  ///
  /// Renvoie `null` quand il n'y a rien de neuf à appliquer : pas de réseau,
  /// version distante identique ou plus ancienne, document illisible. Aucun
  /// de ces cas n'est une erreur — les fiches embarquées font foi en
  /// attendant.
  Future<Map<String, Treatment>?> fetchCorrections() async {
    // L'appel lui-même est protégé : l'interface promet de ne pas lever,
    // mais une implémentation fautive ne doit pas pouvoir faire tomber
    // l'écran des fiches.
    try {
      final distant = await _remote.fetch();
      if (distant == null || distant.version <= _version) return null;

      final fiches = distant.treatments.map(Treatment.fromJson);
      final byLabel = {for (final fiche in fiches) fiche.modelLabel: fiche};
      if (byLabel.isEmpty) return null;

      _cache = byLabel;
      _version = distant.version;
      return byLabel;
    } on Object {
      // Un catalogue distant mal formé ne doit pas effacer un catalogue
      // embarqué qui fonctionne.
      return null;
    }
  }
}
