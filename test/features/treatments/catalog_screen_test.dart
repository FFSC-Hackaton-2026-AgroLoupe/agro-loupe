import 'package:agro_loupe/core/theme/app_theme.dart';
import 'package:agro_loupe/features/treatments/data/treatment_repository.dart';
import 'package:agro_loupe/features/treatments/state/treatment_provider.dart';
import 'package:agro_loupe/features/treatments/ui/screens/catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/sources_muettes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TreatmentProvider treatments;

  setUp(() async {
    treatments = TreatmentProvider(TreatmentRepository(remote: SourceMuette()));
    await treatments.load();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: treatments,
        child: MaterialApp(theme: AppTheme.light, home: const CatalogScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('le manioc est proposé en premier, avec ses six fiches', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Bactériose du manioc'), findsOneWidget);
    expect(find.text('Mosaïque africaine du manioc'), findsOneWidget);
    // Les fiches de tomate ne doivent pas apparaître sous le manioc.
    expect(find.text('Mildiou'), findsNothing);
  });

  testWidgets('changer de culture change la liste', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Tomate'));
    await tester.pump();

    expect(find.text('Mildiou'), findsOneWidget);
    expect(find.text('Bactériose du manioc'), findsNothing);
  });

  testWidgets('une fiche saine ne s\'annonce pas comme une maladie', (
    tester,
  ) async {
    await pump(tester);

    // La gravité « aucune » devient un libellé explicite : « Gravité aucune »
    // n'aurait aucun sens pour un agriculteur.
    expect(find.text('Plante saine'), findsWidgets);
  });

  testWidgets('appuyer sur une carte ouvre la fiche complète', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Bactériose du manioc'));
    await tester.pumpAndSettle();

    // On arrive directement sur les conseils : dans le catalogue on consulte,
    // il n'y a pas d'hypothèse à confirmer.
    expect(find.text('Ce que vous devriez voir'), findsOneWidget);
  });
}
