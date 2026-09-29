import 'package:cloud_firestore/cloud_firestore.dart';

/// Catalogue distant, tel qu'il est stocké.
typedef RemoteCatalog = ({int version, List<Map<String, Object?>> treatments});

/// D'où viennent les corrections apportées aux fiches.
///
/// Interface séparée de son implémentation Firestore pour une raison
/// précise : la garantie « les fiches s'affichent sans réseau » doit pouvoir
/// être vérifiée par un test avec une source qui échoue toujours.
abstract interface class TreatmentRemoteSource {
  /// Le catalogue distant, ou `null` s'il est injoignable ou inexploitable.
  ///
  /// Ne lève jamais : une correction indisponible n'est pas une erreur, c'est
  /// le cas normal hors connexion.
  Future<RemoteCatalog?> fetch();
}

/// Source Firestore : un seul document contient tout le catalogue.
///
/// Un document plutôt que vingt : une seule lecture, une seule mise en cache,
/// et une mise à jour qui ne peut pas laisser le catalogue à moitié corrigé.
/// Les 30 Ko du catalogue tiennent très largement sous la limite d'un
/// document Firestore.
class FirestoreTreatmentSource implements TreatmentRemoteSource {
  FirestoreTreatmentSource([FirebaseFirestore? firestore])
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const String collection = 'catalogue';
  static const String document = 'current';

  @override
  Future<RemoteCatalog?> fetch() async {
    try {
      // `FirebaseFirestore.instance` lève si Firebase n'a pas démarré : on
      // ne l'appelle donc qu'ici, et l'échec est traité comme une absence.
      final base = _firestore ?? FirebaseFirestore.instance;
      final snapshot = await base
          .collection(collection)
          .doc(document)
          .get(const GetOptions(source: Source.server));

      final data = snapshot.data();
      if (data == null) return null;

      final version = data['version'];
      final fiches = data['treatments'];
      if (version is! int || fiches is! List) return null;

      return (
        version: version,
        treatments: fiches.cast<Map<String, Object?>>(),
      );
    } on Object {
      // Réseau absent, règles refusées, Firebase non initialisé, document
      // malformé : dans tous les cas on garde les fiches embarquées.
      return null;
    }
  }
}
