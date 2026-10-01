import 'package:agro_loupe/core/errors/app_exception.dart';
import 'package:agro_loupe/features/diagnosis/models/crop_profile.dart';
import 'package:agro_loupe/features/history/data/history_repository.dart';
import 'package:agro_loupe/features/history/models/history_entry.dart';
import 'package:agro_loupe/features/history/state/history_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements HistoryRepository {}

HistoryEntry _entree({int? id, bool confirme = true}) => HistoryEntry(
  id: id,
  imagePath: '/tmp/feuille.jpg',
  crop: Crop.tomato,
  diseaseName: 'Mildiou',
  modelLabel: 'Tomato___Late_blight',
  confidence: 0.894,
  createdAt: DateTime(2026, 9, 30, 14, 5),
  isConfirmed: confirme,
);

void main() {
  late _MockRepository repository;
  late HistoryProvider provider;

  setUpAll(() => registerFallbackValue(_entree()));

  setUp(() {
    repository = _MockRepository();
    provider = HistoryProvider(repository);
  });

  test("un historique vide est un état à part, pas une erreur", () async {
    when(() => repository.all()).thenAnswer((_) async => []);

    await provider.load();

    final state = provider.state;
    expect(state, isA<HistoryReady>());
    // C'est ce que voit le jury au premier lancement : l'écran d'accueil de
    // l'historique, et non un écran blanc.
    expect((state as HistoryReady).isEmpty, isTrue);
  });

  test('les entrées sont rendues telles que le repository les trie', () async {
    when(
      () => repository.all(),
    ).thenAnswer((_) async => [_entree(id: 2), _entree(id: 1)]);

    await provider.load();

    final state = provider.state as HistoryReady;
    expect(state.entries.map((e) => e.id), [2, 1]);
    expect(state.isEmpty, isFalse);
  });

  test('un stockage illisible devient un message lisible', () async {
    when(
      () => repository.all(),
    ).thenThrow(const StorageException.unavailable());

    await provider.load();

    expect(provider.state, isA<HistoryError>());
    expect((provider.state as HistoryError).message, contains('historique'));
  });

  test('un échec d\'écriture ne casse pas le parcours', () async {
    when(
      () => repository.add(any()),
    ).thenThrow(const StorageException.unavailable());

    await provider.record(_entree());

    // L'utilisateur vient d'obtenir son diagnostic : lui annoncer une erreur
    // de base de données à cet instant n'aurait aucun sens pour lui.
    expect(provider.state, isA<HistoryLoading>());
  });

  test('un enregistrement réussi rafraîchit la liste', () async {
    when(() => repository.add(any())).thenAnswer((_) async => _entree(id: 1));
    when(() => repository.all()).thenAnswer((_) async => [_entree(id: 1)]);

    await provider.record(_entree());

    expect((provider.state as HistoryReady).entries, hasLength(1));
    verify(() => repository.add(any())).called(1);
  });
}
