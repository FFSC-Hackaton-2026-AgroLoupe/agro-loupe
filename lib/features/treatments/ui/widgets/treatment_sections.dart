import 'package:flutter/material.dart';

import '../../models/treatment.dart';

/// Liste à puces précédée d'un titre. Rien n'est affiché si la liste est vide.
class BulletSection extends StatelessWidget {
  const BulletSection({
    super.key,
    required this.title,
    required this.items,
    this.icon,
    this.color,
  });

  final String title;
  final List<String> items;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: tint),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: theme.textTheme.bodyMedium),
                  Expanded(
                    child: Text(item, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Mise en garde propre à une maladie, mise en évidence.
class TreatmentNote extends StatelessWidget {
  const TreatmentNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: colors.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ce que l'utilisateur devrait observer, pour qu'il puisse confirmer ou non.
///
/// C'est le garde-fou du produit : le modèle peut se tromper avec une forte
/// confiance, mais l'agriculteur, lui, a la plante sous les yeux.
class SymptomsPanel extends StatelessWidget {
  const SymptomsPanel({super.key, required this.treatment});

  final Treatment treatment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BulletSection(
          title: 'Ce que vous devriez voir',
          items: treatment.symptoms,
          icon: Icons.visibility_outlined,
        ),
        BulletSection(
          title: 'À ne pas confondre avec',
          items: treatment.confusions,
          icon: Icons.compare_arrows,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

/// Fiche complète, affichée une fois le diagnostic confirmé.
class TreatmentSheetView extends StatelessWidget {
  const TreatmentSheetView({super.key, required this.treatment});

  final Treatment treatment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (treatment.note != null) TreatmentNote(text: treatment.note!),
        BulletSection(
          title: 'À faire maintenant',
          items: treatment.culturalPractices,
          icon: Icons.handyman_outlined,
        ),
        BulletSection(
          title: 'Traitement',
          items: treatment.chemicalTreatment,
          icon: Icons.science_outlined,
        ),
        BulletSection(
          title: 'Éviter que cela revienne',
          items: treatment.prevention,
          icon: Icons.shield_outlined,
        ),
        if (treatment.whenToConsult.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.support_agent,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quand demander conseil',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        treatment.whenToConsult,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
