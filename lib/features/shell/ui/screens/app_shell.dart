import 'package:flutter/material.dart';

import '../../../diagnosis/ui/screens/home_screen.dart';
import '../../../history/ui/screens/history_screen.dart';
import '../../../treatments/ui/screens/catalog_screen.dart';

/// Coquille de l'application : les trois onglets et leur barre de navigation.
///
/// Un seul onglet est construit à la fois, volontairement. L'état ne vit pas
/// dans les widgets mais dans les providers : un diagnostic en cours survit
/// donc à un aller-retour vers un autre onglet sans qu'il faille maintenir
/// les écrans en vie.
///
/// Garder les trois écrans montés — avec un `IndexedStack` — aurait un effet
/// de bord discret : le `PopScope` de [HomeScreen] resterait enregistré
/// depuis les autres onglets, et le bouton retour du téléphone reculerait
/// dans un diagnostic que l'utilisateur n'a plus sous les yeux.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _onglet = 0;

  void _aller(int index) => setState(() => _onglet = index);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Depuis un autre onglet, le bouton retour ramène au diagnostic au lieu
      // de quitter l'application. Sur l'onglet Diagnostic, c'est le `PopScope`
      // de [HomeScreen] qui prend le relais pour remonter d'une étape.
      canPop: _onglet == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _aller(0);
      },
      child: Scaffold(
        body: switch (_onglet) {
          0 => const HomeScreen(),
          1 => const CatalogScreen(),
          _ => const HistoryScreen(),
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: _onglet,
          onDestinationSelected: _aller,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.eco_outlined),
              selectedIcon: Icon(Icons.eco),
              label: 'Diagnostic',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Catalogue',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Historique',
            ),
          ],
        ),
      ),
    );
  }
}
