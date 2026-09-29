import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

import '../../../core/errors/app_exception.dart';
import '../models/second_opinion.dart';

/// Une fiche du catalogue, réduite à ce dont le modèle a besoin.
///
/// Type local, volontairement : la feature `diagnosis` n'importe rien de la
/// feature `treatments`. L'appelant fait la conversion.
typedef CatalogEntry = ({String label, String name});

/// Interroge un modèle multimodal en ligne pour un deuxième avis.
///
/// Le modèle **identifie seulement**. Il choisit parmi les étiquettes de nos
/// fiches ou répond « aucune » : il ne peut donc pas inventer de maladie, ni
/// a fortiori de traitement. Les conseils restent ceux des fiches rédigées et
/// vérifiées par l'équipe.
///
/// Ce service est la seule partie de l'application qui parle au fournisseur.
/// Le jour où l'on passe à Firebase AI Logic, où la clé reste côté serveur,
/// il est le seul fichier à réécrire.
class SecondOpinionService {
  SecondOpinionService({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               // Mesuré : 8 à 10 s sur une bonne connexion. En 2G rurale il
               // faut davantage, mais au-delà l'attente n'est plus tenable :
               // mieux vaut un échec clair qu'un écran figé.
               connectTimeout: const Duration(seconds: 10),
               sendTimeout: const Duration(seconds: 30),
               receiveTimeout: const Duration(seconds: 30),
             ),
           );

  final String baseUrl;
  final String apiKey;
  final String model;
  final Dio _dio;

  /// Côté maximal de l'image envoyée.
  ///
  /// Une photo d'appareil pèse plusieurs mégaoctets ; réduite ainsi elle
  /// tombe à quelques dizaines de kilo-octets, sans perte utile pour
  /// reconnaître une tache sur une feuille. C'est la différence entre
  /// quelques secondes et plusieurs minutes sur un réseau faible.
  static const int _coteMax = 768;

  /// Demande un deuxième avis sur [imagePath], pour la culture [cropName].
  ///
  /// [catalog] limite les réponses possibles à nos fiches ; le modèle garde
  /// le droit de n'en retenir aucune.
  Future<SecondOpinion> ask({
    required String imagePath,
    required String cropName,
    required List<CatalogEntry> catalog,
  }) async {
    final bytes = await _lireImage(imagePath);
    // Décodage et redimensionnement dépassent largement les 100 ms sur une
    // photo d'appareil : hors du fil principal, comme pour le modèle local.
    final reduite = await Isolate.run(() => _reduireImage(bytes));

    final reponse = await _appeler(
      prompt: _construirePrompt(cropName, catalog),
      imageBase64: base64Encode(reduite),
    );

    return _lireReponse(reponse);
  }

  Future<Uint8List> _lireImage(String chemin) async {
    try {
      return await File(chemin).readAsBytes();
    } on FileSystemException catch (error) {
      throw PhotoException(
        "La photo n'a pas pu être relue. Reprenez-la.",
        cause: error,
      );
    }
  }

  Future<String> _appeler({
    required String prompt,
    required String imageBase64,
  }) async {
    try {
      final reponse = await _dio.post<Map<String, dynamic>>(
        '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': model,
          'max_tokens': 600,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'},
                },
              ],
            },
          ],
        },
      );

      final choix = (reponse.data?['choices'] as List?)?.firstOrNull;
      final contenu = (choix as Map?)?['message']?['content'];
      if (contenu is! String || contenu.trim().isEmpty) {
        throw const NetworkException.secondOpinionUnreadable();
      }
      return contenu;
    } on DioException catch (error) {
      throw NetworkException.secondOpinionUnavailable(cause: error);
    }
  }

  SecondOpinion _lireReponse(String contenu) {
    // Le modèle encadre parfois sa réponse par un bloc de code.
    var nettoye = contenu.trim();
    if (nettoye.startsWith('```')) {
      nettoye = nettoye.replaceFirst(RegExp(r'^```(json)?'), '');
      nettoye = nettoye.replaceFirst(RegExp(r'```$'), '').trim();
    }

    try {
      final json = jsonDecode(nettoye);
      if (json is! Map<String, dynamic>) {
        throw const NetworkException.secondOpinionUnreadable();
      }
      return SecondOpinion.fromJson(json);
    } on FormatException catch (error) {
      throw NetworkException.secondOpinionUnreadable(cause: error);
    }
  }

  String _construirePrompt(String cropName, List<CatalogEntry> catalog) {
    final liste = catalog
        .map((fiche) => '- ${fiche.label} : ${fiche.name}')
        .join('\n');

    return '''
Tu aides un petit producteur agricole d'Afrique de l'Ouest à identifier ce qui
affecte sa plante, à partir d'une photo de feuille.

L'utilisateur a indiqué cultiver : $cropName.

Choisis au plus une étiquette dans cette liste, et rien d'autre :
$liste

Règles impératives :
1. Tu identifies seulement. Tu ne donnes JAMAIS de conseil de traitement, ni de
   produit, ni de dose. Les conseils viennent de fiches rédigées par des
   agronomes.
2. Si aucune étiquette ne convient, réponds etiquette = null et explique ce que
   tu vois. Répondre « je ne sais pas » est une bonne réponse, bien meilleure
   qu'une étiquette choisie par défaut.
3. Beaucoup de dégâts viennent de ravageurs (thrips, acariens, chenilles) et non
   de maladies. Dis-le si c'est le cas.
4. Pas de pourcentage ni de score : une certitude que tu t'attribues toi-même
   n'est pas comparable à celle d'un modèle calculé.

Réponds uniquement par un objet JSON, sans texte autour :
{
  "etiquette": "<une étiquette de la liste, ou null>",
  "nom": "<nom français de la maladie, ou null>",
  "certitude": "haute | moyenne | faible",
  "observation": "<ce qui est visible sur la feuille, une ou deux phrases, en français simple>",
  "ravageur_plutot_que_maladie": true ou false,
  "raison_si_aucune": "<pourquoi aucune étiquette ne convient, ou null>"
}''';
  }
}

/// Redresse, réduit et réencode la photo. Exécuté dans un isolate.
Uint8List _reduireImage(Uint8List bytes) {
  final decodee = img.decodeImage(bytes);
  if (decodee == null) {
    throw const PhotoException("Cette image n'a pas pu être lue.");
  }

  // L'orientation EXIF n'est pas appliquée aux pixels : sans cela, une photo
  // prise à la verticale part couchée.
  final redressee = img.bakeOrientation(decodee);
  final plusGrandCote = math.max(redressee.width, redressee.height);

  final finale = plusGrandCote <= SecondOpinionService._coteMax
      ? redressee
      : img.copyResize(
          redressee,
          width: redressee.width >= redressee.height
              ? SecondOpinionService._coteMax
              : null,
          height: redressee.height > redressee.width
              ? SecondOpinionService._coteMax
              : null,
          interpolation: img.Interpolation.average,
        );

  return img.encodeJpg(finale, quality: 80);
}
