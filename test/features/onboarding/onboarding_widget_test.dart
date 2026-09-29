import 'package:agro_loupe/app.dart';
import 'package:agro_loupe/core/services/connectivity_service.dart';
import 'package:agro_loupe/features/onboarding/data/onboarding_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockConnectivityService extends Mock implements ConnectivityService {}

const _accueil = 'Photographiez une feuille';

void main() {
  late _MockConnectivityService connectivity;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    connectivity = _MockConnectivityService();
    when(
      () => connectivity.onStatusChanged,
    ).thenAnswer((_) => const Stream<ConnectionStatus>.empty());
  });

  /// [tuto] coupe le voile : la plupart des tests veulent l'application nue.
  Future<void> pumpApp(
    WidgetTester tester, {
    required bool onboarding,
    bool tuto = false,
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AgroLoupeApp(
        connectivityService: connectivity,
        showOnboarding: onboarding,
        showCoachMarks: tuto,
      ),
    );
    await tester.pump();
  }

  testWidgets('au premier lancement, la présentation passe avant tout', (
    tester,
  ) async {
    await pumpApp(tester, onboarding: true);

    expect(find.text('Photographiez une feuille'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
    // Personne ne doit être retenu devant un écran d'explication.
    expect(find.text('Passer'), findsOneWidget);
  });

  testWidgets('les trois pages se suivent et mènent à Commencer', (
    tester,
  ) async {
    await pumpApp(tester, onboarding: true);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Sans connexion'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Que faire ensuite'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
    expect(find.text('Suivant'), findsNothing);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    // On arrive sur le diagnostic, pas sur un menu : c'est l'usage principal.
    expect(find.text(_accueil), findsOneWidget);
  });

  testWidgets('« Passer » mène directement à l\'application', (tester) async {
    await pumpApp(tester, onboarding: true);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(find.text(_accueil), findsOneWidget);
  });

  testWidgets('une fois vue, la présentation ne revient pas', (tester) async {
    await pumpApp(tester, onboarding: false);

    expect(find.text('Passer'), findsNothing);
    expect(find.text(_accueil), findsOneWidget);
  });

  group('mémorisation', () {
    test('rien au départ, puis vue', () async {
      const storage = OnboardingStorage();

      expect(await storage.hasSeen(), isFalse);
      await storage.markSeen();
      expect(await storage.hasSeen(), isTrue);
    });
  });

  group('tutoriel', () {
    testWidgets('les bulles désignent la culture, la photo, puis les onglets', (
      tester,
    ) async {
      await pumpApp(tester, onboarding: false, tuto: true);
      await tester.pumpAndSettle();

      expect(find.text('1 sur 3'), findsOneWidget);
      expect(find.text('Choisissez votre culture'), findsOneWidget);

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('2 sur 3'), findsOneWidget);

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Vos trois onglets'), findsOneWidget);
      expect(find.text("J'ai compris"), findsOneWidget);

      await tester.tap(find.text("J'ai compris"));
      await tester.pumpAndSettle();

      expect(find.text('1 sur 3'), findsNothing);
    });

    testWidgets('« Passer » ferme le tutoriel immédiatement', (tester) async {
      await pumpApp(tester, onboarding: false, tuto: true);
      await tester.pumpAndSettle();

      expect(find.text('Choisissez votre culture'), findsOneWidget);

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      // Un utilisateur qui ne comprend pas ce qu'on lui montre doit pouvoir
      // en sortir d'un geste.
      expect(find.text('Choisissez votre culture'), findsNothing);
      expect(find.text('Quelle culture ?'), findsOneWidget);
    });

    testWidgets('une fois vu, le tutoriel ne revient pas', (tester) async {
      SharedPreferences.setMockInitialValues({
        OnboardingStorage.coachAccueil: true,
        OnboardingStorage.coachConfirmation: true,
      });
      await pumpApp(tester, onboarding: false, tuto: true);
      await tester.pumpAndSettle();

      expect(find.text('1 sur 3'), findsNothing);
    });

    testWidgets('« Revoir le tutoriel » le rejoue à la demande', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        OnboardingStorage.coachAccueil: true,
        OnboardingStorage.coachConfirmation: true,
      });
      await pumpApp(tester, onboarding: false, tuto: true);
      await tester.pumpAndSettle();
      expect(find.text('1 sur 3'), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revoir le tutoriel'));
      await tester.pumpAndSettle();

      expect(find.text('1 sur 3'), findsOneWidget);
      expect(find.text('Choisissez votre culture'), findsOneWidget);
    });

    testWidgets('la fiche photo s’ouvre depuis le même menu', (tester) async {
      await pumpApp(tester, onboarding: false);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('La bonne photo'));
      await tester.pumpAndSettle();

      expect(find.text('La photo décide du résultat'), findsOneWidget);
      expect(find.text('Une seule feuille'), findsOneWidget);
    });
  });
}
