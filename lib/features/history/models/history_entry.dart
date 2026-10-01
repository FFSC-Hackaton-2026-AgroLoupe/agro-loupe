import 'package:flutter/foundation.dart';

import '../../diagnosis/models/crop_profile.dart';
import '../../treatments/models/treatment.dart';

/// Entrée d'historique représentant un diagnostic passé réalisé par l'utilisateur.
///
/// Modèle immuable stocké localement sur l'appareil (SQLite).
/// Les photos et données sensibles ne quittent jamais le téléphone.
@immutable
class HistoryEntry {
  const HistoryEntry({
    this.id,
    required this.imagePath,
    required this.crop,
    required this.diseaseName,
    required this.modelLabel,
    required this.confidence,
    required this.createdAt,
    required this.isConfirmed,
    this.treatment,
    this.observation,
  });

  final int? id;

  /// Chemin de la photo sur l'appareil. L'image ne quitte jamais le téléphone.
  final String imagePath;

  final Crop crop;

  /// Nom affiché en français courant (ex. « Mildiou de la tomate »).
  final String diseaseName;

  /// Étiquette brute issue du modèle IA (clé de jointure vers les fiches).
  final String modelLabel;

  /// Degré de confiance (0.0 à 1.0).
  final double confidence;

  final DateTime createdAt;

  /// Vrai si le producteur a confirmé les symptômes au champ, faux si abandonné.
  final bool isConfirmed;

  /// Fiche complète associée, si le diagnostic a été confirmé.
  final Treatment? treatment;

  final String? observation;

  int get percent => (confidence * 100).round();


  /// Date formatée en français clair (ex. « 26 sept. 2026 à 14:30 »).
  String get formattedDate {
    const mois = [
      '',
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    final jour = createdAt.day;
    final nomMois = mois[createdAt.month];
    final annee = createdAt.year;
    final heure = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$jour $nomMois $annee à $heure:$minute';
  }

  /// Nom affiché de la culture en français.
  String get cropDisplayName => CropProfile.of(crop).displayName;

  HistoryEntry copyWith({
    int? id,
    String? imagePath,
    Crop? crop,
    String? diseaseName,
    String? modelLabel,
    double? confidence,
    DateTime? createdAt,
    bool? isConfirmed,
    Treatment? treatment,
    String? observation,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      crop: crop ?? this.crop,
      diseaseName: diseaseName ?? this.diseaseName,
      modelLabel: modelLabel ?? this.modelLabel,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      treatment: treatment ?? this.treatment,
      observation: observation ?? this.observation,
    );
  }

  Map<String, Object?> toJson() => {
    if (id != null) 'id': id,
    'imagePath': imagePath,
    'crop': crop.name,
    'diseaseName': diseaseName,
    'modelLabel': modelLabel,
    'confidence': confidence,
    'createdAt': createdAt.toIso8601String(),
    'isConfirmed': isConfirmed ? 1 : 0,
    if (observation != null) 'observation': observation,
  };

  factory HistoryEntry.fromJson(
    Map<String, Object?> json, {
    Treatment? treatment,
  }) {
    return HistoryEntry(
      id: json['id'] as int?,
      imagePath: json['imagePath']! as String,
      crop: Crop.values.byName(json['crop']! as String),
      diseaseName: json['diseaseName']! as String,
      modelLabel: json['modelLabel']! as String,
      confidence: (json['confidence']! as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']! as String),
      isConfirmed: json['isConfirmed'] == 1 || json['isConfirmed'] == true,
      treatment: treatment,
      observation: json['observation'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          imagePath == other.imagePath &&
          crop == other.crop &&
          diseaseName == other.diseaseName &&
          modelLabel == other.modelLabel &&
          confidence == other.confidence &&
          createdAt == other.createdAt &&
          isConfirmed == other.isConfirmed &&
          observation == other.observation;

  @override
  int get hashCode => Object.hash(
    id,
    imagePath,
    crop,
    diseaseName,
    modelLabel,
    confidence,
    createdAt,
    isConfirmed,
    observation,
  );
}
