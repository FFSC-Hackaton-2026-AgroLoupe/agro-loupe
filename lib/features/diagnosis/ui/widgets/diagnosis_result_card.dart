import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/diagnosis_colors.dart';
import '../../models/disease_names.dart';
import '../../state/diagnosis_provider.dart';

/// Résultat proposé à l'utilisateur, qui doit le confirmer.
class DiagnosisResultCard extends StatelessWidget {
  const DiagnosisResultCard(this.state, {super.key});

  final DiagnosisSuccess state;

  @override
  Widget build(BuildContext context) {
    final prediction = state.prediction;
    final label = prediction.label;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _Photo(path: state.diagnosis.imagePath),
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
          DiseaseNames.of(label),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        _Confidence(percent: prediction.percent, label: label),
        const SizedBox(height: 24),
        const _Confirmation(),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.path});

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

/// Niveau de confiance, coloré selon ce qu'il signifie.
class _Confidence extends StatelessWidget {
  const _Confidence({required this.percent, required this.label});

  final int percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.diagnosisColors;
    final (color, texte) = switch (label) {
      _ when DiseaseNames.isUnknown(label) => (
        colors.uncertain,
        "Ce n'est peut-être pas la bonne plante",
      ),
      _ when DiseaseNames.isHealthy(label) => (
        colors.healthy,
        'Aucune maladie détectée',
      ),
      _ when percent < 60 => (colors.uncertain, 'Diagnostic incertain'),
      _ => (colors.diseased, 'Maladie probable'),
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$percent %',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(texte, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

/// Demande à l'utilisateur si le résultat correspond à ce qu'il observe.
///
/// Ce n'est pas un confort : le modèle des cultures tomate et maïs peut se
/// tromper avec une très forte confiance, et l'agriculteur, lui, a la plante
/// sous les yeux. Les symptômes attendus s'afficheront ici dès que les fiches
/// de traitement seront disponibles.
class _Confirmation extends StatelessWidget {
  const _Confirmation();

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
              'Est-ce que cela correspond à ce que vous voyez sur votre plant ?',
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
                    onPressed: provider.reset,
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
