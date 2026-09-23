import 'package:connectivity_plus/connectivity_plus.dart';

/// État du réseau, tel que l'interface a besoin de le connaître.
enum ConnectionStatus { online, offline }

/// Surveille la présence d'une connexion.
///
/// Sert uniquement à informer l'utilisateur : le diagnostic, lui, ne dépend
/// jamais du réseau. Ce service ne bloque donc aucune fonctionnalité.
class ConnectivityService {
  /// [connectivity] n'est fourni que par les tests ; en production, le service
  /// crée sa propre instance.
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// État courant du réseau, à un instant donné.
  Future<ConnectionStatus> get status async =>
      _toStatus(await _connectivity.checkConnectivity());

  /// Émet une valeur à chaque changement d'état, sans répéter deux fois
  /// le même (`distinct`), pour éviter des reconstructions inutiles.
  Stream<ConnectionStatus> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map(_toStatus).distinct();

  /// L'appareil est considéré connecté dès qu'une interface est active.
  ///
  /// Note : cela n'assure pas qu'internet soit réellement joignable, seulement
  /// qu'une interface existe. C'est suffisant pour un simple indicateur.
  ConnectionStatus _toStatus(List<ConnectivityResult> results) {
    final hasInterface = results.any(
      (result) => result != ConnectivityResult.none,
    );
    return hasInterface ? ConnectionStatus.online : ConnectionStatus.offline;
  }
}
