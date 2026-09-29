import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/ai_config.dart';
import 'features/onboarding/data/onboarding_storage.dart';

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

  // Lu avant le premier rendu : afficher la coquille puis basculer sur la
  // présentation ferait clignoter l'écran au tout premier lancement.
  final dejaVu = await const OnboardingStorage().hasSeen();

  runApp(AgroLoupeApp(showOnboarding: !dejaVu));
}
