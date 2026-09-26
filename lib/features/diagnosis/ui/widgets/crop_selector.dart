import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/crop_profile.dart';
import '../../state/diagnosis_provider.dart';

/// Choix de la culture, avant la photo.
///
/// Connaître la culture n'est pas une formalité : cela restreint le modèle aux
/// seules maladies concernées et fait gagner une dizaine de points de confiance.
///
/// Présenté en trois cartes illustrées plutôt qu'en libellés : les trois
/// feuilles sont visuellement très différentes, ce qui permet de choisir sans
/// lire — utile en extérieur, et pour un utilisateur peu à l'aise avec l'écrit.
class CropSelector extends StatelessWidget {
  const CropSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.select<DiagnosisProvider, Crop>((p) => p.crop);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quelle culture ?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          spacing: 12,
          children: [
            for (final profile in CropProfile.all)
              Expanded(
                child: _CropCard(
                  profile: profile,
                  isSelected: profile.crop == selected,
                  onTap: () => context.read<DiagnosisProvider>().selectCrop(
                    profile.crop,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CropCard extends StatelessWidget {
  const _CropCard({
    required this.profile,
    required this.isSelected,
    required this.onTap,
  });

  final CropProfile profile;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = isSelected ? colors.primary : colors.outlineVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: profile.displayName,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primaryContainer.withValues(alpha: 0.35)
                : colors.surface,
            border: Border.all(color: border, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Leaf(profile: profile, isSelected: isSelected),
              const SizedBox(height: 8),
              Text(
                profile.displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected ? colors.primary : colors.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vignette de la feuille, avec un repli tant que la photo n'est pas fournie.
class _Leaf extends StatelessWidget {
  const _Leaf({required this.profile, required this.isSelected});

  final CropProfile profile;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            // Hauteur fixe plutôt qu'un rapport de forme : sinon la vignette
            // suit la largeur de l'écran et devient énorme sur tablette.
            height: 84,
            width: double.infinity,
            child: Image.asset(
              profile.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, _, _) => ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Icon(
                  Icons.eco_outlined,
                  color: colors.onSurfaceVariant,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        if (isSelected)
          Positioned(
            top: 4,
            right: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.check, size: 14, color: colors.onPrimary),
              ),
            ),
          ),
      ],
    );
  }
}
