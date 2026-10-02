import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/diagnosis_colors.dart';
import '../../../../shared/widgets/app_bar_title.dart';
import '../../../diagnosis/models/crop_profile.dart';
import '../../models/treatment.dart';
import '../../state/treatment_provider.dart';
import 'disease_screen.dart';

/// Catalogue des maladies, consultable sans passer par un diagnostic.
///
/// On y vient par curiosité ou pour comparer, pas au bout d'une analyse : les
/// fiches s'ouvrent donc directement, sans étape de confirmation par
/// symptômes.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  Crop _culture = Crop.cassava;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TreatmentProvider>().state;

    return Scaffold(
      appBar: AppBar(title: const AppBarTitle('Catalogue')),
      body: switch (state) {
        TreatmentsLoading() => const Center(child: CircularProgressIndicator()),
        TreatmentsError(:final message) => _Erreur(message: message),
        TreatmentsReady() => _Liste(
          culture: _culture,
          onCulture: (crop) => setState(() => _culture = crop),
        ),
      },
    );
  }
}

class _Liste extends StatelessWidget {
  const _Liste({required this.culture, required this.onCulture});

  final Crop culture;
  final ValueChanged<Crop> onCulture;

  @override
  Widget build(BuildContext context) {
    final profil = CropProfile.of(culture);
    final fiches = context.read<TreatmentProvider>().forCrop(
      profil.displayName,
    );

    return Column(
      children: [
        _Cultures(courante: culture, onCulture: onCulture),
        Expanded(
          child: fiches.isEmpty
              ? const _Vide()
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: fiches.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _Carte(treatment: fiches[i]),
                ),
        ),
      ],
    );
  }
}

/// Choix de la culture, en onglets.
///
/// Les trois cultures seulement : « une autre culture » n'a pas de fiches, il
/// n'y aurait rien à montrer.
class _Cultures extends StatelessWidget {
  const _Cultures({required this.courante, required this.onCulture});

  final Crop courante;
  final ValueChanged<Crop> onCulture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SegmentedButton<Crop>(
        segments: [
          for (final profil in CropProfile.withLocalModel)
            ButtonSegment(value: profil.crop, label: Text(profil.displayName)),
        ],
        selected: {courante},
        onSelectionChanged: (choix) => onCulture(choix.first),
        showSelectedIcon: false,
      ),
    );
  }
}

/// Une maladie dans la liste.
///
/// Trois informations seulement : le nom, la gravité, et la première ligne
/// des symptômes. De quoi reconnaître la bonne fiche sans avoir à l'ouvrir.
class _Carte extends StatelessWidget {
  const _Carte({required this.treatment});

  final Treatment treatment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = context.diagnosisColors;
    final couleur = switch (treatment.severity) {
      'élevée' => couleurs.diseased,
      'moyenne' => couleurs.uncertain,
      'aucune' => couleurs.healthy,
      _ => couleurs.uncertain,
    };

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DiseaseScreen(treatment: treatment),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Un trait de couleur plutôt qu'une pastille : il reste lisible
              // pour qui distingue mal le rouge du vert.
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: couleur,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treatment.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      treatment.severity == 'aucune'
                          ? 'Plante saine'
                          : 'Gravité ${treatment.severity}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: couleur,
                      ),
                    ),
                    if (treatment.symptoms.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        treatment.symptoms.first,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vide extends StatelessWidget {
  const _Vide();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Aucune fiche pour cette culture.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _Erreur extends StatelessWidget {
  const _Erreur({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
