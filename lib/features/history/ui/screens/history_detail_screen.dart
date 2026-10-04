import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/diagnosis_colors.dart';
import '../../../../shared/widgets/app_bar_title.dart';
import '../../../diagnosis/ui/widgets/diagnosis_result_card.dart';
import '../../../treatments/ui/widgets/treatment_sections.dart';
import '../../models/history_entry.dart';

/// Écran de consultation détaillée d'un diagnostic passé.
///
/// Ne lit aucun provider et ne déclenche aucune requête : il s'appuie
/// exclusivement sur [entry], ce qui le rend entièrement autonome et testable.
class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppBarTitle('Détail du diagnostic')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _HistoryPhoto(path: entry.imagePath),
          const SizedBox(height: 20),
          _HeaderSection(entry: entry),
          const SizedBox(height: 24),
          _ContentSection(entry: entry),
        ],
      ),
    );
  }
}

/// Photographie du diagnostic avec gestion robuste de suppression.
class _HistoryPhoto extends StatelessWidget {
  const _HistoryPhoto({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final file = File(path);
    final exists = file.existsSync();

    Widget placeholder() => ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Photo non disponible sur cet appareil',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: exists
            ? Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, _, _) => placeholder(),
              )
            : placeholder(),
      ),
    );
  }
}

/// En-tête : culture, nom de maladie, date et badge de statut.
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.diagnosisColors;

    final (badgeColor, badgeIcon, badgeLabel) = entry.isConfirmed
        ? (colors.healthy, Icons.check_circle_outline, 'Diagnostic confirmé')
        : (colors.uncertain, Icons.cancel_outlined, 'Diagnostic non retenu');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.cropDisplayName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 14, color: badgeColor),
                  const SizedBox(width: 5),
                  Text(
                    badgeLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
        Text(entry.diseaseName, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              entry.formattedDate,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ConfidenceIndicator(percent: entry.percent, label: entry.modelLabel),
      ],
    );
  }
}

/// Fiche de traitement complète ou message d'abandon explicite.
class _ContentSection extends StatelessWidget {
  const _ContentSection({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    if (!entry.isConfirmed) {
      return const _AbandonedCard();
    }

    if (entry.treatment != null) {
      return TreatmentSheetView(treatment: entry.treatment!);
    }

    return const _MissingTreatmentCard();
  }
}

/// Affiché lorsqu'un diagnostic a été abandonné par l'utilisateur.
class _AbandonedCard extends StatelessWidget {
  const _AbandonedCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Diagnostic non retenu',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Vous aviez indiqué que les symptômes ne correspondaient pas à '
            'votre plant. Aucun traitement n’a été retenu afin d’éviter une '
            'intervention inadaptée.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'En cas de doute, prenez une nouvelle photo de plus près ou '
            'montrez directement le plant à un agent agricole.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Affiché si un diagnostic confirmé ne possède pas de fiche de traitement locale.
class _MissingTreatmentCard extends StatelessWidget {
  const _MissingTreatmentCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.secondaryContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.support_agent_outlined,
            size: 24,
            color: colors.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fiche non disponible',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'La fiche de traitement de cette maladie n’est pas disponible '
                  'dans l’application. Montrez votre plant à un conseiller agricole.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
