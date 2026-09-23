import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/services/connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'features/diagnosis/ui/screens/home_screen.dart';

/// Racine de l'application : injection des dépendances, puis thème et écrans.
class AgroLoupeApp extends StatelessWidget {
  const AgroLoupeApp({super.key, this.connectivityService});

  /// Permet aux tests de fournir un service simulé. En production, laisser
  /// `null` : l'application crée elle-même l'instance réelle.
  final ConnectivityService? connectivityService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Services transverses (une seule instance pour toute l'application).
        Provider<ConnectivityService>(
          create: (_) => connectivityService ?? ConnectivityService(),
        ),

        // 2. Flux dérivés d'un service, lus directement par l'interface.
        //    `initialData` est optimiste : tant qu'on ne sait pas, on n'affiche
        //    aucun avertissement plutôt qu'un bandeau qui clignote au démarrage.
        StreamProvider<ConnectionStatus>(
          create: (context) =>
              context.read<ConnectivityService>().onStatusChanged,
          initialData: ConnectionStatus.online,
        ),

        // 3. Repositories et états des fonctionnalités : à ajouter ici au fur
        //    et à mesure (diagnosis, treatments, history).
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
