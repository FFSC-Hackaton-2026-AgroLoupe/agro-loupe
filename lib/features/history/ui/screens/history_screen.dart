import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_bar_title.dart';
import '../../state/history_provider.dart';
import '../../models/history_entry.dart';
import '../widgets/history_empty.dart';
import '../widgets/history_tile.dart';
import 'history_detail_screen.dart';

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
        HistoryReady(:final entries) => _Liste(entries: entries),
      },
    );
  }
}

/// Liste des diagnostics, du plus récent au plus ancien.
class _Liste extends StatelessWidget {
  const _Liste({required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final entry = entries[i];
        return Dismissible(
          key: ValueKey(entry.id ?? entry.createdAt.toIso8601String()),
          // Dans un seul sens : un balayage vers la droite est le geste de
          // retour sur Android, le confondre avec une suppression ferait
          // perdre des diagnostics par accident.
          direction: DismissDirection.endToStart,
          background: const _FondSuppression(),
          confirmDismiss: (_) => _confirmer(context),
          onDismissed: (_) => context.read<HistoryProvider>().remove(entry),
          child: HistoryTile(
            entry: entry,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HistoryDetailScreen(entry: entry),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmer(BuildContext context) async {
    final supprimer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce diagnostic ?'),
        content: const Text(
          'Il sera retiré de votre historique. La photo reste sur votre '
          'téléphone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return supprimer ?? false;
  }
}

class _FondSuppression extends StatelessWidget {
  const _FondSuppression();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
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
