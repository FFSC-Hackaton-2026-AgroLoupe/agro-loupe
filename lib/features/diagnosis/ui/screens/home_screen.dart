import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/photo_service.dart';
import '../../../onboarding/state/coach_controller.dart';
import '../../../onboarding/ui/coach_targets.dart';
import '../../../../shared/widgets/app_bar_title.dart';
import '../../../../shared/widgets/connection_badge.dart';
import '../../state/diagnosis_provider.dart';
import '../widgets/crop_selector.dart';
import 'photo_guide_screen.dart';
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
          actions: const [_MenuAide()],
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

/// Les deux aides, rassemblées sous un seul bouton.
///
/// Un menu plutôt qu'une icône par entrée : la barre de titre porte déjà la
/// marque et, pendant un diagnostic, le bouton de retour.
class _MenuAide extends StatelessWidget {
  const _MenuAide();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Aide',
      onSelected: (choix) {
        if (choix == 'tuto') {
          context.read<CoachController>().replay();
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PhotoGuideScreen()),
        );
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'tuto', child: Text('Revoir le tutoriel')),
        PopupMenuItem(value: 'photo', child: Text('La bonne photo')),
      ],
    );
  }
}

/// Point de départ : on choisit sa culture, puis on photographie.
///
/// Rien ne défile ici, et les deux boutons sont toujours à l'écran : c'est
/// l'action principale de l'application, elle ne doit jamais demander un
/// geste pour être trouvée. C'est la photo qui cède la place quand l'écran
/// est court, et sa consigne s'abrège plutôt que de déborder.
class _Start extends StatelessWidget {
  const _Start();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Seule cette partie défile. Les boutons, eux, restent hors de la
          // zone défilante : c'est ce qui garantit qu'ils sont toujours à
          // l'écran, sans dépendre d'un calcul de hauteur.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CropSelector(),
                    const SizedBox(height: 20),
                    SizedBox(
                      // Estimation de la place prise par le sélecteur. Si
                      // elle est fausse, cette zone défile un peu : elle ne
                      // déborde pas, et les boutons ne bougent pas.
                      height: math.max(160, constraints.maxHeight - 260),
                      child: const _Hero(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _Actions(),
        ],
      ),
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
            key: CoachTargets.photoButton,
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
          // La consigne s'adapte à la place disponible au lieu de déborder :
          // sur un petit écran, le titre seul ; sur un très petit, rien.
          LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _Instruction(hauteur: constraints.maxHeight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction({required this.hauteur});

  /// Hauteur disponible dans la photo.
  final double hauteur;

  /// En dessous, la consigne complète ne tient plus : mesuré à 60 px, le
  /// titre et ses deux lignes débordaient de 14 px.
  static const double _seuilTitreSeul = 170;

  /// En dessous, même le titre est de trop : la photo est réduite à un
  /// bandeau, autant la laisser nue.
  static const double _seuilRien = 88;

  @override
  Widget build(BuildContext context) {
    if (hauteur < _seuilRien) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Photographiez une feuille',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hauteur >= _seuilTitreSeul) ...[
          const SizedBox(height: 6),
          Text(
            "Une seule feuille, en plein jour. L'analyse se fait sur votre "
            'téléphone, même sans connexion.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
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
