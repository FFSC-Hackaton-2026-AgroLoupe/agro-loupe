import 'package:flutter/widgets.dart';

/// Clés des éléments que le tutoriel met en lumière.
///
/// Rassemblées ici parce que le voile vit au-dessus de toute l'application,
/// dans la coquille, alors que les éléments désignés appartiennent à des
/// écrans différents — le sélecteur de culture, le bouton photo et la barre
/// d'onglets ne se voient pas les uns les autres.
///
/// Les faire descendre par constructeur traverserait cinq widgets sans
/// qu'aucun ne s'en serve, et couplerait la coquille à l'intérieur de chaque
/// écran. Le registre reste le moindre mal.
abstract final class CoachTargets {
  /// Le choix de la culture, sur l'accueil.
  static final GlobalKey cropSelector = GlobalKey(debugLabel: 'coach-culture');

  /// Le bouton de prise de photo.
  static final GlobalKey photoButton = GlobalKey(debugLabel: 'coach-photo');

  /// La barre des trois onglets, dans la coquille.
  static final GlobalKey navBar = GlobalKey(debugLabel: 'coach-onglets');

  /// Les boutons Oui/Non de la confirmation par symptômes.
  ///
  /// L'étape la plus importante à expliquer : personne ne s'attend à ce que
  /// l'application demande de vérifier, et répondre « oui » par réflexe fait
  /// tomber le seul garde-fou contre un diagnostic faux.
  static final GlobalKey confirmation = GlobalKey(debugLabel: 'coach-confirm');
}
