import 'package:shared_preferences/shared_preferences.dart';

/// Mémorise que la présentation a déjà été vue.
///
/// Aucune erreur n'est remontée : si le stockage est indisponible, on
/// considère simplement que la présentation n'a pas été vue. Au pire elle
/// s'affiche une fois de trop — ce qui vaut mieux que de bloquer le
/// démarrage de l'application pour un réglage de confort.
class OnboardingStorage {
  const OnboardingStorage();

  static const String _cle = 'onboarding_vu';

  /// Tutoriel de l'accueil : culture, photo, onglets.
  static const String coachAccueil = 'coach_accueil_vu';

  /// Bulle sur la confirmation par symptômes, au premier résultat.
  static const String coachConfirmation = 'coach_confirmation_vu';

  Future<bool> hasSeen([String cle = _cle]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(cle) ?? false;
    } on Object {
      return false;
    }
  }

  Future<void> markSeen([String cle = _cle]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(cle, true);
    } on Object {
      // Sans effet : l'explication réapparaîtra au prochain lancement.
    }
  }
}
