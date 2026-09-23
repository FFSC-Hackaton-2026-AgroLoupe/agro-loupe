import 'package:agro_loupe/core/services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  late _MockConnectivity connectivity;
  late ConnectivityService service;

  setUp(() {
    connectivity = _MockConnectivity();
    service = ConnectivityService(connectivity: connectivity);
  });

  group('status', () {
    test('en ligne dès qu\'une interface est active', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      expect(await service.status, ConnectionStatus.online);
    });

    test('hors ligne quand aucune interface ne répond', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      expect(await service.status, ConnectionStatus.offline);
    });
  });

  group('onStatusChanged', () {
    test('traduit les changements en états lisibles', () {
      when(() => connectivity.onConnectivityChanged).thenAnswer(
        (_) => Stream.fromIterable([
          [ConnectivityResult.none],
          [ConnectivityResult.mobile],
        ]),
      );

      expect(
        service.onStatusChanged,
        emitsInOrder([ConnectionStatus.offline, ConnectionStatus.online]),
      );
    });

    test('n\'émet pas deux fois le même état de suite', () {
      when(() => connectivity.onConnectivityChanged).thenAnswer(
        (_) => Stream.fromIterable([
          [ConnectivityResult.wifi],
          [ConnectivityResult.mobile],
          [ConnectivityResult.none],
        ]),
      );

      // wifi puis mobile signifient tous deux « en ligne » : une seule émission.
      expect(
        service.onStatusChanged,
        emitsInOrder([ConnectionStatus.online, ConnectionStatus.offline]),
      );
    });
  });
}
