import 'optics_mirror.dart';
import 'p1_pressure_plates.dart';
import 'puzzle_script.dart';
import 'stub_switch.dart';

/// Room JSON declares `"puzzle": "<id>"`; this registry maps the id to a
/// factory (LEVEL_FORMAT.md §5). One entry per built room script.
typedef PuzzleFactory = PuzzleScript Function();

const Map<String, PuzzleFactory> puzzleRegistry = {
  'stub_switch': StubSwitchPuzzle.new,
  'p1_pressure_plates': P1PressurePlates.new,
  // Box stacking is pure traversal + a goal lever — the stub script fits.
  'p2_box_stack': StubSwitchPuzzle.new,
  'optics_mirror': OpticsMirrorPuzzle.new,
};
