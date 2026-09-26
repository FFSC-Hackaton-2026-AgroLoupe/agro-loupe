import 'package:agro_loupe/features/diagnosis/data/classifier_service.dart';
import 'package:agro_loupe/features/diagnosis/models/crop_profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les 38 étiquettes du modèle partagé, dans l'ordre de ses sorties.
/// Seules celles qui interviennent dans les tests portent leur vrai nom.
List<String> _plantVillageLabels() {
  final labels = List.generate(38, (i) => 'Autre___classe_$i');
  labels[0] = 'Apple___Apple_scab';
  labels[1] = 'Apple___Black_rot';
  labels[7] = 'Corn_(maize)___Cercospora_leaf_spot';
  labels[9] = 'Corn_(maize)___Northern_Leaf_Blight';
  labels[10] = 'Corn_(maize)___healthy';
  labels[8] = 'Corn_(maize)___Common_rust_';
  labels[25] = 'Pepper_bell___healthy';
  labels[29] = 'Tomato___Early_blight';
  labels[30] = 'Tomato___Late_blight';
  labels[37] = 'Tomato___healthy';
  return labels;
}

void main() {
  group('filtrage par culture', () {
    test('écarte les espèces étrangères et renormalise', () {
      // Sorties réellement mesurées sur une photo de mildiou de tomate.
      final scores = List<double>.filled(38, 0);
      scores[30] = 0.776; // Tomato___Late_blight
      scores[0] = 0.119; // Apple___Apple_scab
      scores[29] = 0.092; // Tomato___Early_blight
      scores[25] = 0.009; // Pepper_bell___healthy
      scores[1] = 0.002; // Apple___Black_rot

      final top = rankPredictions(
        scores,
        _plantVillageLabels(),
        CropProfile.tomato,
        3,
      );

      expect(top.first.label, 'Tomato___Late_blight');
      // Le pommier écarté, le mildiou remonte de 77,6 % à environ 89 %.
      expect(top.first.confidence, closeTo(0.894, 0.005));
      expect(top.first.isUncertain, isFalse);
      expect(
        top.map((p) => p.label),
        everyElement(startsWith('Tomato')),
        reason: 'aucune espèce étrangère ne doit subsister',
      );
    });

    test('le maïs et la tomate partagent le modèle sans se mélanger', () {
      final scores = List<double>.filled(38, 0);
      scores[9] = 0.6; // Corn_(maize)___Northern_Leaf_Blight
      scores[30] = 0.4; // Tomato___Late_blight

      final mais = rankPredictions(
        scores,
        _plantVillageLabels(),
        CropProfile.maize,
        3,
      );
      expect(mais.first.label, 'Corn_(maize)___Northern_Leaf_Blight');
      expect(mais.first.confidence, closeTo(1.0, 0.001));

      final tomate = rankPredictions(
        scores,
        _plantVillageLabels(),
        CropProfile.tomato,
        3,
      );
      expect(tomate.first.label, 'Tomato___Late_blight');
      expect(tomate.first.confidence, closeTo(1.0, 0.001));
    });

    test('le manioc garde toutes ses classes, y compris « inconnu »', () {
      final labels = ['cbb', 'cbsd', 'cgm', 'cmd', 'healthy', 'unknown'];
      final scores = [0.02, 0.03, 0.05, 0.10, 0.10, 0.70];

      final top = rankPredictions(scores, labels, CropProfile.cassava, 3);

      expect(top.first.label, 'unknown');
      // Aucun filtre : les scores passent inchangés.
      expect(top.first.confidence, closeTo(0.70, 0.001));
      expect(top.length, 3);
    });
  });

  group('seuil de confiance', () {
    test('un score sous 60 % est signalé comme incertain', () {
      final labels = ['cbb', 'cbsd', 'cgm', 'cmd', 'healthy', 'unknown'];
      final scores = [0.55, 0.20, 0.10, 0.08, 0.05, 0.02];

      final top = rankPredictions(scores, labels, CropProfile.cassava, 1);

      expect(top.first.confidence, closeTo(0.55, 0.001));
      expect(top.first.isUncertain, isTrue);
      expect(top.first.percent, 55);
    });
  });

  group('robustesse', () {
    test('des scores tous nuls ne provoquent pas de division par zéro', () {
      final top = rankPredictions(
        List<double>.filled(38, 0),
        _plantVillageLabels(),
        CropProfile.tomato,
        3,
      );

      expect(top, isNotEmpty);
      expect(top.every((p) => p.confidence == 0), isTrue);
      expect(top.first.isUncertain, isTrue);
    });

    test('des étiquettes sans rapport avec la culture sont refusées', () {
      expect(
        () => rankPredictions([1.0], ['cbb'], CropProfile.tomato, 1),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('déquantification', () {
    // Paramètres réels de la sortie de CropNet, relevés sur le fichier.
    const scale = 0.00390625; // 1/256
    const zeroPoint = 0;

    test('ramène des entiers 0-255 en probabilités', () {
      final p = dequantize([255, 128, 0], scale, zeroPoint);

      expect(p[0], closeTo(0.996, 0.001));
      expect(p[1], closeTo(0.500, 0.001));
      expect(p[2], 0);
    });

    test('une sortie complète somme bien à 1', () {
      // Distribution mesurée sur une photo de tomates : « unknown » à 99,6 %.
      final p = dequantize([0, 0, 0, 0, 1, 255], scale, zeroPoint);

      expect(p.reduce((a, b) => a + b), closeTo(1.0, 0.01));
      expect(p.last, greaterThan(0.99));
    });

    test('tient compte du point zéro non nul', () {
      final p = dequantize([128], 0.007874015718698502, 128);

      expect(p.single, closeTo(0, 0.0001));
    });
  });
}
