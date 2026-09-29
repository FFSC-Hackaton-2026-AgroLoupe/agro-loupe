import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/ai_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Accès en ligne aux modèles, optionnel : si `.env` manque, l'application
  // démarre quand même et le diagnostic hors-ligne reste entier.
  await AiConfig.load();

  // Firebase sera initialisé ici une fois `flutterfire configure` exécuté :
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // Tant que ce n'est pas fait, l'application démarre sans Firebase et le
  // diagnostic hors-ligne reste pleinement fonctionnel.

  runApp(const AgroLoupeApp());
}
