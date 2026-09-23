import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase sera initialisé ici une fois `flutterfire configure` exécuté :
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // Tant que ce n'est pas fait, l'application démarre sans Firebase et le
  // diagnostic hors-ligne reste pleinement fonctionnel.

  runApp(const AgroLoupeApp());
}
