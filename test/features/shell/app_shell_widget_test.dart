import 'package:agro_loupe/app.dart';
import 'package:agro_loupe/core/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivityService extends Mock implements ConnectivityService {}

/// Repères pris dans le corps des écrans, pas sur les libellés de la barre :
/// une fois un onglet ouvert, son nom apparaît deux fois — dans la barre et
/// dans le titre — et l'assertion deviendrait ambiguë.
const _accueil = 'Photographiez une feuille';

/// Le titre de l'onglet Catalogue dans sa barre, et non le libellé de la
/// barre de navigation, qui porte le même mot.
final _catalogue = find.ancestor(
  of: find.text('Catalogue'),
  matching: find.byType(AppBar),
);

/// Le titre de l'onglet Historique, dans sa barre — et non le libellé de la
/// barre de navigation, qui porte le même mot.
final _historique = find.ancestor(
  of: find.text('Historique'),
  matching: find.byType(AppBar),
);

void main() {
  late _MockConnectivityService connectivity;

  setUp(() {
    connectivity = _MockConnectivityService();
    when(
      () => connectivity.onStatusChanged,
    ).thenAnswer((_) => const Stream<ConnectionStatus>.empty());
  });

  /// Une pulsation bornée plutôt que `pumpAndSettle` : tant que les fiches
  /// se chargent, le catalogue affiche un indicateur circulaire, dont
  /// l'animation ne s'arrête jamais — `pumpAndSettle` expirerait.
  Future<void> battre(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 50));

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      // Sans cela, le voile du tutoriel se poserait par-dessus l'écran et
      // avalerait les appuis : ces tests veulent l'application nue.
      AgroLoupeApp(connectivityService: connectivity, showCoachMarks: false),
    );
    await tester.pump();
  }

  testWidgets('les trois onglets sont accessibles', (tester) async {
    await pumpApp(tester);

    // Le diagnostic est l'onglet d'accueil : c'est la promesse du produit.
    expect(find.text(_accueil), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await battre(tester);
    expect(_catalogue, findsOneWidget);
    expect(find.text(_accueil), findsNothing);

    await tester.tap(find.byIcon(Icons.history_outlined));
    await battre(tester);
    expect(_historique, findsOneWidget);

    await tester.tap(find.byIcon(Icons.eco_outlined));
    await battre(tester);
    expect(find.text(_accueil), findsOneWidget);
  });

  testWidgets('le retour depuis un autre onglet ramène au diagnostic', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await battre(tester);
    expect(_catalogue, findsOneWidget);

    // Bouton retour du téléphone : il doit revenir au diagnostic plutôt que
    // de quitter l'application.
    await tester.binding.handlePopRoute();
    await battre(tester);

    expect(find.text(_accueil), findsOneWidget);
    expect(_catalogue, findsNothing);
  });
}
