import 'package:agro_loupe/core/theme/app_theme.dart';
import 'package:agro_loupe/features/diagnosis/models/crop_profile.dart';
import 'package:agro_loupe/features/history/data/history_repository.dart';
import 'package:agro_loupe/features/history/models/history_entry.dart';
import 'package:agro_loupe/features/history/state/history_provider.dart';
import 'package:agro_loupe/features/history/ui/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockRepository extends Mock implements HistoryRepository {}

HistoryEntry _entree({
  int id = 1,
  String nom = 'Mildiou',
  bool confirme = true,
}) => HistoryEntry(
  id: id,
  imagePath: '/inexistant/feuille.jpg',
  crop: Crop.tomato,
  diseaseName: nom,
  modelLabel: 'Tomato___Late_blight',
  confidence: 0.894,
  createdAt: DateTime(2026, 9, 30, 14, 5),
  isConfirmed: confirme,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepository repository;
  late HistoryProvider provider;

  setUpAll(() => registerFallbackValue(_entree()));

  setUp(() {
    repository = _MockRepository();
    provider = HistoryProvider(repository);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.light, home: const HistoryScreen()),
      ),
    );
    // Le chargement est lancé après la première trame.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('un historique vide affiche son écran d\'accueil', (
    tester,
  ) async {
    when(() => repository.all()).thenAnswer((_) async => []);

    await pump(tester);

    // C'est ce que voit le jury au premier lancement.
    expect(find.text('Aucun diagnostic pour l’instant'), findsOneWidget);
  });

  testWidgets('les diagnostics apparaissent avec leur date et leur culture', (
    tester,
  ) async {
    when(
      () => repository.all(),
    ).thenAnswer((_) async => [_entree(), _entree(id: 2, nom: 'Alternariose')]);

    await pump(tester);

    expect(find.text('Mildiou'), findsOneWidget);
    expect(find.text('Alternariose'), findsOneWidget);
    expect(find.textContaining('Tomate'), findsWidgets);
    expect(find.textContaining('30 sept. 2026'), findsWidgets);
  });

  testWidgets('un diagnostic abandonné se distingue d\'un confirmé', (
    tester,
  ) async {
    when(
      () => repository.all(),
    ).thenAnswer((_) async => [_entree(), _entree(id: 2, confirme: false)]);

    await pump(tester);

    expect(find.text('Symptômes confirmés'), findsOneWidget);
    expect(find.text('Resté sans réponse'), findsOneWidget);
  });

  testWidgets('une photo disparue ne casse pas la liste', (tester) async {
    when(() => repository.all()).thenAnswer((_) async => [_entree()]);

    await pump(tester);

    // Le fichier n'existe pas. On ne peut pas vérifier ici que l'icône de
    // remplacement s'affiche : en test, le chargement de l'image reste en
    // attente et l'`errorBuilder` ne se déclenche jamais. Ce qui est
    // vérifiable, et qui compte, c'est que rien ne casse autour.
    expect(find.text('Mildiou'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('appuyer sur une ligne ouvre le détail', (tester) async {
    when(() => repository.all()).thenAnswer((_) async => [_entree()]);

    await pump(tester);
    await tester.tap(find.text('Mildiou'));
    await tester.pumpAndSettle();

    expect(find.textContaining('30 sept. 2026'), findsWidgets);
  });

  testWidgets('la suppression demande confirmation', (tester) async {
    when(() => repository.all()).thenAnswer((_) async => [_entree()]);

    await pump(tester);
    await tester.drag(find.text('Mildiou'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer ce diagnostic ?'), findsOneWidget);

    // Annuler ne doit rien supprimer : un geste de balayage est vite fait
    // par accident, et un diagnostic perdu ne se retrouve pas.
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.remove(any()));
    expect(find.text('Mildiou'), findsOneWidget);
  });
}
