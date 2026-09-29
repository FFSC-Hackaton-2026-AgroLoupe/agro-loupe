import 'package:agro_loupe/core/errors/app_exception.dart';
import 'package:agro_loupe/features/diagnosis/data/second_opinion_service.dart';
import 'package:agro_loupe/features/diagnosis/models/second_opinion.dart';
import 'package:agro_loupe/features/diagnosis/state/second_opinion_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecondOpinionService extends Mock implements SecondOpinionService {}

const _photo = '/tmp/feuille.jpg';

SecondOpinion _avis({String? label = 'Tomato___Late_blight'}) => SecondOpinion(
  label: label,
  name: 'Mildiou',
  certainty: SecondOpinionCertainty.high,
  observation: 'Larges taches brunes et humides.',
  pestRatherThanDisease: false,
  reasonIfNone: null,
);

void main() {
  setUpAll(() => registerFallbackValue(<CatalogEntry>[]));

  group('lecture de la réponse', () {
    test('une réponse complète est lue telle quelle', () {
      final avis = SecondOpinion.fromJson({
        'etiquette': 'Tomato___Late_blight',
        'nom': 'Mildiou',
        'certitude': 'haute',
        'observation': 'Taches brunes.',
        'ravageur_plutot_que_maladie': false,
        'raison_si_aucune': null,
      });

      expect(avis.label, 'Tomato___Late_blight');
      expect(avis.certainty, SecondOpinionCertainty.high);
      expect(avis.isInconclusive, isFalse);
    });

    test('un refus est reconnu comme tel', () {
      final avis = SecondOpinion.fromJson({
        'etiquette': null,
        'nom': null,
        'certitude': 'haute',
        'observation': "L'image ne montre pas de feuille.",
        'ravageur_plutot_que_maladie': false,
        'raison_si_aucune': "Il s'agit du portrait d'une personne.",
      });

      // C'est la réponse qui justifie toute l'intégration : le modèle
      // embarqué, lui, nommerait une maladie avec aplomb.
      expect(avis.isInconclusive, isTrue);
      expect(avis.reasonIfNone, isNotNull);
    });

    test('le mot « null » en texte vaut une absence', () {
      final avis = SecondOpinion.fromJson({
        'etiquette': 'null',
        'nom': '  ',
        'certitude': 'haute',
        'observation': 'Rien de net.',
        'ravageur_plutot_que_maladie': false,
        'raison_si_aucune': null,
      });

      expect(avis.label, isNull);
      expect(avis.name, isNull);
    });

    test('une certitude inattendue retombe sur la plus basse', () {
      // Mieux vaut sous-vendre une réponse juste que présenter une réponse
      // fausse comme sûre.
      expect(
        SecondOpinionCertainty.parse('très sûr'),
        SecondOpinionCertainty.low,
      );
      expect(SecondOpinionCertainty.parse(null), SecondOpinionCertainty.low);
    });
  });

  group('provider', () {
    late _MockSecondOpinionService service;
    late SecondOpinionProvider provider;

    setUp(() {
      service = _MockSecondOpinionService();
      provider = SecondOpinionProvider(service);
    });

    Future<void> demander() => provider.ask(
      imagePath: _photo,
      cropName: 'Tomate',
      catalog: const [(label: 'Tomato___Late_blight', name: 'Mildiou')],
    );

    test('sans service configuré, rien n\'est proposé', () async {
      final sansAcces = SecondOpinionProvider(null);

      expect(sansAcces.isAvailable, isFalse);
      await sansAcces.ask(imagePath: _photo, cropName: 'Tomate', catalog: []);
      expect(sansAcces.stateFor(_photo), isA<SecondOpinionIdle>());
    });

    test('une réponse obtenue devient un état prêt', () async {
      when(
        () => service.ask(
          imagePath: any(named: 'imagePath'),
          cropName: any(named: 'cropName'),
          catalog: any(named: 'catalog'),
        ),
      ).thenAnswer((_) async => _avis());

      await demander();

      final state = provider.stateFor(_photo);
      expect(state, isA<SecondOpinionReady>());
      expect((state as SecondOpinionReady).opinion.name, 'Mildiou');
    });

    test('une panne réseau devient un message lisible', () async {
      when(
        () => service.ask(
          imagePath: any(named: 'imagePath'),
          cropName: any(named: 'cropName'),
          catalog: any(named: 'catalog'),
        ),
      ).thenThrow(const NetworkException.secondOpinionUnavailable());

      await demander();

      final state = provider.stateFor(_photo);
      expect(state, isA<SecondOpinionError>());
      // Le diagnostic hors-ligne reste la promesse : le message le rappelle.
      expect((state as SecondOpinionError).message, contains('hors-ligne'));
    });

    test('un avis ne déborde pas sur la photo suivante', () async {
      when(
        () => service.ask(
          imagePath: any(named: 'imagePath'),
          cropName: any(named: 'cropName'),
          catalog: any(named: 'catalog'),
        ),
      ).thenAnswer((_) async => _avis());

      await demander();

      expect(provider.stateFor(_photo), isA<SecondOpinionReady>());
      // Nouveau diagnostic, nouvelle photo : l'avis précédent ne doit pas
      // rester affiché sous un résultat qui ne le concerne pas.
      expect(
        provider.stateFor('/tmp/autre_feuille.jpg'),
        isA<SecondOpinionIdle>(),
      );
    });
  });
}
