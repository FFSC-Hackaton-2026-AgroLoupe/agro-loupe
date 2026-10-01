import 'package:flutter/material.dart';

import '../../../../core/theme/diagnosis_colors.dart';
import '../../models/treatment.dart';

/// Bandeau en haut de la fiche : nom, culture, gravité.
///
/// La couleur vient de [DiagnosisColors], déjà mesurée pour le thème clair
/// et le thème sombre. `aucune` prend le vert des plantes saines.
class DiseaseHeader extends StatelessWidget {
  const DiseaseHeader({super.key, required this.treatment});

  final Treatment treatment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = context.diagnosisColors;
    final couleur = switch (treatment.severity) {
      'élevée' => couleurs.diseased,
      'moyenne' => couleurs.uncertain,
      'aucune' => couleurs.healthy,
      _ => couleurs.uncertain,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(treatment.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            _culture(treatment.crop),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Gravité',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                treatment.severity,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: couleur,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Les fiches stockent `manioc`, `tomate`, `maïs`.
/// L'écran reprend le nom du sélecteur : Manioc, Tomate, Maïs.
String _culture(String crop) {
  if (crop.isEmpty) return crop;
  return '${crop[0].toUpperCase()}${crop.substring(1)}';
}
