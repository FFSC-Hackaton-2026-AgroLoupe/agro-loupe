import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../treatments/models/treatment.dart';
import '../../../treatments/state/treatment_provider.dart';
import '../../../treatments/ui/widgets/treatment_sections.dart';
import '../../models/crop_profile.dart';
import '../../models/diagnosis.dart';
import '../../models/second_opinion.dart';
import '../../state/second_opinion_provider.dart';

/// Deuxième avis en ligne, proposé après l'échec du diagnostic embarqué.
///
/// Trois conditions doivent être réunies pour que le bouton apparaisse : un
/// accès en ligne configuré, le réseau présent, et un utilisateur qui a rejeté
/// les hypothèses locales. Il n'y a aucune bascule automatique : le modèle
/// embarqué répond toujours en premier, hors connexion, en 200 ms.
class SecondOpinionCard extends StatelessWidget {
  const SecondOpinionCard(this.diagnosis, {super.key});

  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SecondOpinionProvider>();
    if (!provider.isAvailable) return const SizedBox.shrink();

    final state = provider.stateFor(diagnosis.imagePath);
    final online = context.watch<ConnectionStatus>() == ConnectionStatus.online;

    // Hors ligne, on ne propose pas une action vouée à l'échec. Un avis déjà
    // rendu reste en revanche affiché : il a été obtenu, il reste lisible.
    if (!online && state is SecondOpinionIdle) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const SizedBox(height: 12),
            switch (state) {
              SecondOpinionIdle() => _Offer(diagnosis: diagnosis),
              SecondOpinionAsking() => const _Asking(),
              SecondOpinionReady(:final opinion) => _Result(opinion: opinion),
              SecondOpinionError(:final message) => _Failure(message: message),
            },
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.cloud_outlined,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          'Deuxième avis en ligne',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Offer extends StatelessWidget {
  const _Offer({required this.diagnosis});

  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Le module hors-ligne ne connaît qu'une liste fixe de maladies. "
          'Une analyse en ligne peut reconnaître autre chose, y compris un '
          'insecte.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => _demander(context),
          icon: const Icon(Icons.travel_explore_outlined),
          label: const Text('Demander un deuxième avis'),
        ),
        const SizedBox(height: 4),
        Text(
          'Nécessite internet. Compte quelques secondes.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _demander(BuildContext context) {
    final profile = CropProfile.of(diagnosis.crop);
    final catalog = context
        .read<TreatmentProvider>()
        .forCrop(profile.displayName)
        .map((fiche) => (label: fiche.modelLabel, name: fiche.name))
        .toList();

    context.read<SecondOpinionProvider>().ask(
      imagePath: diagnosis.imagePath,
      cropName: profile.displayName,
      catalog: catalog,
    );
  }
}

class _Asking extends StatelessWidget {
  const _Asking();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Analyse en ligne…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: context.read<SecondOpinionProvider>().reset,
          child: const Text('Réessayer'),
        ),
      ],
    );
  }
}

/// Résultat rendu par le modèle en ligne.
///
/// Aucune jauge et aucun pourcentage : la certitude est exprimée en mots, et
/// elle n'est pas comparable au score calculé du modèle embarqué.
class _Result extends StatelessWidget {
  const _Result({required this.opinion});

  final SecondOpinion opinion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Treatment? treatment = opinion.label == null
        ? null
        : context.watch<TreatmentProvider>().forLabel(opinion.label!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          opinion.isInconclusive
              ? "Aucune maladie de notre liste ne correspond"
              : (treatment?.name ?? opinion.name ?? 'Maladie identifiée'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          opinion.certainty.label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Text(opinion.observation, style: theme.textTheme.bodyMedium),

        if (opinion.pestRatherThanDisease) ...[
          const SizedBox(height: 12),
          Text(
            "Il s'agirait d'un insecte ravageur, et non d'une maladie.",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        if (opinion.reasonIfNone != null) ...[
          const SizedBox(height: 8),
          Text(opinion.reasonIfNone!, style: theme.textTheme.bodyMedium),
        ],

        const SizedBox(height: 20),

        // Règle intangible : le modèle identifie, les fiches soignent. Sans
        // fiche correspondante, on s'arrête à l'identification.
        if (treatment != null)
          TreatmentSheetView(treatment: treatment)
        else
          Text(
            'Nous ne pouvons pas vous conseiller de traitement pour ce cas. '
            'Montrez le plant à un agent agricole.',
            style: theme.textTheme.bodyMedium,
          ),

        const SizedBox(height: 20),
        Text(
          'Identification assistée par ordinateur, non vérifiée par notre '
          'équipe. Les conseils affichés, eux, proviennent de nos fiches.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
