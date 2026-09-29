import 'package:flutter/material.dart';

/// Historique local des diagnostics.
///
/// Écran provisoire. À remplacer par la liste des diagnostics passés, du plus
/// récent au plus ancien — tâche H1 de Hannatou. La couche sqflite et le
/// `HistoryProvider` sont fournis à part : cet écran n'aura qu'à lire l'état
/// et l'afficher.
///
/// La coquille n'a pas à être modifiée : seul le contenu de ce fichier
/// change.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: Center(
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
      ),
    );
  }
}
