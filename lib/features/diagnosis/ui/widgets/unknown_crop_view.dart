import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../models/crop_profile.dart';
import '../../models/second_opinion.dart';
import '../../state/diagnosis_provider.dart';
import '../../state/second_opinion_provider.dart';

/// Résultat pour une culture hors des trois couvertes.
///
/// Aucun modèle n'a tourné sur l'appareil : l'identification vient entièrement
/// du service en ligne, et l'écran le dit. L'analyse démarre d'elle-même —
/// l'utilisateur a déjà pris sa photo, lui redemander d'appuyer serait une
/// étape pour rien.
class UnknownCropView extends StatefulWidget {
  const UnknownCropView({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<UnknownCropView> createState() => _UnknownCropViewState();
}

class _UnknownCropViewState extends State<UnknownCropView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _lancer());
  }

  void _lancer() {
    if (!mounted) return;
    final provider = context.read<SecondOpinionProvider>();
    if (provider.stateFor(widget.imagePath) is SecondOpinionIdle) {
      provider.askForUnknownCrop(imagePath: widget.imagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SecondOpinionProvider>();
    final state = provider.stateFor(widget.imagePath);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        if (!provider.isAvailable)
          const _Unavailable()
        else
          switch (state) {
            SecondOpinionIdle() || SecondOpinionAsking() => const _Asking(),
            SecondOpinionReady(:final opinion) => _Result(opinion: opinion),
            SecondOpinionError(:final message) => _Failure(
              message: message,
              imagePath: widget.imagePath,
            ),
          },
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: context.read<DiagnosisProvider>().reset,
          child: const Text('Nouvelle analyse'),
        ),
      ],
    );
  }
}

/// Aucun accès en ligne configuré : cette culture est hors de portée.
class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cette culture demande une analyse en ligne',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          "Elle n'est pas disponible pour le moment. Le manioc, la tomate et "
          "le maïs restent analysables sans connexion.",
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _Asking extends StatelessWidget {
  const _Asking();

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectionStatus>() == ConnectionStatus.online;
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 32),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          online ? 'Identification en cours…' : 'En attente de connexion…',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Cette culture ne peut pas être analysée hors connexion.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.imagePath});

  final String message;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: () => context
              .read<SecondOpinionProvider>()
              .askForUnknownCrop(imagePath: imagePath),
          child: const Text('Réessayer'),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.opinion});

  final SecondOpinion opinion;

  /// Profil correspondant à la plante reconnue, si elle fait partie des trois
  /// cultures couvertes.
  ///
  /// Le cas arrive quand l'utilisateur a choisi « une autre culture » par
  /// méprise. On le renvoie alors vers le parcours hors-ligne, qui est plus
  /// fiable et donne accès à nos fiches.
  CropProfile? get _couverte {
    final nom = opinion.cropName?.toLowerCase();
    if (nom == null) return null;
    for (final profile in CropProfile.withLocalModel) {
      if (nom.contains(profile.displayName.toLowerCase())) return profile;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couverte = _couverte;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // La plante d'abord : c'est la seule chose que l'utilisateur peut
        // vérifier avec certitude, et tout le reste en dépend.
        Text(
          opinion.cropName == null
              ? "Nous n'avons pas reconnu la plante"
              : 'Il s\'agirait de : ${opinion.cropName}',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          opinion.certainty.label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        if (couverte != null) ...[
          const SizedBox(height: 16),
          _Redirect(profile: couverte),
        ],

        const SizedBox(height: 20),
        if (opinion.name != null) ...[
          Text(opinion.name!, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
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
          const SizedBox(height: 12),
          Text(opinion.reasonIfNone!, style: theme.textTheme.bodyMedium),
        ],

        if (opinion.culturalAdvice.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Ce que vous pouvez faire', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final mesure in opinion.culturalAdvice)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: theme.textTheme.bodyMedium),
                  Expanded(
                    child: Text(mesure, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],

        const SizedBox(height: 24),
        // Règle intangible : aucun produit ne vient du modèle. Le dire
        // explicitement évite que l'utilisateur aille en chercher un seul.
        Text(
          "Aucun produit n'est conseillé ici. Pour un traitement, montrez le "
          'plant à un agent agricole : les produits autorisés varient selon '
          'les pays.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Identification assistée par ordinateur, non vérifiée par notre '
          'équipe.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Proposition de repasser sur le parcours hors-ligne.
class _Redirect extends StatelessWidget {
  const _Redirect({required this.profile});

  final CropProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette culture est couverte hors connexion. Le diagnostic y est '
              'plus fiable et donne accès à nos fiches de traitement.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () {
                final diagnosis = context.read<DiagnosisProvider>();
                diagnosis.selectCrop(profile.crop);
                diagnosis.reset();
              },
              child: Text('Analyser comme ${profile.displayName}'),
            ),
          ],
        ),
      ),
    );
  }
}
