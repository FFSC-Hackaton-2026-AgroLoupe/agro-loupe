import 'package:agro_loupe/features/treatments/data/treatment_repository.dart';
import 'package:agro_loupe/features/treatments/models/treatment.dart';
import 'package:agro_loupe/features/treatments/ui/screens/disease_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Treatment> fiches;

  setUpAll(() async {
    final byLabel = await TreatmentRepository().loadAll();
    fiches = byLabel.values.toList();
  });

  test('les vingt fiches sont chargées', () {
    expect(fiches, hasLength(20));
  });

  testWidgets('chaque fiche s\'ouvre avec son nom et un retour', (
    tester,
  ) async {
    for (final fiche in fiches) {
      await tester.pumpWidget(
        MaterialApp(home: DiseaseScreen(treatment: fiche)),
      );

      expect(find.text(fiche.name), findsWidgets);
      expect(find.byTooltip('Retour'), findsOneWidget);

      final titre = tester.widget<Text>(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(fiche.name),
        ),
      );
      expect(titre.maxLines, 1);
      expect(titre.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'les trois plantes saines s\'ouvrent sans proposer de traitement',
    (tester) async {
      final saines = fiches
          .where((fiche) => fiche.id.endsWith('_sain'))
          .toList();
      expect(saines, hasLength(3));

      for (final fiche in saines) {
        await tester.pumpWidget(
          MaterialApp(home: DiseaseScreen(treatment: fiche)),
        );

        expect(
          find.textContaining("Aucun traitement n'est justifié"),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('une fiche complète montre tous les conseils', (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final fiche = fiches.firstWhere((item) => item.id == 'manioc_bacteriose');
    await tester.pumpWidget(MaterialApp(home: DiseaseScreen(treatment: fiche)));

    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('Gravité'),
      ),
      findsNothing,
    );

    const titres = [
      'Ce que vous devriez voir',
      'À ne pas confondre avec',
      'À faire maintenant',
      'Traitement',
      'Éviter que cela revienne',
      'Quand demander conseil',
    ];
    for (final titre in titres) {
      await tester.scrollUntilVisible(find.text(titre), 200);
      expect(find.text(titre), findsOneWidget);
    }
    expect(find.text('Gravité'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
