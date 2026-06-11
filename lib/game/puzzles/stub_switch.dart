import '../components/lever.dart';
import 'puzzle_script.dart';

/// M3 stub puzzle: the room is solved when the lever with id `switch` is on.
/// Exists to prove the script lifecycle end-to-end; real puzzles arrive in M4.
class StubSwitchPuzzle extends PuzzleScript {
  Lever? _switch;

  @override
  void onLoad(PuzzleRoom room) {
    _switch = room.byId<Lever>('switch');
    assert(_switch != null, 'stub_switch puzzle needs a lever with id "switch"');
  }

  @override
  bool get isSolved => _switch?.on ?? false;
}
