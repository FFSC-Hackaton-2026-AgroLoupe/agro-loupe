import 'package:agro_loupe/features/treatments/data/treatment_repository.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Étiquettes réellement produites par les deux modèles embarqués.
Future<Set<String>> _labelsFromModels() async {
  final manioc = await rootBundle.loadString(
    'assets/models/cassava_labels.txt',
  );
  final plantVillage = await rootBundle.loadString(
    'assets/models/plantvillage_labels.txt',
  );

  List<String> lignes(String raw) =>
      raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  return {
    ...lignes(manioc),
    ...lignes(
      plantVillage,
    ).where((l) => l.startsWith('Tomato') || l.startsWith('Corn_')),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TreatmentRepository repository;

  setUp(() => repository = TreatmentRepository());

  test('chaque classe des modèles possède sa fiche', () async {
    final fiches = await repository.loadAll();
    final attendues = await _labelsFromModels();

    final manquantes = attendues.difference(fiches.keys.toSet());
    expect(
      manquantes,
      isEmpty,
      reason:
          'Ces classes seraient diagnostiquées sans fiche à afficher : $manquantes',
    );

    final orphelines = fiches.keys.toSet().difference(attendues);
    expect(
      orphelines,
      isEmpty,
      reason: 'Fiches sans classe correspondante : $orphelines',
    );
  });

  test('aucune fiche n\'est vide de contenu', () async {
    final fiches = await repository.loadAll();

    for (final fiche in fiches.values) {
      expect(fiche.name, isNotEmpty, reason: fiche.id);
      expect(fiche.symptoms, isNotEmpty, reason: '${fiche.id} : symptômes');
      expect(
        fiche.culturalPractices,
        isNotEmpty,
        reason: '${fiche.id} : pratiques culturales',
      );
      expect(
        fiche.chemicalTreatment,
        isNotEmpty,
        reason: '${fiche.id} : traitement',
      );
    }
  });

  test('les fiches des plants sains ne proposent pas de produit', () async {
    final fiches = await repository.loadAll();
    final saines = fiches.values.where((f) => f.severity == 'aucune');

    expect(saines, isNotEmpty);
    for (final fiche in saines) {
      // Traiter un plant sain coûte de l'argent et favorise les résistances :
      // la fiche doit le dire, pas proposer une matière active.
      expect(
        fiche.chemicalTreatment.join(' ').toLowerCase(),
        isNot(anyOf(contains('mancozèbe'), contains('cuivre'))),
        reason: fiche.id,
      );
    }
  });

  test('le contenu est mis en cache après le premier chargement', () async {
    final premier = await repository.loadAll();
    final second = await repository.loadAll();

    expect(identical(premier, second), isTrue);
  });
}
