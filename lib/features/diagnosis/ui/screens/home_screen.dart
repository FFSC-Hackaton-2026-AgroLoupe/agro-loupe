import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/photo_service.dart';
import '../../../../shared/widgets/app_bar_title.dart';
import '../../../../shared/widgets/connection_badge.dart';
import '../../state/diagnosis_provider.dart';
import '../widgets/crop_selector.dart';
import '../widgets/diagnosis_result_card.dart';
import '../widgets/second_opinion_card.dart';
import '../widgets/unknown_crop_view.dart';

/// Écran unique du diagnostic : choix de la culture, photo, résultat.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final peutRevenir =
        provider.state is! DiagnosisIdle &&
        provider.state is! DiagnosisAnalyzing;

    return PopScope(
      // Le bouton retour du téléphone remonte d'une étape au lieu de quitter
      // l'application : c'est ce que l'utilisateur attend au milieu d'un
      // diagnostic.
      canPop: !peutRevenir,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) provider.goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const AppBarTitle(AppConstants.appName),
          leading: peutRevenir
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Revenir',
                  onPressed: provider.goBack,
                )
              : null,
        ),
        body: const Column(
          children: [
            ConnectionBadge(),
            Expanded(child: _Body()),
          ],
        ),
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
      DiagnosisConfirmed() => DiagnosisConfirmedCard(state),
      DiagnosisExhausted() => _Exhausted(state),
      DiagnosisOnline(:final imagePath) => UnknownCropView(
        imagePath: imagePath,
      ),
      DiagnosisError(:final message) => _Failure(message: message),
    };
  }
}

/// Point de départ : on choisit sa culture, puis on photographie.
class _Start extends StatelessWidget {
  const _Start();

  /// Hauteur en dessous de laquelle la consigne posée sur la photo ne tient
  /// plus. Mesurée : le titre et ses deux lignes débordaient à 60 px.
  static const double _hauteurMiniHero = 200;

  /// Place occupée par le sélecteur de culture, les deux boutons et les
  /// espacements. Approximation : si elle est fausse, la page défile un peu,
  /// elle ne déborde jamais.
  static const double _placeDuReste = 300;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // La photo prend la place restante, sans jamais descendre sous une
        // hauteur lisible. Sur un écran trop court, c'est la page qui défile
        // plutôt que la consigne qui se fait rogner.
        final hauteurHero = math.max(
          _hauteurMiniHero,
          constraints.maxHeight - _placeDuReste,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CropSelector(),
              const SizedBox(height: 20),
              SizedBox(height: hauteurHero, child: const _Hero()),
              const SizedBox(height: 20),
              const _Actions(),
            ],
          ),
        );
      },
    );
  }
}

/// Les deux façons de fournir une feuille, côte à côte.
///
/// L'appareil photo occupe plus de place que la galerie : au champ, c'est le
/// geste attendu, la galerie n'étant qu'un repli. Les libellés sont courts
/// pour tenir sur une seule ligne sur un écran de 360 dp, et la hauteur de
/// 52 px donne une cible confortable à viser avec des mains sales.
class _Actions extends StatelessWidget {
  const _Actions();

  static const Size _taille = Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DiagnosisProvider>();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            onPressed: () => provider.analyze(PhotoSource.camera),
            style: FilledButton.styleFrom(minimumSize: _taille),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Photographier'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () => provider.analyze(PhotoSource.gallery),
            style: OutlinedButton.styleFrom(minimumSize: _taille),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galerie'),
          ),
        ),
      ],
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
///
/// C'est le moment où le deuxième avis en ligne est le plus pertinent : le
/// modèle embarqué vient d'échouer, et l'utilisateur le sait.
class _Exhausted extends StatelessWidget {
  const _Exhausted(this.state);

  final DiagnosisExhausted state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Message(
            icon: Icons.help_outline,
            title: "Nous n'avons pas pu identifier la maladie",
            body:
                'Reprenez la photo en plein jour, au plus près de la feuille. '
                'Si le doute persiste, montrez le plant à un agent agricole.',
            action: 'Recommencer',
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SecondOpinionCard(state.diagnosis),
          ),
        ],
      ),
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
          mainAxisSize: MainAxisSize.min,
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
