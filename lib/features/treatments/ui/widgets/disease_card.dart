import 'package:flutter/material.dart';

import '../../../../core/theme/diagnosis_colors.dart';
import '../../models/treatment.dart';

/// Carte résumée d'une fiche maladie.
///
/// Affiche le nom de la maladie, sa gravité et la première ligne
/// de ses symptômes.
class DiseaseCard extends StatelessWidget {
  const DiseaseCard({
    super.key,
    required this.treatment,
    this.onTap,
  });

  final Treatment treatment;
  final VoidCallback? onTap;

  Color _severityColor(BuildContext context) {
    final colors = context.diagnosisColors;

    return switch (treatment.severity) {
      'élevée' => colors.diseased,
      'moyenne' => colors.uncertain,
      'aucune' => colors.healthy,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _severityColor(context);

    final firstSymptom = treatment.symptoms.isNotEmpty
        ? treatment.symptoms.first
        : 'Aucun symptôme renseigné.';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                treatment.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: severityColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Gravité : ${treatment.severity}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                firstSymptom,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}