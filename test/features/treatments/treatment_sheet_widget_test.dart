import 'package:agro_loupe/core/theme/app_theme.dart';
import 'package:agro_loupe/features/diagnosis/data/diagnosis_repository.dart';
import 'package:agro_loupe/core/services/photo_service.dart';
import 'package:agro_loupe/features/diagnosis/models/crop_profile.dart';
import 'package:agro_loupe/features/diagnosis/models/diagnosis.dart';
import 'package:agro_loupe/features/diagnosis/models/prediction.dart';
import 'package:agro_loupe/features/diagnosis/state/diagnosis_provider.dart';
import 'package:agro_loupe/features/diagnosis/ui/widgets/diagnosis_result_card.dart';
import 'package:agro_loupe/features/treatments/data/treatment_repository.dart';
import 'package:agro_loupe/features/treatments/state/treatment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockDiagnosisRepository extends Mock implements DiagnosisRepository {}

const _mildiou = 'Tomato___Late_blight';

Diagnosis _diagnosis() => Diagnosis(
  crop: Crop.tomato,
  imagePath: '/inexistant.jpg',
  predictions: const [
    Prediction(label: _mildiou, confidence: 0.894),
    Prediction(label: 'Tomato___Early_blight', confidence: 0.106),
  ],
  createdAt: DateTime(2026, 9, 26),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Crop.tomato);
    registerFallbackValue(PhotoSource.camera);
  });

  late TreatmentProvider treatments;
  late DiagnosisProvider diagnosis;
  late _MockDiagnosisRepository repository;

  setUp(() async {
    treatments = TreatmentProvider(TreatmentRepository());
    await treatments.load();

    repository = _MockDiagnosisRepository();
    when(() => repository.prepare(any())).thenAnswer((_) async {});
    when(
      () => repository.diagnose(
        crop: any(named: 'crop'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => _diagnosis());
    diagnosis = DiagnosisProvider(repository);
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    // Format téléphone : avec la fenêtre par défaut (800 × 600), la photo en
    // 4:3 remplit tout l'écran et le ListView ne construit jamais la suite.
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: treatments),
          ChangeNotifierProvider.value(value: diagnosis),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('avant confirmation : symptômes, mais aucun traitement', (
    tester,
  ) async {
    await pump(tester, DiagnosisResultCard(DiagnosisSuccess(_diagnosis())));

    expect(find.text('Mildiou'), findsOneWidget);
    expect(find.text('Ce que vous devriez voir'), findsOneWidget);
    expect(find.text('À ne pas confondre avec'), findsOneWidget);

    // Conseiller un produit sur une hypothèse non confirmée ferait traiter
    // la mauvaise maladie.
    expect(find.text('Traitement'), findsNothing);
    expect(find.text('Éviter que cela revienne'), findsNothing);
  });

  testWidgets('après confirmation : traitement et prévention affichés', (
    tester,
  ) async {
    await pump(
      tester,
      DiagnosisConfirmedCard(DiagnosisConfirmed(_diagnosis())),
    );

    expect(find.text('À faire maintenant'), findsOneWidget);
    expect(find.text('Traitement'), findsOneWidget);
    expect(find.text('Éviter que cela revienne'), findsOneWidget);
    expect(find.text('Quand demander conseil'), findsOneWidget);

    // Contenu réel de la fiche, pas seulement les titres.
    expect(find.textContaining('mancozèbe'), findsWidgets);
    expect(find.textContaining('tuteurer'), findsWidgets);
  });

  testWidgets('le parcours complet mène du résultat à la fiche', (
    tester,
  ) async {
    // Le provider doit réellement porter le résultat : c'est lui qui décide
    // de ce que fait le bouton « Oui ».
    await diagnosis.analyze(PhotoSource.camera);
    await pump(tester, const _Parcours());

    expect(find.text('Ce que vous devriez voir'), findsOneWidget);
    expect(find.text('Traitement'), findsNothing);

    // La confirmation est en bas de la fiche : il faut y défiler comme le
    // ferait l'utilisateur après avoir lu les symptômes.
    final oui = find.widgetWithText(FilledButton, 'Oui');
    await tester.scrollUntilVisible(oui, 200);
    // scrollUntilVisible s'arrête dès que le widget affleure : son centre peut
    // rester hors de la zone visible, et le tap ne touche alors rien.
    await tester.ensureVisible(oui);
    await tester.pumpAndSettle();
    await tester.tap(oui);
    await tester.pumpAndSettle();

    expect(diagnosis.state, isA<DiagnosisConfirmed>());
    expect(find.text('Traitement'), findsOneWidget);
    expect(find.text('Éviter que cela revienne'), findsOneWidget);
  });
}

/// Reproduit l'aiguillage de l'écran d'accueil entre les deux états concernés.
class _Parcours extends StatelessWidget {
  const _Parcours();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DiagnosisProvider>().state;
    return switch (state) {
      DiagnosisConfirmed() => DiagnosisConfirmedCard(state),
      DiagnosisSuccess() => DiagnosisResultCard(state),
      _ => const SizedBox.shrink(),
    };
  }
}
