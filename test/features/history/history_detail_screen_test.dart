import 'package:agro_loupe/core/theme/app_theme.dart';
import 'package:agro_loupe/features/diagnosis/models/crop_profile.dart';
import 'package:agro_loupe/features/history/models/history_entry.dart';
import 'package:agro_loupe/features/history/ui/screens/history_detail_screen.dart';
import 'package:agro_loupe/features/treatments/models/treatment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Treatment _fakeTreatment() => const Treatment(
  id: 'tomate_mildiou',
  modelLabel: 'Tomato___Late_blight',
  crop: 'tomate',
  name: 'Mildiou de la tomate',
  severity: 'élevée',
  symptoms: ['Grandes taches brunes et humides sur les feuilles.'],
  confusions: ['Alternariose (taches en cercles concentriques).'],
  culturalPractices: [
    'Arracher et brûler les feuilles les plus atteintes.',
    'Arroser au pied sans mouiller le feuillage.',
  ],
  chemicalTreatment: [
    'Bouillie bordelaise (cuivre) en préventif.',
    'Fongicide à base de mancozèbe en curatif.',
  ],
  prevention: ['Espacer les plants pour une bonne aération.'],
  whenToConsult: 'Si plus de la moitié de la parcelle est touchée.',
  note: 'Maladie fulgurante par temps humide.',
);

HistoryEntry _confirmedEntry({Treatment? treatment}) => HistoryEntry(
  id: 1,
  imagePath: '/chemin/inexistant/photo.jpg',
  crop: Crop.tomato,
  diseaseName: 'Mildiou de la tomate',
  modelLabel: 'Tomato___Late_blight',
  confidence: 0.88,
  createdAt: DateTime(2026, 9, 26, 14, 30),
  isConfirmed: true,
  treatment: treatment ?? _fakeTreatment(),
);

HistoryEntry _abandonedEntry() => HistoryEntry(
  id: 2,
  imagePath: '/chemin/inexistant/photo_rejetee.jpg',
  crop: Crop.cassava,
  diseaseName: 'Mosaïque du manioc',
  modelLabel: 'cgm',
  confidence: 0.54,
  createdAt: DateTime(2026, 9, 28, 9, 15),
  isConfirmed: false,
  treatment: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryEntry Model', () {
    test('instanciation et calculs de base', () {
      final entry = _confirmedEntry();

      expect(entry.percent, 88);
      expect(entry.cropDisplayName, 'Tomate');
      expect(entry.formattedDate, '26 sept. 2026 à 14:30');
    });

    test('sérialisation et désérialisation JSON / SQLite', () {
      final entry = _confirmedEntry();
      final json = entry.toJson();

      expect(json['id'], 1);
      expect(json['crop'], 'tomato');
      expect(json['diseaseName'], 'Mildiou de la tomate');
      expect(json['isConfirmed'], 1);

      final restored = HistoryEntry.fromJson(json, treatment: _fakeTreatment());
      expect(restored.id, entry.id);
      expect(restored.crop, entry.crop);
      expect(restored.diseaseName, entry.diseaseName);
      expect(restored.isConfirmed, isTrue);
      expect(restored.treatment?.name, 'Mildiou de la tomate');
    });

    test('copyWith modifie les champs ciblés', () {
      final entry = _confirmedEntry();
      final updated = entry.copyWith(isConfirmed: false, confidence: 0.40);

      expect(updated.id, entry.id);
      expect(updated.isConfirmed, isFalse);
      expect(updated.confidence, 0.40);
      expect(updated.percent, 40);
    });
  });

  group('HistoryDetailScreen Widget', () {
    Future<void> pumpScreen(WidgetTester tester, HistoryEntry entry) async {
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: HistoryDetailScreen(entry: entry),
        ),
      );
      await tester.pump();
    }

    testWidgets('affiche les détails complets pour un diagnostic confirmé', (
      tester,
    ) async {
      await pumpScreen(tester, _confirmedEntry());

      expect(find.text('Détail du diagnostic'), findsOneWidget);
      expect(find.text('Tomate'), findsOneWidget);
      expect(find.text('Diagnostic confirmé'), findsOneWidget);
      expect(find.text('Mildiou de la tomate'), findsOneWidget);
      expect(find.text('26 sept. 2026 à 14:30'), findsOneWidget);
      expect(find.text('88 %'), findsOneWidget);

      expect(find.text('À faire maintenant'), findsOneWidget);
      expect(find.text('Traitement'), findsOneWidget);
      expect(find.text('Éviter que cela revienne'), findsOneWidget);
      expect(find.text('Quand demander conseil'), findsOneWidget);
      expect(find.textContaining('Bouillie bordelaise'), findsOneWidget);
    });

    testWidgets('affiche le message d’abandon sans fiche de traitement', (
      tester,
    ) async {
      await pumpScreen(tester, _abandonedEntry());

      expect(find.text('Manioc'), findsOneWidget);
      expect(find.text('Diagnostic non retenu'), findsWidgets);
      expect(find.text('Mosaïque du manioc'), findsOneWidget);
      expect(find.text('28 sept. 2026 à 09:15'), findsOneWidget);
      expect(
        find.textContaining('Vous aviez indiqué que les symptômes'),
        findsOneWidget,
      );

      // Aucun traitement conseillé sur une hypothèse rejetée par l'agriculteur.
      expect(find.text('À faire maintenant'), findsNothing);
      expect(find.text('Traitement'), findsNothing);
      expect(find.text('Éviter que cela revienne'), findsNothing);
    });

    testWidgets('gère proprement une photo locale supprimée ou introuvable', (
      tester,
    ) async {
      await pumpScreen(tester, _confirmedEntry());

      // L'image n'existant pas sur disque, le fallback errorBuilder doit s'afficher
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(
        find.text('Photo non disponible sur cet appareil'),
        findsOneWidget,
      );
    });

    testWidgets('affiche le conseil agricole si la fiche est absente', (
      tester,
    ) async {
      final entrySansFiche = HistoryEntry(
        id: 3,
        imagePath: '/chemin/inexistant/photo.jpg',
        crop: Crop.tomato,
        diseaseName: 'Maladie rare',
        modelLabel: 'Tomato___Rare',
        confidence: 0.75,
        createdAt: DateTime(2026, 9, 26, 14, 30),
        isConfirmed: true,
        treatment: null,
      );
      await pumpScreen(tester, entrySansFiche);

      expect(find.text('Diagnostic confirmé'), findsOneWidget);
      expect(find.text('Fiche non disponible'), findsOneWidget);
      expect(
        find.textContaining('Montrez votre plant à un conseiller agricole'),
        findsOneWidget,
      );
    });
  });
}
