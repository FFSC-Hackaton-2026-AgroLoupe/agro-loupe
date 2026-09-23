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
  description: 'bouton « Prendre une photo »',
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
    await tester.pumpWidget(AgroLoupeApp(connectivityService: connectivity));
    await tester.pump();
  }

  testWidgets("l'accueil invite à photographier une feuille", (tester) async {
    await pumpApp(tester);

    expect(find.text('AgroLoupe'), findsOneWidget);
    expect(find.text('Photographiez une feuille'), findsOneWidget);
    expect(photoButton, findsOneWidget);
    expect(find.text('Prendre une photo'), findsOneWidget);
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
}
