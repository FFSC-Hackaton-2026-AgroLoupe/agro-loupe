import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Accès en ligne aux modèles, en **développement uniquement**.
///
/// Les valeurs viennent de `.env`, qui n'est pas commité. Ce fichier est
/// volontairement la seule partie de l'application qui connaisse une clé :
/// le jour où l'on passe à Firebase AI Logic, où la clé reste côté serveur,
/// il est le seul à changer.
///
/// Avertissement : un `.env` déclaré dans les assets est **embarqué dans
/// l'APK** et s'en extrait en clair. Tant que cette classe est utilisée,
/// aucun APK ne doit être diffusé, jury compris.
abstract final class AiConfig {
  /// Charge `.env` si présent.
  ///
  /// N'échoue jamais : le diagnostic hors-ligne est le cœur du produit et il
  /// ne doit pas dépendre d'un fichier de configuration. Sans `.env`,
  /// [isConfigured] vaut `false` et le deuxième avis reste simplement caché.
  static Future<void> load() async {
    try {
      await dotenv.load();
    } catch (_) {
      // Fichier absent ou illisible : on continue sans accès en ligne.
    }
  }

  static String _read(String key) => dotenv.maybeGet(key)?.trim() ?? '';

  /// Clé fournie par Rodium AI.
  static String get apiKey => _read('RODIUM_API_KEY');

  /// Racine de l'API, sans slash final.
  static String get baseUrl => _read('RODIUM_BASE_URL');

  /// Modèle multimodal interrogé pour le deuxième avis.
  static String get model => _read('RODIUM_MODEL');

  /// `true` seulement si les trois valeurs sont renseignées.
  ///
  /// L'interface s'en sert pour n'afficher le deuxième avis que lorsqu'il
  /// peut réellement aboutir.
  static bool get isConfigured =>
      apiKey.isNotEmpty && baseUrl.isNotEmpty && model.isNotEmpty;
}
