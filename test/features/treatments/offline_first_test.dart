import 'package:agro_loupe/features/treatments/data/treatment_remote_source.dart';
import 'package:agro_loupe/features/treatments/data/treatment_repository.dart';
import 'package:agro_loupe/features/treatments/state/treatment_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Source distante toujours injoignable : le cas d'un utilisateur qui n'a
/// jamais eu de réseau.
class _SourceMuette implements TreatmentRemoteSource {
  int appels = 0;

  @override
  Future<RemoteCatalog?> fetch() async {
    appels++;
    return null;
  }
}

/// Source qui échoue bruyamment, comme un Firestore mal configuré.
class _SourceQuiLeve implements TreatmentRemoteSource {
  @override
  Future<RemoteCatalog?> fetch() async => throw StateError('pas de réseau');
}

/// Source renvoyant un catalogue corrigé.
class _SourceCorrigee implements TreatmentRemoteSource {
  _SourceCorrigee({required this.version, required this.nom});

  final int version;
  final String nom;

  @override
  Future<RemoteCatalog?> fetch() async => (
    version: version,
    treatments: [
      {
        'id': 'tomate_mildiou',
        'modelLabel': 'Tomato___Late_blight',
        'crop': 'tomate',
        'name': nom,
        'severity': 'élevée',
        'symptoms': <String>['Taches brunes'],
        'confusions': <String>[],
        'culturalPractices': <String>[],
        'chemicalTreatment': <String>[],
        'prevention': <String>[],
        'whenToConsult': 'Voir un agent agricole.',
        'note': null,
        'source': null,
      },
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('les fiches s\'affichent sans jamais joindre le réseau', () async {
    final source = _SourceMuette();
    final provider = TreatmentProvider(TreatmentRepository(remote: source));

    await provider.load();

    // C'est la promesse du produit : un utilisateur qui n'a jamais eu de
    // connexion doit voir les 20 fiches livrées avec l'application.
    final state = provider.state;
    expect(state, isA<TreatmentsReady>());
    expect((state as TreatmentsReady).byLabel.length, 20);
    expect(provider.forLabel('Tomato___Late_blight')?.name, 'Mildiou');
    expect(source.appels, 1, reason: 'la correction est bien tentée');
  });

  test('une source qui lève ne casse rien', () async {
    final provider = TreatmentProvider(
      TreatmentRepository(remote: _SourceQuiLeve()),
    );

    await provider.load();

    // Firestore mal configuré, règles refusées, Firebase non démarré : dans
    // tous les cas l'utilisateur garde ses fiches.
    expect(provider.state, isA<TreatmentsReady>());
    expect(provider.forLabel('Tomato___Late_blight'), isNotNull);
  });

  test('une correction plus récente remplace la fiche embarquée', () async {
    final provider = TreatmentProvider(
      TreatmentRepository(
        remote: _SourceCorrigee(version: 99, nom: 'Mildiou (corrigé)'),
      ),
    );

    await provider.load();

    expect(
      provider.forLabel('Tomato___Late_blight')?.name,
      'Mildiou (corrigé)',
    );
  });

  test('une version plus ancienne est ignorée', () async {
    final provider = TreatmentProvider(
      TreatmentRepository(
        remote: _SourceCorrigee(version: 0, nom: 'Vieille version'),
      ),
    );

    await provider.load();

    // Sans ce garde-fou, un catalogue distant oublié en arrière écraserait
    // des fiches plus récentes livrées avec l'application.
    expect(provider.forLabel('Tomato___Late_blight')?.name, 'Mildiou');
    expect(provider.forLabel('cmd'), isNotNull);
  });
}
