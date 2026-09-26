import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/diagnosis_colors.dart';
import '../../../treatments/models/treatment.dart';
import '../../../treatments/state/treatment_provider.dart';
import '../../../treatments/ui/widgets/treatment_sections.dart';
import '../../models/disease_names.dart';
import '../../state/diagnosis_provider.dart';

/// Hypothèse proposée à l'utilisateur, avec les symptômes attendus.
///
/// Aucun traitement n'est affiché à ce stade : tant que l'utilisateur n'a pas
/// reconnu les symptômes, conseiller un produit reviendrait à traiter une
/// maladie peut-être absente.
class DiagnosisResultCard extends StatelessWidget {
  const DiagnosisResultCard(this.state, {super.key});

  final DiagnosisSuccess state;

  @override
  Widget build(BuildContext context) {
    final label = state.prediction.label;
    final treatment = context.watch<TreatmentProvider>().forLabel(label);
    final isUnknown = DiseaseNames.isUnknown(label);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        DiagnosisPhoto(path: state.diagnosis.imagePath),
        const SizedBox(height: 20),
        if (state.isFallback)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Autre hypothèse',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        Text(
          treatment?.name ?? DiseaseNames.of(label),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        ConfidenceIndicator(percent: state.prediction.percent, label: label),
        const SizedBox(height: 24),
        if (treatment != null) SymptomsPanel(treatment: treatment),
        if (isUnknown)
          const _Restart()
        else
          _Confirmation(hasSymptoms: treatment != null),
      ],
    );
  }
}

/// Photographie analysée.
class DiagnosisPhoto extends StatelessWidget {
  const DiagnosisPhoto({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (context, _, _) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: Icon(Icons.image_not_supported_outlined),
            ),
          ),
        ),
      ),
    );
  }
}

/// Degré de correspondance entre la photo et la maladie proposée.
///
/// Le pourcentage brut est relégué : il dit à quel point le modèle est sûr, ce
/// qui n'est pas la même chose que la vérité — on a mesuré une réponse fausse
/// annoncée à 97 %. Ce qui compte pour l'utilisateur, c'est de savoir s'il doit
/// regarder son plant de près, et c'est ce que dit le libellé.
class ConfidenceIndicator extends StatelessWidget {
  const ConfidenceIndicator({
    super.key,
    required this.percent,
    required this.label,
  });

  final int percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.diagnosisColors;

    final (
      Color color,
      String titre,
      String aide,
      int barres,
    ) = switch (label) {
      _ when DiseaseNames.isUnknown(label) => (
        colors.uncertain,
        'Plante non reconnue',
        "Vérifiez la culture choisie, puis reprenez la photo de plus près.",
        0,
      ),
      _ when DiseaseNames.isHealthy(label) => (
        colors.healthy,
        'Aucun signe de maladie',
        'Continuez à surveiller après les pluies.',
        5,
      ),
      _ when percent >= 80 => (
        colors.diseased,
        'Forte correspondance',
        'Les signes relevés collent bien à cette maladie.',
        5,
      ),
      _ when percent >= 60 => (
        colors.diseased,
        'Correspondance moyenne',
        'Comparez attentivement avec les symptômes ci-dessous.',
        3,
      ),
      _ => (
        colors.uncertain,
        'Correspondance faible',
        "Rien n'est sûr. Une autre photo, en plein jour, aiderait.",
        2,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Gauge(filled: barres, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titre,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$percent %',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(aide, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Cinq segments : lisible d'un coup d'œil, sans avoir à lire un nombre.
class _Gauge extends StatelessWidget {
  const _Gauge({required this.filled, required this.color});

  final int filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final vide = Theme.of(context).colorScheme.outlineVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            width: 6,
            height: i < filled ? 18 : 10,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i < filled ? color : vide,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// Demande à l'utilisateur si les symptômes correspondent à ce qu'il observe.
class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.hasSymptoms});

  final bool hasSymptoms;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DiagnosisProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasSymptoms
                  ? 'Est-ce bien ce que vous voyez sur votre plant ?'
                  : 'Est-ce que cela correspond à votre plant ?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: provider.rejectCurrent,
                    child: const Text('Non'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: provider.confirmCurrent,
                    child: const Text('Oui'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Restart extends StatelessWidget {
  const _Restart();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: context.read<DiagnosisProvider>().reset,
      child: const Text('Reprendre une photo'),
    );
  }
}

/// Fiche complète, affichée une fois l'hypothèse confirmée.
class DiagnosisConfirmedCard extends StatelessWidget {
  const DiagnosisConfirmedCard(this.state, {super.key});

  final DiagnosisConfirmed state;

  @override
  Widget build(BuildContext context) {
    final label = state.prediction.label;
    final Treatment? treatment = context.watch<TreatmentProvider>().forLabel(
      label,
    );
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          treatment?.name ?? DiseaseNames.of(label),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        ConfidenceIndicator(percent: state.prediction.percent, label: label),
        const SizedBox(height: 24),
        if (treatment != null)
          TreatmentSheetView(treatment: treatment)
        else
          Text(
            "La fiche de cette maladie n'est pas disponible. "
            'Montrez le plant à un agent agricole.',
            style: theme.textTheme.bodyMedium,
          ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: context.read<DiagnosisProvider>().reset,
          child: const Text('Nouveau diagnostic'),
        ),
      ],
    );
  }
}
