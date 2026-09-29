import 'package:agro_loupe/app.dart';
import 'package:agro_loupe/core/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivityService extends Mock implements ConnectivityService {}

/// `FilledButton.icon` construit une sous-classe de [FilledButton] : un
/// `find.byType` échouerait, car il compare le type exact.
final photoButton = find.byWidgetPredicate(
  (widget) => widget is FilledButton,
  description: 'bouton « Photographier »',
);

void main() {
  late _MockConnectivityService connectivity;

  setUp(() {
    connectivity = _MockConnectivityService();
    // L'application ne doit jamais toucher au canal natif pendant un test.
    when(
      () => connectivity.onStatusChanged,
    ).thenAnswer((_) => const Stream<ConnectionStatus>.empty());
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      // Sans cela, le voile du tutoriel se poserait par-dessus l'écran et
      // avalerait les appuis : ces tests veulent l'application nue.
      AgroLoupeApp(connectivityService: connectivity, showCoachMarks: false),
    );
    await tester.pump();
  }

  testWidgets("l'accueil invite à photographier une feuille", (tester) async {
    await pumpApp(tester);

    expect(find.text('AgroLoupe'), findsOneWidget);
    expect(find.text('Photographiez une feuille'), findsOneWidget);
    expect(photoButton, findsOneWidget);
    expect(find.text('Photographier'), findsOneWidget);
  });

  testWidgets('aucun bandeau hors-ligne tant que le réseau est là', (
    tester,
  ) async {
    when(
      () => connectivity.onStatusChanged,
    ).thenAnswer((_) => Stream.value(ConnectionStatus.online));

    await pumpApp(tester);

    expect(find.byIcon(Icons.cloud_off), findsNothing);
  });

  testWidgets('le bandeau hors-ligne apparaît sans bloquer le bouton', (
    tester,
  ) async {
    when(
      () => connectivity.onStatusChanged,
    ).thenAnswer((_) => Stream.value(ConnectionStatus.offline));

    await pumpApp(tester);

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    // Le diagnostic reste accessible : c'est la promesse produit.
    final button = tester.widget<FilledButton>(photoButton);
    expect(button.onPressed, isNotNull);
  });

  // Les boutons sont l'action principale : les atteindre ne doit jamais
  // demander de faire défiler l'écran. Une régression l'avait rendu
  // nécessaire sur petit téléphone, sans qu'aucun test ne l'attrape.
  for (final taille in const [
    Size(320, 568), // petit téléphone
    Size(360, 640), // entrée de gamme courant
    Size(411, 731), // milieu de gamme
  ]) {
    testWidgets('les boutons restent visibles en ${taille.width.toInt()}'
        'x${taille.height.toInt()}', (tester) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpApp(tester);

      final bouton = tester.getRect(photoButton);
      expect(
        bouton.bottom,
        lessThanOrEqualTo(taille.height),
        reason: "le bouton dépasse le bas de l'écran",
      );
      expect(bouton.top, greaterThanOrEqualTo(0));
      expect(find.text('Galerie'), findsOneWidget);
    });
  }
}
