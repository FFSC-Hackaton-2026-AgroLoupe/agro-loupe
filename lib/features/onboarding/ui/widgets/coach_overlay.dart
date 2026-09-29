import 'package:flutter/material.dart';

/// Une étape du tutoriel : l'élément à désigner et ce qu'on en dit.
class CoachStep {
  const CoachStep({required this.key, required this.title, required this.body});

  /// Clé posée sur l'élément à mettre en lumière.
  ///
  /// Si l'élément n'est pas à l'écran au moment voulu, l'étape est sautée :
  /// un tutoriel ne doit jamais coincer l'utilisateur devant un voile noir.
  final GlobalKey key;

  final String title;
  final String body;
}

/// Voile sombre percé sur un élément, avec une bulle d'explication.
///
/// Écrit à la main plutôt qu'avec un paquet : c'est une centaine de lignes,
/// et une dépendance de plus est un risque de plus le jour de la démo.
///
/// Toujours interruptible. « Passer » est visible à chaque étape, et un appui
/// n'importe où avance — un utilisateur qui ne comprend pas ce qu'on lui
/// montre doit pouvoir en sortir sans chercher comment.
class CoachOverlay extends StatefulWidget {
  const CoachOverlay({required this.steps, required this.onDone, super.key});

  final List<CoachStep> steps;
  final VoidCallback onDone;

  @override
  State<CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<CoachOverlay> {
  int _index = 0;
  Rect? _cible;

  /// La bulle se pose sous l'élément désigné quand il reste la place, au
  /// dessus sinon.
  bool _dessous = true;

  @override
  void initState() {
    super.initState();
    // Les positions ne sont connues qu'après la première mise en page.
    WidgetsBinding.instance.addPostFrameCallback((_) => _mesurer());
  }

  void _mesurer() {
    if (!mounted) return;

    // On avance jusqu'à trouver une étape dont l'élément est bien à l'écran.
    while (_index < widget.steps.length) {
      final rect = _rectDe(widget.steps[_index].key);
      if (rect != null) {
        setState(() => _cible = rect);
        return;
      }
      _index++;
    }
    widget.onDone();
  }

  static Rect? _rectDe(GlobalKey key) {
    final contexte = key.currentContext;
    if (contexte == null) return null;
    final objet = contexte.findRenderObject();
    if (objet is! RenderBox || !objet.hasSize) return null;
    return objet.localToGlobal(Offset.zero) & objet.size;
  }

  void _suivant() {
    if (_index >= widget.steps.length - 1) {
      widget.onDone();
      return;
    }
    setState(() {
      _index++;
      _cible = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _mesurer());
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.steps.length) return const SizedBox.shrink();

    final etape = widget.steps[_index];
    final taille = MediaQuery.sizeOf(context);
    _dessous =
        _cible == null ||
        _cible!.bottom + _Bulle.hauteurEstimee < taille.height;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Le geste ne porte que sur le voile : posé sur toute la pile, il
          // se disputait chaque appui avec les boutons de la bulle, et
          // « Passer » déclenchait aussi le passage à l'étape suivante.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _suivant,
              child: CustomPaint(painter: _Voile(trou: _cible)),
            ),
          ),
          if (_cible != null)
            // Le `Positioned` est posé ici, directement dans la pile : rendu
            // depuis le widget de la bulle, il laissait sa largeur non
            // bornée et la rangée de boutons ne pouvait plus se mesurer.
            Positioned(
              left: 16,
              right: 16,
              top: _dessous ? _cible!.bottom + 20 : null,
              bottom: _dessous ? null : taille.height - _cible!.top + 20,
              // Largeur calculée depuis l'écran plutôt que déduite des
              // contraintes reçues : le voile est posé au-dessus de toute
              // l'application, et rien ne garantit qu'elles soient bornées.
              child: SizedBox(
                width: taille.width - 32,
                child: _Bulle(
                  etape: etape,
                  numero: _index + 1,
                  total: widget.steps.length,
                  derniere: _index == widget.steps.length - 1,
                  onSuivant: _suivant,
                  onPasser: widget.onDone,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Voile sombre percé d'une ouverture sur l'élément désigné.
class _Voile extends CustomPainter {
  const _Voile({required this.trou});

  final Rect? trou;

  static const double _marge = 8;
  static const Radius _rayon = Radius.circular(12);

  @override
  void paint(Canvas canvas, Size size) {
    final peinture = Paint()..color = const Color(0xCC000000);
    final plein = Path()..addRect(Offset.zero & size);

    if (trou == null) {
      canvas.drawPath(plein, peinture);
      return;
    }

    final ouverture = Path()
      ..addRRect(RRect.fromRectAndRadius(trou!.inflate(_marge), _rayon));
    canvas.drawPath(
      Path.combine(PathOperation.difference, plein, ouverture),
      peinture,
    );
  }

  @override
  bool shouldRepaint(_Voile oldDelegate) => oldDelegate.trou != trou;
}

class _Bulle extends StatelessWidget {
  const _Bulle({
    required this.etape,
    required this.numero,
    required this.total,
    required this.derniere,
    required this.onSuivant,
    required this.onPasser,
  });

  final CoachStep etape;
  final int numero;
  final int total;
  final bool derniere;
  final VoidCallback onSuivant;
  final VoidCallback onPasser;

  /// Place estimée de la bulle, pour décider de la poser au-dessus ou en
  /// dessous de l'élément désigné.
  static const double hauteurEstimee = 190;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$numero sur $total',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(etape.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(etape.body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            // `Expanded` n'est pas décoratif : le thème donne aux
            // `FilledButton` une largeur minimale infinie, et dans une
            // rangée rien ne la borne. Sans lui, la mise en page échoue.
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onPasser,
                    child: const Text('Passer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onSuivant,
                    child: Text(derniere ? "J'ai compris" : 'Suivant'),
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
