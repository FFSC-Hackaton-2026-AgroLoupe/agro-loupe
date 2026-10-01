import 'package:flutter/material.dart';

import '../../../../core/theme/diagnosis_colors.dart';
import '../../../diagnosis/ui/widgets/diagnosis_result_card.dart';
import '../../models/history_entry.dart';

/// Une ligne de l'historique : vignette, maladie, culture, date et statut.
///
/// `DiagnosisPhoto` est réutilisé tel quel (voir diagnosis_result_card.dart)
/// pour charger la photo depuis son chemin, simplement contraint à la taille
/// d'une vignette ici.
class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.entry, this.onTap});

  final HistoryEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.diagnosisColors;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: SizedBox(
        width: 56,
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: DiagnosisPhoto(path: entry.imagePath),
        ),
      ),
      title: Text(
        entry.diseaseName,
        style: theme.textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${entry.cropDisplayName} · ${entry.formattedDate}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _StatusBadge(
        isConfirmed: entry.isConfirmed,
        confirmedColor: colors.healthy,
        mutedColor: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Distingue un diagnostic confirmé au champ d'un diagnostic abandonné.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.isConfirmed,
    required this.confirmedColor,
    required this.mutedColor,
  });

  final bool isConfirmed;
  final Color confirmedColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isConfirmed ? 'Diagnostic confirmé' : 'Diagnostic abandonné',
      child: Icon(
        isConfirmed ? Icons.check_circle : Icons.remove_circle_outline,
        color: isConfirmed ? confirmedColor : mutedColor,
        size: 22,
      ),
    );
  }
}