import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/diagnosis_colors.dart';
import '../../models/history_entry.dart';

/// Une ligne de l'historique.
///
/// La vignette d'abord : c'est la photo que l'agriculteur a prise, et c'est
/// par elle qu'il reconnaît le plant dont il s'agit, bien avant de lire le
/// nom de la maladie.
class HistoryTile extends StatelessWidget {
  const HistoryTile({required this.entry, required this.onTap, super.key});

  final HistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = context.diagnosisColors;
    final couleur = entry.isConfirmed ? couleurs.healthy : couleurs.uncertain;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Vignette(chemin: entry.imagePath),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.diseaseName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.cropDisplayName} · ${entry.formattedDate}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          entry.isConfirmed
                              ? Icons.check_circle_outline
                              : Icons.help_outline,
                          size: 15,
                          color: couleur,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            entry.isConfirmed
                                ? 'Symptômes confirmés'
                                : 'Resté sans réponse',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: couleur,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Photo du diagnostic, ou son remplacement.
///
/// Le fichier peut avoir disparu : l'utilisateur a pu vider sa galerie, ou
/// le système nettoyer son dossier temporaire. Une icône vaut mieux qu'un
/// carré rouge au milieu de la liste.
class _Vignette extends StatelessWidget {
  const _Vignette({required this.chemin});

  final String chemin;

  static const double _cote = 56;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: _cote,
        height: _cote,
        child: Image.file(
          File(chemin),
          fit: BoxFit.cover,
          errorBuilder: (context, _, _) => ColoredBox(
            color: colors.surfaceContainerHighest,
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 22,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
