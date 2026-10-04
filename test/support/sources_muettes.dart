import 'package:agro_loupe/features/treatments/data/treatment_remote_source.dart';

/// Source distante toujours injoignable.
///
/// À utiliser dans tout test qui construit un [TreatmentRepository] : sans
/// elle, le repository appelle Firestore, qui n'existe pas en test. Le code
/// le rattrape, mais chaque test paie l'attente pour rien.
class SourceMuette implements TreatmentRemoteSource {
  @override
  Future<RemoteCatalog?> fetch() async => null;
}
