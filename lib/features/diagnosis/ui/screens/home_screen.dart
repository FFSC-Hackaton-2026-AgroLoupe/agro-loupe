import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/connection_badge.dart';

/// Écran d'accueil : point de départ d'un diagnostic.
///
/// Provisoire : la prise de photo et l'analyse seront branchées lors de
/// l'implémentation de la fonctionnalité `diagnosis`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Column(
        children: [
          const ConnectionBadge(),
          const Expanded(child: _Introduction()),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: FilledButton.icon(
              onPressed: () => _notImplementedYet(context),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Prendre une photo'),
            ),
          ),
        ],
      ),
    );
  }

  void _notImplementedYet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Le diagnostic arrive bientôt.')),
    );
  }
}

/// Explication affichée tant qu'aucun diagnostic n'a été lancé.
class _Introduction extends StatelessWidget {
  const _Introduction();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, size: 96, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Photographiez une feuille',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "L'analyse se fait directement sur votre téléphone, "
              'même sans connexion internet.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
