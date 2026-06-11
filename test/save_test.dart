import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesign/game/save/progress.dart';
import 'package:thesign/game/save/save_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SaveService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('round-trips progress', () async {
      final service = SaveService();
      await service.save(Progress(
        currentNode: 'hub_01',
        solvedRooms: {'room_plates', 'room_mirror'},
      ));
      final loaded = await service.load();
      expect(loaded!.currentNode, 'hub_01');
      expect(loaded.solvedRooms, {'room_plates', 'room_mirror'});
    });

    test('returns null with no save', () async {
      expect(await SaveService().load(), isNull);
    });

    test('profiles are isolated', () async {
      await SaveService(profile: 'p1')
          .save(Progress(currentNode: 'corridor_01'));
      expect(await SaveService(profile: 'p2').load(), isNull);
    });

    test('wipe clears the save', () async {
      final service = SaveService();
      await service.save(Progress(currentNode: 'hub_01'));
      await service.wipe();
      expect(await service.load(), isNull);
    });
  });
}
