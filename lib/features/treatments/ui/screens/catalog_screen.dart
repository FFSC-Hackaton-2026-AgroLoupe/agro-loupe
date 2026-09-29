import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_bar_title.dart';

/// Catalogue des maladies, consultable sans passer par un diagnostic.
///
/// Écran provisoire. À remplacer par la liste des maladies de la culture
/// choisie — tâche L1 de Letissia. Les 20 fiches sont déjà chargées en
/// mémoire par `TreatmentProvider` : il s'agit de les afficher, pas de les
/// produire. Modèle à copier : `crop_selector.dart`, dans la feature
/// diagnosis.
///
/// La coquille n'a pas à être modifiée : seul le contenu de ce fichier
/// change.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const AppBarTitle('Catalogue')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 20),
              Text(
                'Les maladies, culture par culture',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Vous pourrez bientôt consulter les symptômes et les '
                'traitements sans avoir à photographier une feuille.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
