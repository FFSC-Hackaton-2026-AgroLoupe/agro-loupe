import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../models/crop_profile.dart';
import '../models/prediction.dart';

/// Exécute le diagnostic sur l'appareil, sans aucun accès au réseau.
///
/// Le service est indépendant de la culture : tout ce qui varie d'un modèle à
/// l'autre est décrit par un [CropProfile]. Les interpréteurs sont mis en cache
/// par fichier de modèle, si bien que la tomate et le maïs — qui partagent le
/// même modèle — ne le chargent qu'une fois.
class ClassifierService {
  final Map<String, Interpreter> _interpreters = {};
  final Map<String, List<String>> _labels = {};

  /// Charge à l'avance le modèle d'une culture.
  ///
  /// À appeler pendant que l'utilisateur cadre sa photo : le chargement prend
  /// plusieurs centaines de millisecondes, autant ne pas les lui faire attendre
  /// après le déclenchement.
  Future<void> warmUp(CropProfile profile) async {
    await _interpreterFor(profile);
    await _labelsFor(profile);
  }

  /// Analyse [imageBytes] et renvoie les [topK] hypothèses les plus probables,
  /// de la plus forte à la plus faible.
  ///
  /// Les deux modèles ne parlent pas le même langage : CropNet est entièrement
  /// quantifié en entiers 8 bits, PlantVillage travaille en flottants. Le type
  /// attendu est lu sur le tenseur lui-même plutôt que déclaré quelque part,
  /// pour qu'il ne puisse jamais diverger du fichier réellement embarqué.
  ///
  /// Aucun softmax n'est appliqué : après déquantification, les deux modèles
  /// renvoient déjà des probabilités dont la somme vaut 1.
  Future<List<Prediction>> classify({
    required Uint8List imageBytes,
    required CropProfile profile,
    int topK = 3,
  }) async {
    final interpreter = await _interpreterFor(profile);
    final labels = await _labelsFor(profile);

    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    // Côté du carré attendu, lu sur le modèle : [1, côté, côté, 3].
    final size = inputTensor.shape[1];

    // Le décodage et le redimensionnement d'une photo d'appareil dépassent
    // largement les 100 ms : on les sort du fil de l'interface.
    final rgb = await Isolate.run(() => _prepareImage(imageBytes, size));

    final quantizedInput = inputTensor.type == TensorType.uint8;
    final quantizedOutput = outputTensor.type == TensorType.uint8;

    final input = quantizedInput
        ? _buildInput(rgb, size, (value) => value)
        : _buildInput(rgb, size, (value) => value / 255.0);
    final output = quantizedOutput
        ? List.generate(1, (_) => List<int>.filled(labels.length, 0))
        : List.generate(1, (_) => List<double>.filled(labels.length, 0));

    try {
      interpreter.run(input, output);
    } on Object catch (error) {
      throw ModelException.unavailable(cause: error);
    }

    final scores = quantizedOutput
        ? dequantize(
            (output as List<List<int>>)[0],
            outputTensor.params.scale,
            outputTensor.params.zeroPoint,
          )
        : (output as List<List<double>>)[0];

    return rankPredictions(scores, labels, profile, topK);
  }

  /// Construit le tenseur d'entrée [1, côté, côté, 3] en appliquant [convert]
  /// à chaque composante : identité pour un modèle quantifié, division par 255
  /// pour un modèle en flottants.
  List<List<List<List<num>>>> _buildInput(
    Uint8List rgb,
    int size,
    num Function(int value) convert,
  ) {
    return List.generate(
      1,
      (_) => List.generate(
        size,
        (y) => List.generate(size, (x) {
          final offset = (y * size + x) * 3;
          return [
            convert(rgb[offset]),
            convert(rgb[offset + 1]),
            convert(rgb[offset + 2]),
          ];
        }),
      ),
    );
  }

