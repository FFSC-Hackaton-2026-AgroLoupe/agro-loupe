import 'package:agro_loupe/core/errors/app_exception.dart';
import 'package:agro_loupe/core/services/photo_service.dart';
import 'package:agro_loupe/features/diagnosis/data/diagnosis_repository.dart';
import 'package:agro_loupe/features/diagnosis/models/crop_profile.dart';
import 'package:agro_loupe/features/diagnosis/models/diagnosis.dart';
import 'package:agro_loupe/features/diagnosis/models/prediction.dart';
import 'package:agro_loupe/features/diagnosis/state/diagnosis_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements DiagnosisRepository {}

Diagnosis _diagnosis({int hypotheses = 3}) => Diagnosis(
  crop: Crop.tomato,
  imagePath: '/tmp/feuille.jpg',
  predictions: [
    for (var i = 0; i < hypotheses; i++)
      Prediction(label: 'Tomato___maladie_$i', confidence: 0.9 - i * 0.3),
  ],
  createdAt: DateTime(2026, 9, 26),
);

void main() {
  late _MockRepository repository;
  late DiagnosisProvider provider;

  setUpAll(() {
    registerFallbackValue(Crop.cassava);
    registerFallbackValue(PhotoSource.camera);
  });

  setUp(() {
    repository = _MockRepository();
    when(() => repository.prepare(any())).thenAnswer((_) async {});
    provider = DiagnosisProvider(repository);
  });

  group('analyse', () {
    test('part au repos, sur le manioc', () {
      expect(provider.state, isA<DiagnosisIdle>());
      expect(provider.crop, Crop.cassava);
    });

    test('passe par un état d\'analyse avant le résultat', () async {
      when(
        () => repository.diagnose(
          crop: any(named: 'crop'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => _diagnosis());

      final vus = <DiagnosisState>[];
      provider.addListener(() => vus.add(provider.state));

      await provider.analyze(PhotoSource.camera);

      expect(vus.first, isA<DiagnosisAnalyzing>());
      expect(vus.last, isA<DiagnosisSuccess>());
    });

    test('revient au repos si l\'utilisateur annule la photo', () async {
      when(
        () => repository.diagnose(
          crop: any(named: 'crop'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => null);

      await provider.analyze(PhotoSource.gallery);

      expect(provider.state, isA<DiagnosisIdle>());
    });

    test('transforme une erreur métier en message affichable', () async {
      when(
        () => repository.diagnose(
          crop: any(named: 'crop'),
          source: any(named: 'source'),
        ),
      ).thenThrow(const PhotoException.permissionDenied());

      await provider.analyze(PhotoSource.camera);

      final state = provider.state;
      expect(state, isA<DiagnosisError>());
      expect((state as DiagnosisError).message, contains('caméra'));
    });
  });

  group('confirmation par symptômes', () {
    setUp(() {
      when(
        () => repository.diagnose(
          crop: any(named: 'crop'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => _diagnosis());
    });

    test('un rejet propose l\'hypothèse suivante', () async {
      await provider.analyze(PhotoSource.camera);
      expect((provider.state as DiagnosisSuccess).shownIndex, 0);

      provider.rejectCurrent();

      final state = provider.state as DiagnosisSuccess;
      expect(state.shownIndex, 1);
      expect(state.isFallback, isTrue);
      expect(state.prediction.label, 'Tomato___maladie_1');
    });

    test(
      'rejeter toutes les hypothèses oriente vers un agent agricole',
      () async {
        await provider.analyze(PhotoSource.camera);

        provider.rejectCurrent();
        provider.rejectCurrent();
        expect((provider.state as DiagnosisSuccess).hasNext, isFalse);

        provider.rejectCurrent();

        expect(provider.state, isA<DiagnosisExhausted>());
      },
    );

    test('confirmer ouvre la fiche de traitement', () async {
      await provider.analyze(PhotoSource.camera);

      provider.confirmCurrent();

      final state = provider.state;
      expect(state, isA<DiagnosisConfirmed>());
      expect(
        (state as DiagnosisConfirmed).prediction.label,
        'Tomato___maladie_0',
      );
    });

    test('confirmer la deuxième hypothèse retient bien celle-là', () async {
      await provider.analyze(PhotoSource.camera);
      provider.rejectCurrent();

      provider.confirmCurrent();

      final state = provider.state as DiagnosisConfirmed;
      expect(state.prediction.label, 'Tomato___maladie_1');
    });

    test('une confirmation hors résultat ne fait rien', () {
      provider.confirmCurrent();
      expect(provider.state, isA<DiagnosisIdle>());
    });

    test('un rejet hors résultat ne fait rien', () {
      provider.rejectCurrent();
      expect(provider.state, isA<DiagnosisIdle>());
    });
  });

  group('choix de la culture', () {
    test('efface le résultat précédent et précharge le modèle', () async {
      when(
        () => repository.diagnose(
          crop: any(named: 'crop'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => _diagnosis());
      await provider.analyze(PhotoSource.camera);
      expect(provider.state, isA<DiagnosisSuccess>());

      provider.selectCrop(Crop.maize);

      // Un résultat de tomate n'a aucun sens une fois passé au maïs.
      expect(provider.state, isA<DiagnosisIdle>());
      expect(provider.crop, Crop.maize);
      expect(provider.profile.labelPrefix, 'Corn_');
      verify(() => repository.prepare(Crop.maize)).called(1);
    });

    test('rechoisir la même culture ne réinitialise rien', () async {
      when(
        () => repository.diagnose(
          crop: any(named: 'crop'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => _diagnosis());
      await provider.analyze(PhotoSource.camera);

      provider.selectCrop(Crop.cassava);

      expect(provider.state, isA<DiagnosisSuccess>());
      verifyNever(() => repository.prepare(any()));
    });
  });
}
