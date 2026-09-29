import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// Titre d'`AppBar` précédé de la marque de l'application.
///
/// Deux fichiers plutôt qu'un seul teinté : le bleu nuit de la loupe
/// disparaîtrait sur le fond sombre, et le vert sauge de la feuille doit
/// rester vert — une teinte unique appliquée à l'ensemble les écraserait tous
/// les deux.
class AppBarTitle extends StatelessWidget {
  const AppBarTitle(this.text, {super.key});

  /// Titre de l'écran. `AgroLoupe` sur l'accueil, le nom de l'onglet ailleurs.
  final String text;

  static const double _taille = 28;

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          sombre ? AppConstants.iconOnDarkAsset : AppConstants.iconAsset,
          height: _taille,
          width: _taille,
          // Un logo absent ne doit pas décaler le titre ni faire rougir
          // l'écran : on le retire simplement.
          errorBuilder: (context, _, _) => const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
