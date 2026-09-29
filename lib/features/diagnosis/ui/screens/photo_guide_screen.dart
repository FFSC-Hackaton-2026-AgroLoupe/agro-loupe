import 'package:flutter/material.dart';

import '../../../../core/theme/diagnosis_colors.dart';
import '../../../../shared/widgets/app_bar_title.dart';

/// Comment photographier une feuille pour obtenir un bon résultat.
///
/// C'est le seul endroit où l'utilisateur peut réellement se tromper. Il ne
/// peut pas mal utiliser un menu à trois onglets, mais il peut très bien
/// photographier trois feuilles de loin, à l'ombre — et le modèle répondra
/// alors n'importe quoi, avec assurance.
///
/// Accessible en permanence depuis l'accueil, pas seulement au premier
/// lancement : on en a besoin au moment de photographier, pas la veille.
class PhotoGuideScreen extends StatelessWidget {
  const PhotoGuideScreen({super.key});

  static const List<({String regle, String pourquoi})> _aFaire = [
    (
      regle: 'Une seule feuille dans la photo',
      pourquoi: 'Plusieurs feuilles brouillent la reconnaissance.',
    ),
    (
      regle: 'La feuille remplit presque tout le cadre',
      pourquoi: 'De trop loin, les taches deviennent invisibles.',
    ),
    (
      regle: 'En plein jour, à la lumière naturelle',
      pourquoi: 'Les couleurs comptent autant que la forme des taches.',
    ),
    (
      regle: 'Photographiez le côté atteint',
      pourquoi: "Certaines maladies n'apparaissent que sous la feuille.",
    ),
    (
      regle: 'Tenez le téléphone immobile',
      pourquoi: 'Une photo floue fait perdre les petits détails.',
    ),
  ];

  static const List<String> _aEviter = [
    'Photographier le champ entier ou la plante en entier',
    "Prendre la photo à l'ombre, le soir, ou avec le flash",
    'Poser la feuille sur un fond coloré ou encombré',
    'Photographier une feuille sèche ou abîmée par le transport',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = context.diagnosisColors;

    return Scaffold(
      appBar: AppBar(title: const AppBarTitle('La bonne photo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'La qualité de la photo décide du résultat. Cinq gestes suffisent.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),

          _Titre(texte: 'À faire', couleur: couleurs.healthy),
          const SizedBox(height: 12),
          for (final item in _aFaire)
            _Ligne(
              icone: Icons.check_circle_outline,
              couleur: couleurs.healthy,
              titre: item.regle,
              detail: item.pourquoi,
            ),

          const SizedBox(height: 28),
          _Titre(texte: 'À éviter', couleur: couleurs.diseased),
          const SizedBox(height: 12),
          for (final item in _aEviter)
            _Ligne(
              icone: Icons.cancel_outlined,
              couleur: couleurs.diseased,
              titre: item,
              detail: null,
            ),

          const SizedBox(height: 32),
          Text(
            "Si le résultat vous paraît faux, reprenez la photo de plus près "
            'avant toute chose. C\'est ce qui corrige le plus de cas.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre({required this.texte, required this.couleur});

  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Text(
      texte,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: couleur,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.icone,
    required this.couleur,
    required this.titre,
    required this.detail,
  });

  final IconData icone;
  final Color couleur;
  final String titre;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22, color: couleur),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: theme.textTheme.bodyLarge),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
