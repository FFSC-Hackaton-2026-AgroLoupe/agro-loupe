import 'package:flutter/material.dart';

import '../../models/treatment.dart';
import '../widgets/disease_header.dart';
import '../widgets/treatment_sections.dart';

/// Fiche consultée depuis le catalogue.
///
/// On lit par curiosité : les symptômes et les conseils s'affichent tout de
/// suite, sans étape pour confirmer le diagnostic.
class DiseaseScreen extends StatelessWidget {
  const DiseaseScreen({super.key, required this.treatment});

  /// Fiche à afficher. L'écran n'en charge pas d'autre.
  final Treatment treatment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          treatment.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: DiseaseHeader(treatment: treatment),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
              children: [
                SymptomsPanel(treatment: treatment),
                TreatmentSheetView(treatment: treatment),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
