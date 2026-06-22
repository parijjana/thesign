import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The no-text rule, enforced (GDD §0, STYLE_GUIDE §8b): the **play space** is
/// wordless and numeral-free — quantities are always shown visually (beaker
/// levels, pip dots, balance tilt), never as drawn words or numbers.
///
/// On a Flame canvas the only way to draw words OR numerals is a text-rendering
/// API, so banning those APIs in play-space code enforces both halves of the
/// rule at once. Text is permitted ONLY in:
///   * the application shell (`lib/game/ui/shell/`) — title/settings/etc., which
///     are text-permitted-but-symbol-first by design;
///   * dev-only tooling (`debug_hud.dart`) — never shipped to players.
void main() {
  // Substrings of allowed paths (normalized to forward slashes).
  const allowed = [
    'lib/game/ui/shell/',
    'lib/game/ui/debug_hud.dart',
  ];

  // Flame/Flutter canvas text-rendering APIs. If a gameplay component reaches
  // for one of these, it's about to draw words or numerals in the play space.
  final banned = RegExp(
    r'\b(TextPaint|TextPainter|TextComponent|ParagraphBuilder|drawParagraph)\b',
  );

  test('play-space code draws no words or numerals (no-text rule)', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (allowed.any(path.contains)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        // Strip line comments so a comment that merely mentions an API name
        // (e.g. "no TextPaint here") doesn't trip the guard.
        final code = lines[i].split('//').first;
        final match = banned.firstMatch(code);
        if (match != null) {
          offenders.add('$path:${i + 1}  ->  ${match.group(0)}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Play-space code must be wordless and numeral-free — quantities '
          'are shown visually, never drawn as text/numbers (STYLE_GUIDE §8b). '
          'Move any genuine text into the shell (lib/game/ui/shell/).\n'
          '${offenders.join('\n')}',
    );
  });
}
