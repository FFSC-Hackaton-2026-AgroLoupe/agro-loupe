import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'diagnosis_colors.dart';

/// Thèmes clair et sombre de l'application.
///
/// Les deux sont construits à partir de la même couleur de base pour rester
/// cohérents. L'appareil de l'utilisateur décide lequel s'applique.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      // Les couleurs de verdict vivent à part de la couleur de marque :
      // voir la justification dans `diagnosis_colors.dart`.
      extensions: <ThemeExtension<dynamic>>[
        brightness == Brightness.light
            ? DiagnosisColors.light
            : DiagnosisColors.dark,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Cible tactile confortable : l'application s'utilise souvent
          // en extérieur, parfois avec les mains sales ou gantées.
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
