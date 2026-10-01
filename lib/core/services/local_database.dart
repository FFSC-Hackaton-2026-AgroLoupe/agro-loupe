import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../errors/app_exception.dart';

/// Base de données locale, sur le téléphone.
///
/// L'historique ne quitte jamais l'appareil : ce sont les photos et les
/// diagnostics de quelqu'un, et rien dans le produit ne justifie de les
/// envoyer ailleurs.
class LocalDatabase {
  LocalDatabase({String fileName = 'agroloupe.db'}) : _fileName = fileName;

  /// Base en mémoire, pour les tests : rien n'est écrit sur le disque.
  LocalDatabase.inMemory() : _fileName = inMemoryDatabasePath;

  final String _fileName;
  Database? _db;

  static const String historyTable = 'history';

  /// Ouvre la base, en la créant au besoin.
  Future<Database> open() async {
    final existante = _db;
    if (existante != null) return existante;

    try {
      final chemin = _fileName == inMemoryDatabasePath
          ? inMemoryDatabasePath
          : p.join(await getDatabasesPath(), _fileName);

      final base = await openDatabase(
        chemin,
        version: 1,
        onCreate: (db, version) => _creer(db),
      );
      _db = base;
      return base;
    } on Object catch (error) {
      throw StorageException.unavailable(cause: error);
    }
  }

  static Future<void> _creer(Database db) async {
    await db.execute('''
      CREATE TABLE $historyTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT NOT NULL,
        crop TEXT NOT NULL,
        diseaseName TEXT NOT NULL,
        modelLabel TEXT NOT NULL,
        confidence REAL NOT NULL,
        createdAt TEXT NOT NULL,
        isConfirmed INTEGER NOT NULL,
        observation TEXT
      )
    ''');

    // L'historique se lit toujours du plus récent au plus ancien.
    await db.execute(
      'CREATE INDEX idx_history_date ON $historyTable (createdAt DESC)',
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
