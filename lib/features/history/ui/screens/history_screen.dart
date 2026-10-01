import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_bar_title.dart';
import '../../state/history_provider.dart';
import '../widgets/history_tile.dart';

/// Historique local des diagnostics, du plus récent au plus ancien.
///
/// Lit `HistoryProvider` : dès qu'un diagnostic est confirmé ou abandonné
/// côté onglet Diagnostic (`record()`), l'écran se reconstruit tout seul
/// via `notifyListeners()` — pas besoin de relancer l'application.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Filet de sécurité : si l'écran est affiché avant que le chargement
    // initial ait été déclenché ailleurs, on le déclenche ici.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HistoryProvider>();
      if (provider.state is HistoryLoading) {
        provider.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<HistoryProvider>().state;

    return Scaffold(
      appBar: AppBar(title: const AppBarTitle('Historique')),
      body: switch (state) {
        HistoryLoading() => const Center(child: CircularProgressIndicator()),
        HistoryError(:final message) =>
          _ErrorState(theme: theme, message: message),
        HistoryReady(:final entries) =>
          entries.isEmpty
              ? _EmptyState(theme: theme)
              : _HistoryList(entries: entries),
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries});

  final List<dynamic> entries;

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 88, endIndent: 16),
      itemBuilder: (context, index) => HistoryTile(entry: sorted[index]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 20),
            Text(
              'Vos diagnostics passés',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ils resteront sur votre téléphone, consultables sans '
              'connexion.',
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.theme, required this.message});

  final ThemeData theme;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<HistoryProvider>().load(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}