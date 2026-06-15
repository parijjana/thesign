import 'm6_puzzles.dart';
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
  // Physical puzzles (stacking, counterweight): the component does the
  // physics, a goal lever ends them — the stub script fits. (The seesaw was
  // retired to the icebox; room_fulcrum now uses the counterweight lift.)
  'p2_box_stack': StubSwitchPuzzle.new,
  'p_counterweight': StubSwitchPuzzle.new,
  'optics_mirror': OpticsMirrorPuzzle.new,
  'p_sokoban': SokobanPuzzle.new,
  'p_splitter': SplitterPuzzle.new,
  'p_sequence': SequencePuzzle.new,
  'p_capstone': CapstonePuzzle.new,
};
