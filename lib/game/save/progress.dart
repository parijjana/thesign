/// Save data model (ARCHITECTURE.md §5.8). Pure Dart, headless-testable.
/// Per-profile from day one (profiles get their select UI in M7).
class Progress {
  Progress({
    required this.currentNode,
    Set<String>? solvedRooms,
    Set<String>? foundEtchings,
    Set<String>? discoveredSecrets,
    Set<String>? visitedNodes,
    Set<String>? powerups,
  })  : solvedRooms = solvedRooms ?? {},
        foundEtchings = foundEtchings ?? {},
        discoveredSecrets = discoveredSecrets ?? {},
        visitedNodes = visitedNodes ?? {},
        powerups = powerups ?? {};

  String currentNode;
  final Set<String> solvedRooms;
  final Set<String> foundEtchings; // lore collection (gallery in M7)
  final Set<String> discoveredSecrets; // '<node>/<exit>' keys
  final Set<String> visitedNodes; // feeds the M7 castle map
  final Set<String> powerups; // Powerup ids owned (Metroidvania)

  Map<String, dynamic> toJson() => {
        'version': 1,
        'currentNode': currentNode,
        'solvedRooms': solvedRooms.toList()..sort(),
        'foundEtchings': foundEtchings.toList()..sort(),
        'discoveredSecrets': discoveredSecrets.toList()..sort(),
        'visitedNodes': visitedNodes.toList()..sort(),
        'powerups': powerups.toList()..sort(),
      };

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
        currentNode: json['currentNode'] as String,
        solvedRooms:
            (json['solvedRooms'] as List? ?? []).cast<String>().toSet(),
        foundEtchings:
            (json['foundEtchings'] as List? ?? []).cast<String>().toSet(),
        discoveredSecrets:
            (json['discoveredSecrets'] as List? ?? []).cast<String>().toSet(),
        visitedNodes:
            (json['visitedNodes'] as List? ?? []).cast<String>().toSet(),
        powerups: (json['powerups'] as List? ?? []).cast<String>().toSet(),
      );
}