  Future<Interpreter> _interpreterFor(CropProfile profile) async {
    final cached = _interpreters[profile.modelAsset];
    if (cached != null) return cached;
    try {
      final interpreter = await Interpreter.fromAsset(profile.modelAsset);
      _interpreters[profile.modelAsset] = interpreter;
      return interpreter;
    } on Object catch (error) {
      throw ModelException.unavailable(cause: error);
    }
  }

  Future<List<String>> _labelsFor(CropProfile profile) async {
    final cached = _labels[profile.labelsAsset];
    if (cached != null) return cached;
    try {
      final raw = await rootBundle.loadString(profile.labelsAsset);
      final labels = raw
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
      if (labels.isEmpty) {
        throw const ModelException.unavailable();
      }
      _labels[profile.labelsAsset] = labels;
      return labels;
    } on ModelException {
      rethrow;
    } on Object catch (error) {
      throw ModelException.unavailable(cause: error);
    }
  }

  /// Libère les interpréteurs natifs.
  void close() {
    for (final interpreter in _interpreters.values) {
      interpreter.close();
    }
    _interpreters.clear();
    _labels.clear();
  }
}

/// Décode, redresse et redimensionne la photo, puis rend ses octets RGB.
///
/// Exécutée dans un isolate : cette fonction doit rester au niveau du fichier
/// et ne dépendre d'aucun état de l'application.
Uint8List _prepareImage(Uint8List bytes, int size) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const PhotoException(
      "Cette image n'a pas pu être lue. Reprenez la photo.",
    );
  }

  // Les photos d'appareil portent leur orientation dans les métadonnées EXIF.
  // Sans ce redressement, le modèle analyserait une feuille couchée.
  final oriented = img.bakeOrientation(decoded);
  final resized = img.copyResize(
    oriented,
    width: size,
    height: size,
    interpolation: img.Interpolation.average,
  );

  final rgb = Uint8List(size * size * 3);
  var offset = 0;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final pixel = resized.getPixel(x, y);
      rgb[offset++] = pixel.r.toInt();
      rgb[offset++] = pixel.g.toInt();
      rgb[offset++] = pixel.b.toInt();
    }
  }
  return rgb;
}

/// Ne conserve que les classes de la culture choisie, renormalise, puis trie.
///
/// La renormalisation compte : sur une feuille de tomate, le modèle partagé
/// place parfois une maladie du pommier en deuxième position. L'écarter puis
/// répartir sa probabilité sur les classes pertinentes rend au bon résultat la
/// confiance qui lui revient — une douzaine de points, mesurés sur une photo
/// réelle de mildiou.
@visibleForTesting
List<Prediction> rankPredictions(
  List<double> scores,
  List<String> labels,
  CropProfile profile,
  int topK,
) {
  final prefix = profile.labelPrefix;
  final kept = <int>[
    for (var i = 0; i < labels.length; i++)
      if (prefix == null || labels[i].startsWith(prefix)) i,
  ];

  if (kept.isEmpty) {
    throw ModelException(
      "Les étiquettes du modèle ne correspondent pas à la culture "
      '« ${profile.displayName} ».',
    );
  }

  final total = kept.fold<double>(0, (sum, i) => sum + scores[i]);
  final predictions = [
    for (final i in kept)
      Prediction(
        label: labels[i],
        confidence: total > 0 ? scores[i] / total : 0,
      ),
  ]..sort((a, b) => b.confidence.compareTo(a.confidence));

  return predictions.take(topK).toList(growable: false);
}

/// Ramène une sortie quantifiée en probabilités réelles.
///
/// Un modèle quantifié range ses sorties dans des entiers 0-255 ; la valeur
/// réelle vaut `scale × (entier − zéro)`. Sans cette étape, les « probabilités »
/// seraient des entiers bruts et le seuil de confiance n'aurait aucun sens.
@visibleForTesting
List<double> dequantize(List<int> raw, double scale, int zeroPoint) => [
  for (final value in raw) scale * (value - zeroPoint),
];
