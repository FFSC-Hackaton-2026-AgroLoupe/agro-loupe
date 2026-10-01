import 'package:flutter/material.dart';

/// Vue d'accueil affichée lorsque l'historique ne contient aucun diagnostic.
///
/// Évite un écran vide au premier lancement et rappelle à l'agriculteur que
/// ses données resteront sur son téléphone, même sans connexion.
class HistoryEmpty extends StatelessWidget {
  const HistoryEmpty({
    super.key,
    this.onAction,
    this.actionLabel = 'Lancer un diagnostic',
  });

  /// Action déclenchée par le bouton principal, par exemple pour basculer
  /// vers l'onglet Diagnostic.
  final VoidCallback? onAction;

  /// Libellé du bouton d'action.
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_toggle_off_outlined,
                size: 56,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun diagnostic pour l’instant',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                'Vos analyses de feuilles apparaîtront ici. Elles restent '
                'stockées sur votre téléphone et sont consultables sans '
                'connexion internet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
