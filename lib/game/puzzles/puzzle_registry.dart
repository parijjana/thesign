import 'puzzle_script.dart';
import 'stub_switch.dart';

/// Room JSON declares `"puzzle": "<id>"`; this registry maps the id to a
/// factory (LEVEL_FORMAT.md §5). One entry per built room script.
typedef PuzzleFactory = PuzzleScript Function();

const Map<String, PuzzleFactory> puzzleRegistry = {
  'stub_switch': StubSwitchPuzzle.new,
};
