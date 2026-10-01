import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_bar_title.dart';
import '../../state/treatment_provider.dart';
import '../widgets/disease_card.dart';

/// Catalogue des maladies, consultable sans passer par un diagnostic.
///
/// L'utilisateur choisit une culture puis consulte les fiches
/// correspondant à cette culture.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _selectedCrop = 'tomate';

  static const _crops = [
    'manioc',
    'tomate',
    'maïs',
  ];

  String _displayName(String crop) {
    return switch (crop) {
      'manioc' => 'Manioc',
      'tomate' => 'Tomate',
      'maïs' => 'Maïs',
      _ => crop,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TreatmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle('Catalogue'),
      ),
      body: switch (provider.state) {
        TreatmentsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        TreatmentsError(:final message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        TreatmentsReady() => _buildContent(context, provider),
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    TreatmentProvider provider,
  ) {
    final treatments = provider.forCrop(_selectedCrop);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Quelle culture ?',
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: 12),

        _buildCropSelector(context),

        const SizedBox(height: 24),

        Text(
          'Maladies du ${_displayName(_selectedCrop).toLowerCase()}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 12),

        if (treatments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Aucune fiche disponible pour cette culture.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (final treatment in treatments)
            DiseaseCard(
              treatment: treatment,
            ),
      ],
    );
  }

  Widget _buildCropSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        for (final crop in _crops)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CropCard(
                label: _displayName(crop),
                isSelected: crop == _selectedCrop,
                onTap: () {
                  setState(() {
                    _selectedCrop = crop;
                  });
                },
                colors: colors,
              ),
            ),
          ),
      ],
    );
  }
}

/// Carte de sélection d'une culture.
///
/// Sa présentation reprend le principe visuel du CropSelector
/// utilisé dans la feature diagnosis.
class _CropCard extends StatelessWidget {
  const _CropCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;

  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  final border = isSelected
      ? colors.primary
      : colors.outlineVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primaryContainer.withValues(alpha: 0.35)
                : colors.surface,
            border: Border.all(
              color: border,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
          child: Column(
            children: [
              Icon(
                Icons.eco_outlined,
                size: 32,
                color: isSelected
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? colors.primary
                      : colors.onSurface,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}