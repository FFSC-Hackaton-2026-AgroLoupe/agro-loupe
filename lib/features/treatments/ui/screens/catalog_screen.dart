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
    final theme = Theme.of(context);
    final profil = CropProfile.of(culture);
    final fiches = context.read<TreatmentProvider>().forCrop(
      profil.displayName,
    );

    // `unknown` n'est pas une maladie : c'est la réponse du modèle quand il
    // ne reconnaît rien. Elle a sa place dans un diagnostic, pas dans un
    // catalogue que l'on feuillette.
    final consultables = fiches
        .where((fiche) => fiche.modelLabel != 'unknown')
        .toList();

    final maladies = consultables
        .where((fiche) => fiche.severity != 'aucune')
        .toList();
    final saine = consultables
        .where((fiche) => fiche.severity == 'aucune')
        .firstOrNull;

    return ListView(
      padding: EdgeInsets.only(
        bottom: 24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _Cultures(courante: culture, onCulture: onCulture),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            maladies.length > 1
                ? '${maladies.length} maladies répertoriées'
                : '${maladies.length} maladie répertoriée',
            style: theme.textTheme.titleMedium,
          ),
        ),
        for (final fiche in maladies)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _Carte(treatment: fiche),
          ),

        if (saine != null) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'Pour comparer',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // Savoir à quoi ressemble un plant sain aide autant que connaître
            // les maladies : c'est le point de comparaison.
            child: _Carte(treatment: saine),
          ),
        ],
      ],
    );
  }
}

/// Choix de la culture, en vignettes photographiques.
///
/// Les mêmes images que le sélecteur de l'accueil : on reconnaît sa culture
/// sans lire, ce qui compte pour un utilisateur peu à l'aise avec l'écrit.
/// Un bouton segmenté aurait été plus court à écrire, mais il aurait fallu
/// lire trois mots pour choisir.
class _Cultures extends StatelessWidget {
  const _Cultures({required this.courante, required this.onCulture});

  final Crop courante;
  final ValueChanged<Crop> onCulture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        spacing: 10,
        children: [
          for (final profil in CropProfile.withLocalModel)
            Expanded(
              child: _Vignette(
                profil: profil,
                choisie: profil.crop == courante,
                onTap: () => onCulture(profil.crop),
              ),
            ),
        ],
      ),
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette({
    required this.profil,
    required this.choisie,
    required this.onTap,
  });

  final CropProfile profil;
  final bool choisie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final asset = profil.imageAsset;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 76,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: choisie ? colors.primary : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (asset != null)
                Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) =>
                      ColoredBox(color: colors.surfaceContainerHighest),
                )
              else
                ColoredBox(color: colors.surfaceContainerHighest),

              // Le dégradé n'est pas décoratif : sans lui le nom devient
              // illisible sur les parties claires de la photo.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(choisie ? 0xE6000000 : 0xB3000000),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(
                    profil.displayName,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: choisie ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une fiche dans la liste.
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
    final saine = treatment.severity == 'aucune';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DiseaseScreen(treatment: treatment),
          ),
        ),
        // Un bandeau de couleur sur toute la hauteur, plutôt qu'une
        // pastille : il reste lisible pour qui distingue mal le rouge du
        // vert. En bordure plutôt qu'en `IntrinsicHeight` : celui-ci fausse
        // le calcul de largeur des enfants, et faisait déborder l'étiquette
        // de gravité.
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: couleur, width: 5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treatment.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _Gravite(
                        couleur: couleur,
                        texte: saine
                            ? 'Aucun traitement nécessaire'
                            : 'Gravité ${treatment.severity}',
                        icone: saine
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                      ),
                      if (treatment.symptoms.isNotEmpty) ...[
                        const SizedBox(height: 8),
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
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Étiquette de gravité : une couleur **et** un mot, jamais la couleur seule.
class _Gravite extends StatelessWidget {
  const _Gravite({
    required this.couleur,
    required this.texte,
    required this.icone,
  });

  final Color couleur;
  final String texte;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: couleur),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              texte,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: couleur),
            ),
          ),
        ],
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
