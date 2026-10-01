import 'package:agro_loupe/core/theme/app_theme.dart';
import 'package:agro_loupe/features/history/ui/widgets/history_empty.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FilledButton.icon` construit `_FilledButtonWithIcon`, une sous-classe :
/// `find.byType(FilledButton)` compare le type exact et ne la trouve pas.
/// Le même piège est documenté dans `test/widget_test.dart`.
final boutonRempli = find.byWidgetPredicate(
  (widget) => widget is FilledButton,
  description: 'bouton rempli, avec ou sans icône',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpEmpty(
    WidgetTester tester, {
    VoidCallback? onAction,
    String? actionLabel,
    Size size = const Size(400, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Scaffold(
          body: HistoryEmpty(
            onAction: onAction,
            actionLabel: actionLabel ?? 'Lancer un diagnostic',
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'affiche les messages explicatifs et l’icône sans bouton par défaut',
    (tester) async {
      await pumpEmpty(tester);

      expect(find.byIcon(Icons.history_toggle_off_outlined), findsOneWidget);
      expect(find.text('Aucun diagnostic pour l’instant'), findsOneWidget);
      expect(
        find.textContaining('Vos analyses de feuilles apparaîtront ici'),
        findsOneWidget,
      );
      expect(boutonRempli, findsNothing);
    },
  );

  testWidgets('affiche le bouton d’action et répond au clic', (tester) async {
    var clique = false;
    await pumpEmpty(
      tester,
      onAction: () => clique = true,
      actionLabel: 'Photographier une feuille',
    );

    final bouton = find.ancestor(
      of: find.text('Photographier une feuille'),
      matching: boutonRempli,
    );
    expect(bouton, findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);

    await tester.tap(bouton);
    await tester.pump();

    expect(clique, isTrue);
  });

  for (final taille in const [
    Size(320, 568), // Petit téléphone
    Size(360, 640), // Standard entrée de gamme
    Size(411, 731), // Milieu de gamme
  ]) {
    testWidgets(
      'reste parfaitement lisible sans overflow en ${taille.width.toInt()}x${taille.height.toInt()}',
      (tester) async {
        await pumpEmpty(tester, size: taille, onAction: () {});

        expect(find.text('Aucun diagnostic pour l’instant'), findsOneWidget);
        expect(boutonRempli, findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
