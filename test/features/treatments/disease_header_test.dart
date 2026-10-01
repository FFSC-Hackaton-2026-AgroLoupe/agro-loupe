import 'package:agro_loupe/core/theme/app_theme.dart';
import 'package:agro_loupe/core/theme/diagnosis_colors.dart';
import 'package:agro_loupe/features/treatments/data/treatment_repository.dart';
import 'package:agro_loupe/features/treatments/models/treatment.dart';
import 'package:agro_loupe/features/treatments/ui/screens/disease_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _cultures = {'manioc': 'Manioc', 'tomate': 'Tomate', 'maïs': 'Maïs'};

void main() {
  late List<Treatment> fiches;

  setUpAll(() async {
    final byLabel = await TreatmentRepository().loadAll();
    fiches = byLabel.values.toList();
  });

  Treatment une(String gravite) =>
      fiches.firstWhere((fiche) => fiche.severity == gravite);

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    final nom = theme.brightness == Brightness.dark ? 'sombre' : 'clair';
    final couleurs = theme.brightness == Brightness.dark
        ? DiagnosisColors.dark
        : DiagnosisColors.light;

    testWidgets('les trois gravités ont leur couleur en thème $nom', (
      tester,
    ) async {
      final attendues = {
        'élevée': couleurs.diseased,
        'moyenne': couleurs.uncertain,
        'aucune': couleurs.healthy,
      };

      for (final entry in attendues.entries) {
        final fiche = une(entry.key);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: DiseaseScreen(treatment: fiche),
          ),
        );

        expect(find.text(fiche.name), findsWidgets);
        expect(find.text(_cultures[fiche.crop]!), findsOneWidget);
        expect(find.text('Gravité'), findsOneWidget);

        final gravite = tester.widget<Text>(find.text(fiche.severity));
        expect(gravite.style?.color, entry.value);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
