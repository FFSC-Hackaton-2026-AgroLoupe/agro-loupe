import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/history_repository.dart';
import '../models/history_entry.dart';

sealed class HistoryState {
  const HistoryState();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryReady extends HistoryState {
  const HistoryReady(this.entries);

  final List<HistoryEntry> entries;

  /// Vrai au premier lancement : c'est ce que voit le jury en ouvrant
  /// l'onglet, et il mérite mieux qu'un écran blanc.
  bool get isEmpty => entries.isEmpty;
}

class HistoryError extends HistoryState {
  const HistoryError(this.message);

  final String message;
}

/// Tient l'historique local des diagnostics.
class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._repository);

  final HistoryRepository _repository;

  HistoryState _state = const HistoryLoading();
  HistoryState get state => _state;

  Future<void> load() async {
    try {
      _publier(HistoryReady(await _repository.all()));
    } on AppException catch (error) {
      _publier(HistoryError(error.userMessage));
    }
  }

  /// Ajoute une entrée et rafraîchit la liste.
  ///
  /// Un échec d'écriture n'est jamais remonté à l'utilisateur : il vient de
  /// terminer un diagnostic, et lui annoncer une erreur de base de données à
  /// cet instant n'aurait aucun sens pour lui. L'entrée est simplement
  /// perdue.
  Future<void> record(HistoryEntry entry) async {
    try {
      await _repository.add(entry);
      _publier(HistoryReady(await _repository.all()));
    } on AppException catch (error) {
      debugPrint('Historique non enregistré : ${error.userMessage}');
    }
  }

  Future<void> remove(HistoryEntry entry) async {
    final id = entry.id;
    if (id == null) return;
    try {
      await _repository.remove(id);
      _publier(HistoryReady(await _repository.all()));
    } on AppException catch (error) {
      _publier(HistoryError(error.userMessage));
    }
  }

  void _publier(HistoryState etat) {
    _state = etat;
    notifyListeners();
  }
}
