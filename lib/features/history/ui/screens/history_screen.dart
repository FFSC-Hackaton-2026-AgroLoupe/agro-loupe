import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_bar_title.dart';
import '../../state/history_provider.dart';
import '../widgets/history_empty.dart';

/// Historique local des diagnostics.
///
/// L'état vide et l'écran de détail sont écrits ; **la liste reste à faire**
/// — c'est la tâche H1 de Hannatou. `HistoryProvider` lui fournit déjà les
/// entrées triées, du plus récent au plus ancien : il n'y a qu'à remplacer
/// le bloc marqué ci-dessous par la liste.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Rechargé à chaque ouverture de l'onglet : un diagnostic a pu être
    // enregistré depuis la dernière fois.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HistoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HistoryProvider>().state;

    return Scaffold(
      appBar: AppBar(title: const AppBarTitle('Historique')),
      body: switch (state) {
        HistoryLoading() => const Center(child: CircularProgressIndicator()),
        HistoryError(:final message) => _Erreur(message: message),
        HistoryReady(isEmpty: true) => const HistoryEmpty(),
        HistoryReady(:final entries) => _AFaire(nombre: entries.length),
      },
    );
  }
}

/// Emplacement de la liste, en attendant la tâche H1.
class _AFaire extends StatelessWidget {
  const _AFaire({required this.nombre});

  final int nombre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '$nombre diagnostic${nombre > 1 ? 's' : ''} enregistré'
              '${nombre > 1 ? 's' : ''}',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "L'affichage de la liste est en cours de construction.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Erreur extends StatelessWidget {
  const _Erreur({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
