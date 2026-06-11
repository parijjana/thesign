import 'aabb.dart';

/// Something the player can act on with the context button (GDD §5 Interact).
/// Components register with the game on mount; each interact press goes to
/// the first registered interactable overlapping the player.
abstract interface class Interactable {
  Aabb get interactZone;
  void onInteract();
}
