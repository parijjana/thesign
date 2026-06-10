import 'package:flutter_test/flutter_test.dart';
import 'package:thesign/game/core/reset_controller.dart';

class FakeBody implements Resettable {
  int resets = 0;

  @override
  void resetToStart() => resets++;
}

void main() {
  group('ResetController', () {
    test('reset() resets every registered body', () {
      final controller = ResetController();
      final a = FakeBody();
      final b = FakeBody();
      controller
        ..register(a)
        ..register(b)
        ..reset();
      expect(a.resets, 1);
      expect(b.resets, 1);
    });

    test('unregistered bodies are left alone', () {
      final controller = ResetController();
      final a = FakeBody();
      final b = FakeBody();
      controller
        ..register(a)
        ..register(b)
        ..unregister(b)
        ..reset();
      expect(a.resets, 1);
      expect(b.resets, 0);
    });

    test('reset() with no bodies is a no-op', () {
      expect(() => ResetController().reset(), returnsNormally);
    });
  });
}
