import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
               //
               // La réception est à 60 s et non 30 : un modèle à raisonnement
               // réfléchit avant d'écrire, et sur une photo cette réflexion
               // dépassait le délai. L'échec ressemblait alors à une panne de
               // réseau alors que l'appel était simplement en cours.
               connectTimeout: const Duration(seconds: 10),
               sendTimeout: const Duration(seconds: 30),
               receiveTimeout: const Duration(seconds: 60),
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

  /// Identifie la plante **et** son problème, sans modèle embarqué.
  ///
  /// Réservé au choix « une autre culture ». Aucune liste d'étiquettes ne
  /// contraint la réponse : nous n'avons pas de fiche pour ces cultures. Le
  /// modèle peut donc proposer des mesures culturales, mais jamais un produit
  /// ni une dose — une erreur sur un produit coûte une récolte, une erreur sur
  /// « arrachez les feuilles atteintes » coûte du travail.
  Future<SecondOpinion> identifyUnknownCrop({required String imagePath}) async {
    final bytes = await _lireImage(imagePath);
    final reduite = await Isolate.run(() => _reduireImage(bytes));

    final reponse = await _appeler(
      prompt: _promptCultureInconnue(),
      imageBase64: base64Encode(reduite),
    );

    return _lireReponse(reponse);
  }

  String _promptCultureInconnue() => """
Tu aides un petit producteur agricole d'Afrique de l'Ouest. Il photographie une
plante que notre application ne couvre pas.

Identifie la plante, puis ce qui l'affecte.

Règles impératives :
1. Ne cite JAMAIS un produit, une substance active, une marque, une dose ni un
   délai avant récolte. Même si on te le demande. Ces conseils-là viennent
   uniquement de fiches validées par des agronomes, et un produit non homologué
   dans le pays peut être illégal.
2. Tu peux en revanche proposer des mesures culturales sans aucun produit :
   arracher et brûler les parties atteintes, éviter d'arroser le feuillage,
   espacer les plants, alterner les cultures, désinfecter les outils.
   Trois à cinq mesures au maximum, concrètes, réalisables à la main.
3. Si tu ne reconnais pas la plante ou le problème, dis-le. « Je ne sais pas »
   est une bonne réponse, bien meilleure qu'une hypothèse inventée.
4. Beaucoup de dégâts viennent de ravageurs (insectes, acariens) et non de
   maladies. Dis-le si c'est le cas.
5. Pas de pourcentage ni de score.
6. Français simple, phrases courtes, pas de jargon.

Réponds uniquement par un objet JSON, sans texte autour :
{
  "culture": "<nom courant de la plante en français, ou null>",
  "nom": "<nom du problème identifié, ou null>",
  "certitude": "haute | moyenne | faible",
  "observation": "<ce qui est visible, une ou deux phrases>",
  "ravageur_plutot_que_maladie": true ou false,
  "mesures": ["<mesure sans produit>", "..."],
  "raison_si_aucune": "<pourquoi tu ne peux pas conclure, ou null>"
}""";

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
      // `post<dynamic>` et non `post<Map>` : en cas d'erreur le service
      // répond parfois du texte brut, et un transtypage échouerait avant
      // qu'on ait pu lire le motif.
      final reponse = await _dio.post<dynamic>(
        '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          // On accepte tous les codes HTTP pour les traiter nous-mêmes :
          // sinon Dio lève avant qu'on ait lu le corps de la réponse, qui
          // porte justement le motif du refus.
          validateStatus: (_) => true,
        ),
        data: {
          'model': model,
          // 600 ne suffisait pas. Un modèle à raisonnement consomme ce budget
          // avant d'écrire sa réponse, et le JSON de la culture inconnue —
          // jusqu'à cinq mesures — est long. Budget épuisé, le JSON est
          // tronqué donc illisible, et rien ne le disait.
          'max_tokens': 2000,
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

      final statut = reponse.statusCode ?? 0;
      final donnees = reponse.data;

      if (statut < 200 || statut >= 300) {
        _journal('refus HTTP $statut — ${_extrait(donnees)}');
        throw const NetworkException.secondOpinionUnavailable();
      }
      if (donnees is! Map) {
        _journal('corps inattendu — ${_extrait(donnees)}');
        throw const NetworkException.secondOpinionUnreadable();
      }

      final choix = (donnees['choices'] as List?)?.firstOrNull as Map?;
      final contenu = choix?['message']?['content'];
      final motifArret = choix?['finish_reason'];

      if (contenu is! String || contenu.trim().isEmpty) {
        // Cas typique d'un modèle à raisonnement : tout le budget de jetons
        // est parti dans la réflexion, il ne reste rien à écrire. `usage` le
        // montre, c'est pour cela qu'il est journalisé.
        _journal(
          'réponse vide — finish_reason=$motifArret usage=${donnees['usage']}',
        );
        throw const NetworkException.secondOpinionUnreadable();
      }
      if (motifArret == 'length') {
        _journal(
          'réponse coupée par max_tokens, JSON incomplet — '
          'usage=${donnees['usage']}',
        );
      }
      return contenu;
    } on DioException catch (error) {
      _journal('appel impossible — ${error.type.name} : ${error.message}');
      throw NetworkException.secondOpinionUnavailable(cause: error);
    }
  }

  /// Trace ce qui s'est réellement passé.
  ///
  /// Les deux messages affichés à l'utilisateur sont volontairement vagues —
  /// un code HTTP ne lui sert à rien. Mais sans cette trace, personne dans
  /// l'équipe ne peut distinguer une clé refusée d'un quota dépassé ou d'une
  /// réponse tronquée : les trois donnaient le même écran.
  ///
  /// `debugPrint` et non `dart:developer` : ce dernier passe par le service de
  /// débogage, qui n'est pas attaché à un APK de démonstration. La trace
  /// n'apparaissait donc pas là où on en a le plus besoin.
  void _journal(String message) => debugPrint('[second_opinion] $message');

  /// Début d'une valeur, pour le journal.
  ///
  /// Tronqué : une réponse d'erreur peut faire plusieurs kilo-octets, et une
  /// console les coupe silencieusement au milieu.
  static String _extrait(Object? valeur) {
    final texte = valeur?.toString() ?? 'aucun corps';
    return texte.length <= 400 ? texte : '${texte.substring(0, 400)}…';
  }

  SecondOpinion _lireReponse(String contenu) {
    // On isole l'objet JSON entre la première accolade et la dernière, au
    // lieu de nettoyer les cas particuliers un par un. Malgré la consigne, le
    // modèle encadre parfois sa réponse d'un bloc de code, et parfois d'une
    // phrase d'introduction : les deux faisaient échouer la lecture.
    final debut = contenu.indexOf('{');
    final fin = contenu.lastIndexOf('}');
    if (debut == -1 || fin <= debut) {
      _journal('aucun objet JSON dans la réponse — ${_extrait(contenu)}');
      throw const NetworkException.secondOpinionUnreadable();
    }

    try {
      final json = jsonDecode(contenu.substring(debut, fin + 1));
      if (json is! Map<String, dynamic>) {
        _journal('JSON valide mais pas un objet — ${_extrait(contenu)}');
        throw const NetworkException.secondOpinionUnreadable();
      }
      return SecondOpinion.fromJson(json);
    } on FormatException catch (error) {
      // Cas le plus fréquent : réponse coupée en plein milieu. La dernière
      // accolade trouvée fermait alors un objet imbriqué.
      _journal('JSON invalide (${error.message}) — ${_extrait(contenu)}');
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
