import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/ai_config.dart';
import 'firebase_options.dart';
import 'features/onboarding/data/onboarding_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Accès en ligne aux modèles, optionnel : si `.env` manque, l'application
  // démarre quand même et le diagnostic hors-ligne reste entier.
  await AiConfig.load();

  // Firebase ne sert qu'à corriger les fiches et, plus tard, au deuxième
  // avis en ligne. Son échec ne doit donc jamais empêcher l'application de
  // démarrer : le diagnostic et les fiches embarquées n'en dépendent pas.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object catch (error) {
    debugPrint('Firebase indisponible, on continue sans : $error');
  }

  // Lu avant le premier rendu : afficher la coquille puis basculer sur la
  // présentation ferait clignoter l'écran au tout premier lancement.
  final dejaVu = await const OnboardingStorage().hasSeen();

  runApp(AgroLoupeApp(showOnboarding: !dejaVu));
}
