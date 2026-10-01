import '../../../core/errors/app_exception.dart';
import '../../../core/services/local_database.dart';
import '../../treatments/models/treatment.dart';
import '../models/history_entry.dart';

/// Retrouve une fiche à partir de son étiquette de modèle.
///
/// Passé en fonction plutôt qu'en dépendance sur `TreatmentProvider` : la
/// fiche n'est pas stockée avec l'entrée, elle est retrouvée à la lecture.
/// Une correction venue de Firestore profite donc aussi à l'historique.
typedef TreatmentLookup = Treatment? Function(String modelLabel);

/// Lit et écrit l'historique des diagnostics, en local.
class HistoryRepository {
  HistoryRepository(this._database, {TreatmentLookup? lookup})
    : _lookup = lookup;

  final LocalDatabase _database;
  final TreatmentLookup? _lookup;

  /// Toutes les entrées, de la plus récente à la plus ancienne.
  Future<List<HistoryEntry>> all() async {
    try {
      final db = await _database.open();
      final lignes = await db.query(
        LocalDatabase.historyTable,
        orderBy: 'createdAt DESC',
      );
      return lignes
          .map(
            (ligne) => HistoryEntry.fromJson(
              ligne,
              treatment: _lookup?.call(ligne['modelLabel']! as String),
            ),
          )
          .toList(growable: false);
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw StorageException.unavailable(cause: error);
    }
  }

  /// Enregistre un diagnostic et renvoie l'entrée telle qu'elle est stockée.
  Future<HistoryEntry> add(HistoryEntry entry) async {
    try {
      final db = await _database.open();
      final id = await db.insert(LocalDatabase.historyTable, entry.toJson());
      return entry.copyWith(id: id);
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw StorageException.unavailable(cause: error);
    }
  }

  Future<void> remove(int id) async {
    try {
      final db = await _database.open();
      await db.delete(
        LocalDatabase.historyTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw StorageException.unavailable(cause: error);
    }
  }
}
