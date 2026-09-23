import 'package:flutter/material.dart';

/// Couleurs qui portent un verdict.
///
/// Elles sont volontairement distinctes de la couleur de marque. Dans cette
/// application, une couleur colorée est une information, pas une décoration :
/// le bleu signale une action, tandis que le vert, l'ambre et le rouge
/// annoncent un résultat. Un thème vert rendrait les deux indiscernables.
///
/// Exposées en [ThemeExtension] pour que le couple clair/sombre suive
/// automatiquement le thème de l'appareil.
@immutable
class DiagnosisColors extends ThemeExtension<DiagnosisColors> {
  const DiagnosisColors({
    required this.healthy,
    required this.uncertain,
    required this.diseased,
  });

  /// Plante saine, ou diagnostic au-dessus du seuil de confiance.
  final Color healthy;

  /// Confiance sous le seuil : résultat à présenter avec prudence.
  final Color uncertain;

  /// Maladie identifiée avec un niveau de confiance suffisant.
  final Color diseased;

  /// Contrastes mesurés sur fond blanc : 5,13:1, 5,93:1 et 5,62:1.
  static const DiagnosisColors light = DiagnosisColors(
    healthy: Color(0xFF2E7D32),
    uncertain: Color(0xFF8A5A00),
    diseased: Color(0xFFC62828),
  );

  /// Contrastes mesurés sur fond sombre : 9,24:1, 13,18:1 et 10,89:1.
  static const DiagnosisColors dark = DiagnosisColors(
    healthy: Color(0xFF81C784),
    uncertain: Color(0xFFFFD54F),
    diseased: Color(0xFFF2B8B5),
  );

  @override
  DiagnosisColors copyWith({
    Color? healthy,
    Color? uncertain,
    Color? diseased,
  }) {
    return DiagnosisColors(
      healthy: healthy ?? this.healthy,
      uncertain: uncertain ?? this.uncertain,
      diseased: diseased ?? this.diseased,
    );
  }

  @override
  DiagnosisColors lerp(DiagnosisColors? other, double t) {
    if (other == null) return this;
    return DiagnosisColors(
      healthy: Color.lerp(healthy, other.healthy, t)!,
      uncertain: Color.lerp(uncertain, other.uncertain, t)!,
      diseased: Color.lerp(diseased, other.diseased, t)!,
    );
  }
}

/// Raccourci de lecture : `context.diagnosisColors.healthy`.
extension DiagnosisColorsContext on BuildContext {
  DiagnosisColors get diagnosisColors =>
      Theme.of(this).extension<DiagnosisColors>()!;
}
