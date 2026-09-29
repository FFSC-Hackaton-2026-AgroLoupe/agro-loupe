import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/diagnosis_colors.dart';
import '../../../../shared/widgets/app_bar_title.dart';

/// Comment photographier une feuille pour obtenir un bon résultat.
///
/// Montré plutôt qu'écrit : quatre comparaisons côte à côte, la bonne photo
/// à gauche, la mauvaise à droite. Une règle écrite se lit et s'oublie ; un
/// contraste visuel se retient, et se comprend d'un coup d'œil en plein
/// champ.
///
/// Les vignettes sont dessinées, pas photographiées. Deux vraies photos
/// vaudraient mieux, et remplaceront ces dessins dès que l'équipe en aura
/// collecté sur le terrain.
///
/// C'est le seul endroit où l'utilisateur peut réellement se tromper : il ne
/// peut pas mal utiliser un menu à trois onglets, mais il peut très bien
/// photographier trois feuilles de loin, à l'ombre — et le modèle répondra
/// alors n'importe quoi, avec assurance.
class PhotoGuideScreen extends StatelessWidget {
  const PhotoGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const AppBarTitle('La bonne photo')),
      body: ListView(
        // La marge basse du système s'ajoute à la nôtre : sans elle, les
        // dernières lignes se glissent sous la barre de navigation du
        // téléphone et deviennent illisibles.
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            'La photo décide du résultat',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quatre gestes, et le diagnostic devient nettement plus sûr.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),

          const _Comparaison(
            titre: 'Remplissez le cadre',
            explication:
                'De trop loin, les taches deviennent invisibles pour '
                "l'analyse.",
            bonne: _Vignette(taille: _Taille.grande),
            mauvaise: _Vignette(taille: _Taille.petite),
          ),
          const _Comparaison(
            titre: 'Une seule feuille',
            explication:
                'Plusieurs feuilles dans la photo brouillent la '
                'reconnaissance.',
            bonne: _Vignette(taille: _Taille.grande),
            mauvaise: _Vignette(taille: _Taille.petite, nombre: 3),
          ),
          const _Comparaison(
            titre: 'En plein jour',
            explication:
                'Les couleurs comptent autant que la forme des taches. '
                'Évitez le flash.',
            bonne: _Vignette(taille: _Taille.grande),
            mauvaise: _Vignette(taille: _Taille.grande, sombre: true),
          ),
          const _Comparaison(
            titre: 'Tenez le téléphone immobile',
            explication: 'Une photo floue fait perdre les petits détails.',
            bonne: _Vignette(taille: _Taille.grande),
            mauvaise: _Vignette(taille: _Taille.grande, flou: true),
          ),

          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Si le résultat vous paraît faux',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reprenez la photo de plus près avant toute chose. '
                    "C'est ce qui corrige le plus de cas.",
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une règle, illustrée par deux vignettes opposées.
class _Comparaison extends StatelessWidget {
  const _Comparaison({
    required this.titre,
    required this.explication,
    required this.bonne,
    required this.mauvaise,
  });

  final String titre;
  final String explication;
  final Widget bonne;
  final Widget mauvaise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = context.diagnosisColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            explication,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Cadre(
                  couleur: couleurs.healthy,
                  icone: Icons.check,
                  child: bonne,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Cadre(
                  couleur: couleurs.diseased,
                  icone: Icons.close,
                  child: mauvaise,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cadre coloré autour d'une vignette, avec sa pastille de verdict.
class _Cadre extends StatelessWidget {
  const _Cadre({
    required this.couleur,
    required this.icone,
    required this.child,
  });

  final Color couleur;
  final IconData icone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: couleur, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: child,
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(icone, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Taille { grande, petite }

/// Simulation d'une photo de feuille, dessinée.
class _Vignette extends StatelessWidget {
  const _Vignette({
    required this.taille,
    this.nombre = 1,
    this.sombre = false,
    this.flou = false,
  });

  final _Taille taille;

  /// Nombre de feuilles dans le cadre.
  final int nombre;

  final bool sombre;
  final bool flou;

  @override
  Widget build(BuildContext context) {
    final fond = Theme.of(context).colorScheme.surfaceContainerHighest;
    final part = taille == _Taille.grande ? 0.82 : 0.32;

    Widget contenu = ColoredBox(
      color: fond,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cote = constraints.maxWidth * part;
          return Center(
            child: nombre == 1
                ? _feuille(cote)
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < nombre; i++) _feuille(cote * 0.8),
                    ],
                  ),
          );
        },
      ),
    );

    if (flou) {
      contenu = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: contenu,
      );
    }

    if (sombre) {
      contenu = Stack(
        fit: StackFit.expand,
        children: [
          contenu,
          const ColoredBox(color: Color(0x99000000)),
        ],
      );
    }

    return contenu;
  }

  Widget _feuille(double cote) => SizedBox(
    width: cote * 0.62,
    height: cote,
    child: const CustomPaint(painter: _FeuillePainter()),
  );
}

/// Feuille schématique, avec sa nervure et quelques taches.
///
/// Dessinée plutôt qu'embarquée en image : quatre vignettes en deux thèmes
/// feraient huit fichiers à maintenir, pour un dessin de vingt lignes.
class _FeuillePainter extends CustomPainter {
  const _FeuillePainter();

  static const Color _limbe = Color(0xFF8FBFB3);
  static const Color _nervure = Color(0xFF4F7F73);
  static const Color _tache = Color(0xFF8D5A3B);

  @override
  void paint(Canvas canvas, Size size) {
    final l = size.width;
    final h = size.height;

    final forme = Path()
      ..moveTo(l / 2, 0)
      ..quadraticBezierTo(l * 1.05, h * 0.38, l / 2, h)
      ..quadraticBezierTo(-l * 0.05, h * 0.38, l / 2, 0)
      ..close();
    canvas.drawPath(forme, Paint()..color = _limbe);

    canvas.drawLine(
      Offset(l / 2, h * 0.04),
      Offset(l / 2, h * 0.96),
      Paint()
        ..color = _nervure
        ..strokeWidth = (l * 0.045).clamp(0.6, 3.0),
    );

    // Les taches sont ce que l'analyse cherche : sans elles, la vignette ne
    // montrerait pas une feuille malade.
    final tache = Paint()..color = _tache.withValues(alpha: 0.75);
    canvas.drawCircle(Offset(l * 0.34, h * 0.34), l * 0.10, tache);
    canvas.drawCircle(Offset(l * 0.64, h * 0.52), l * 0.08, tache);
    canvas.drawCircle(Offset(l * 0.44, h * 0.70), l * 0.06, tache);
  }

  @override
  bool shouldRepaint(_FeuillePainter oldDelegate) => false;
}
