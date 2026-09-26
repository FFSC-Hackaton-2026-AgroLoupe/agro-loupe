import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/photo_service.dart';
import '../../../../shared/widgets/connection_badge.dart';
import '../../state/diagnosis_provider.dart';
import '../widgets/crop_selector.dart';
import '../widgets/diagnosis_result_card.dart';

/// Écran unique du diagnostic : choix de la culture, photo, résultat.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: const Column(
        children: [
          ConnectionBadge(),
          Expanded(child: _Body()),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DiagnosisProvider>().state;

    return switch (state) {
      DiagnosisIdle() => const _Start(),
      DiagnosisAnalyzing() => const _Analyzing(),
      DiagnosisSuccess() => DiagnosisResultCard(state),
      DiagnosisExhausted() => const _Exhausted(),
      DiagnosisError(:final message) => _Failure(message: message),
    };
  }
}

/// Point de départ : on choisit sa culture, puis on photographie.
/// Point de départ : on choisit sa culture, puis on photographie.
/// Point de départ : on choisit sa culture, puis on photographie.
class _Start extends StatelessWidget {
  const _Start();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DiagnosisProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CropSelector(),
          const SizedBox(height: 20),
          const Expanded(child: _Hero()),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => provider.analyze(PhotoSource.camera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Prendre une photo'),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => provider.analyze(PhotoSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choisir dans la galerie'),
          ),
        ],
      ),
    );
  }
}

/// Photographie d'accueil, avec la consigne posée dessus.
///
/// Le texte est lisible grâce au dégradé sombre : il ne dépend pas des
/// couleurs de la photo, qui varient d'un bord à l'autre de l'image.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppConstants.heroImageAsset,
            fit: BoxFit.cover,
            // L'image est cadrée sur le visage : en cas de rognage vertical,
            // mieux vaut perdre le bas que le haut.
            alignment: Alignment.topCenter,
            errorBuilder: (context, _, _) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomLeft,
            child: Padding(padding: EdgeInsets.all(20), child: _Instruction()),
          ),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Photographiez une feuille',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Une seule feuille, en plein jour. L'analyse se fait sur votre "
          'téléphone, même sans connexion.',
          style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _Analyzing extends StatelessWidget {
  const _Analyzing();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Analyse en cours…',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// Toutes les hypothèses ont été rejetées par l'utilisateur.
class _Exhausted extends StatelessWidget {
  const _Exhausted();

  @override
  Widget build(BuildContext context) {
    return _Message(
      icon: Icons.help_outline,
      title: "Nous n'avons pas pu identifier la maladie",
      body:
          'Reprenez la photo en plein jour, au plus près de la feuille. '
          'Si le doute persiste, montrez le plant à un agent agricole.',
      action: 'Recommencer',
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Message(
      icon: Icons.error_outline,
      title: 'Analyse impossible',
      body: message,
      action: 'Réessayer',
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: context.read<DiagnosisProvider>().reset,
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}
