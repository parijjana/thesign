import '../components/lever.dart';
import 'puzzle_script.dart';

/// "Pull the goal lever" puzzle — solved when the room's goal lever is on.
/// Used by the physical rooms (stacking, counterweight, ascent) whose
/// challenge is reaching the lever, not the lever itself. Finds the lever by
/// id `switch`/`goalSwitch`, else falls back to the first lever in the room,
/// so the lever's authored id never has to match a magic string.
class StubSwitchPuzzle extends PuzzleScript {
  Lever? _lever;

  @override
  void onLoad(PuzzleRoom room) {
    _lever = room.byId<Lever>('switch') ??
        room.byId<Lever>('goalSwitch') ??
        (room.allOf<Lever>().isNotEmpty ? room.allOf<Lever>().first : null);
    assert(_lever != null, 'stub_switch puzzle needs a lever in the room');
  }

  @override
  bool get isSolved => _lever?.on ?? false;
}
