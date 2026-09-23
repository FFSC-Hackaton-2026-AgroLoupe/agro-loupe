import 'package:flutter/material.dart';

/// Couleurs de marque, reprises de l'icône de l'application.
abstract final class AppColors {
  /// Bleu ardoise de l'icône : couleur de marque, dont découle tout le thème.
  ///
  /// Contraste 9,30:1 sur blanc — lisible en plein soleil, sur un écran
  /// d'entrée de gamme, ce qui est le contexte réel d'utilisation.
  static const Color brand = Color(0xFF304963);

  /// Vert sauge de l'icône.
  ///
  /// Contraste 1,75:1 sur blanc : beaucoup trop faible pour du texte, une
  /// icône ou un bouton. À réserver aux fonds et aux surfaces.
  static const Color sage = Color(0xFFA6CBC7);

  /// Indicateur discret d'absence de réseau.
  static const Color offline = Color(0xFF757575);
}
