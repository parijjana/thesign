/// Save data model (ARCHITECTURE.md §5.8). Pure Dart, headless-testable.
/// Per-profile from day one (profiles get their select UI in M7).
class Progress {
  Progress({
    required this.currentNode,
    Set<String>? solvedRooms,
  }) : solvedRooms = solvedRooms ?? {};

  String currentNode;
  final Set<String> solvedRooms;

  Map<String, dynamic> toJson() => {
        'version': 1,
        'currentNode': currentNode,
        'solvedRooms': solvedRooms.toList()..sort(),
      };

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
        currentNode: json['currentNode'] as String,
        solvedRooms: (json['solvedRooms'] as List? ?? []).cast<String>().toSet(),
      );
}
