/// Noms français des maladies, pour l'affichage.
///
/// Table **provisoire** : les noms définitifs viendront des fiches Firestore,
/// avec leurs symptômes et leurs traitements. Elle n'existe que pour ne pas
/// montrer `Tomato___Late_blight` à un agriculteur en attendant, et servira
/// ensuite de repli hors-ligne si une fiche n'a jamais été mise en cache.
///
/// Elle ne contient que des **noms**, jamais de conseil agronomique : le
/// contenu des fiches est rédigé et vérifié par l'équipe (voir la règle 1 de
/// la section 6 du cahier des charges).
abstract final class DiseaseNames {
  static const Map<String, String> _french = {
    // Manioc — CropNet
    'cbb': 'Bactériose du manioc',
    'cbsd': 'Striure brune du manioc',
    'cgm': 'Acarien vert du manioc',
    'cmd': 'Mosaïque africaine du manioc',
    'healthy': 'Plant sain',
    'unknown': 'Plante non reconnue',

    // Tomate — PlantVillage
    'Tomato___Bacterial_spot': 'Bactériose (taches bactériennes)',
    'Tomato___Early_blight': 'Alternariose',
    'Tomato___Late_blight': 'Mildiou',
    'Tomato___Leaf_Mold': 'Cladosporiose',
    'Tomato___Septoria_leaf_spot': 'Septoriose',
    'Tomato___Spider_mites Two-spotted_spider_mite':
        'Acariens (tétranyque tisserand)',
    'Tomato___Target_Spot': 'Corynesporiose',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus':
        'Virus des feuilles jaunes en cuillère',
    'Tomato___Tomato_mosaic_virus': 'Virus de la mosaïque de la tomate',
    'Tomato___healthy': 'Plant sain',

    // Maïs — PlantVillage
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot':
        'Cercosporiose (taches grises)',
    'Corn_(maize)___Common_rust_': 'Rouille commune',
    'Corn_(maize)___Northern_Leaf_Blight': 'Helminthosporiose',
    'Corn_(maize)___healthy': 'Plant sain',
  };

  /// Nom affichable. À défaut de traduction, on nettoie l'étiquette brute
  /// plutôt que de montrer un identifiant technique.
  static String of(String label) =>
      _french[label] ?? label.split('___').last.replaceAll('_', ' ');

  /// La feuille est saine : ce n'est pas une maladie à traiter.
  static bool isHealthy(String label) => label.endsWith('healthy');

  /// Le modèle déclare ne pas reconnaître l'image.
  static bool isUnknown(String label) => label == 'unknown';
}
