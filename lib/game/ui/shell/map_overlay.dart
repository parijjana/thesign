import 'package:flutter/material.dart';

import '../../escape_game.dart';
import '../../level/level_model.dart';
import '../../palette.dart';
import '../symbols.dart';

/// The castle map (M7, MAZE.md §5): a top-down **discovered-graph** view so the
/// side-view maze stays legible. Nodes you've visited are solid; their not-yet-
/// entered neighbours show as faint teasers ("doors I never opened"). Laid out
/// by BFS depth from the start (same layered layout as tool/castle_map.dart).
/// Symbol-first, no text in the map itself. Reached from the pause overlay.
class MapOverlay extends StatelessWidget {
  const MapOverlay(this.game, {super.key});
  final EscapeGame game;

  static const _amber = Palettes.amber;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _amber.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MapPainter(game)),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: GestureDetector(
              onTap: game.hideMap,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _amber.accentNeutral,
                  shape: BoxShape.circle,
                  border: Border.all(color: _amber.ink, width: 3),
                ),
                child: Icon(Icons.close_rounded, size: 30, color: _amber.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.game);
  final EscapeGame game;

  static const _p = Palettes.amber;
  static const _streetBadge = <String, SymbolId>{
    'corridor_01': SymbolId.streetCircle,
    'corridor_02': SymbolId.streetTriangle,
    'corridor_03': SymbolId.streetSquare,
    'corridor_04': SymbolId.streetDiamond,
    'corridor_05': SymbolId.streetStar,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final world = game.registry.world;

    // Undirected adjacency + BFS depth from the start (the columns).
    final adj = <String, Set<String>>{};
    void link(String a, String b) {
      adj.putIfAbsent(a, () => {}).add(b);
      adj.putIfAbsent(b, () => {}).add(a);
    }

    for (final n in world.nodes.values) {
      adj.putIfAbsent(n.id, () => {});
      for (final t in n.exits.values) {
        link(n.id, t);
      }
    }
    final depth = <String, int>{world.start: 0};
    final queue = <String>[world.start];
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      for (final nb in adj[cur]!) {
        if (!depth.containsKey(nb)) {
          depth[nb] = depth[cur]! + 1;
          queue.add(nb);
        }
      }
    }
    for (final id in world.nodes.keys) {
      depth.putIfAbsent(id, () => 0);
    }

    final byDepth = <int, List<String>>{};
    for (final id in world.nodes.keys) {
      byDepth.putIfAbsent(depth[id]!, () => []).add(id);
    }
    for (final l in byDepth.values) {
      l.sort();
    }
    final maxDepth = byDepth.keys.fold(0, (a, b) => a > b ? a : b);
    final maxRows = byDepth.values.map((l) => l.length).fold(0, (a, b) => a > b ? a : b);

    // Fit the grid into the screen, leaving a margin for the close button.
    const margin = 70.0;
    final cellW = (size.width - margin * 2) / (maxDepth + 1);
    final cellH = (size.height - margin * 2) / maxRows;
    final tile = (cellW < cellH ? cellW : cellH) * 0.42;

    final pos = <String, Offset>{};
    byDepth.forEach((d, list) {
      final yOff = (maxRows - list.length) / 2;
      for (var i = 0; i < list.length; i++) {
        pos[list[i]] = Offset(
          margin + (d + 0.5) * cellW,
          margin + (i + yOff + 0.5) * cellH,
        );
      }
    });

    bool visible(String id) =>
        game.visitedNodes.contains(id) ||
        adj[id]!.any(game.visitedNodes.contains);

    // Edges first (under the nodes).
    final drawn = <String>{};
    for (final n in world.nodes.values) {
      final a = pos[n.id]!;
      for (final t in n.exits.values) {
        final key = ([n.id, t]..sort()).join('|');
        if (!drawn.add(key)) continue;
        if (!visible(n.id) || !visible(t)) continue;
        final both = game.visitedNodes.contains(n.id) &&
            game.visitedNodes.contains(t);
        canvas.drawLine(
          a,
          pos[t]!,
          Paint()
            ..color = _p.ink.withValues(alpha: both ? 0.7 : 0.25)
            ..strokeWidth = both ? 3 : 2,
        );
      }
    }

    // Nodes.
    for (final n in world.nodes.values) {
      if (!visible(n.id)) continue;
      final c = pos[n.id]!;
      final seen = game.visitedNodes.contains(n.id);
      _drawNode(canvas, n, c, tile, seen);
    }
  }

  void _drawNode(
      Canvas canvas, NodeData n, Offset c, double tile, bool seen) {
    final isCurrent = n.id == game.currentNodeId;
    final solved = game.solvedRooms.contains(n.id);
    final a = seen ? 1.0 : 0.32;

    // Current node gets a goal-green halo.
    if (isCurrent) {
      canvas.drawCircle(
          c, tile * 0.95, Paint()..color = _p.accentGoal.withValues(alpha: 0.4));
    }

    final fill = Paint()..color = _p.accentNeutral.withValues(alpha: a);
    final edge = Paint()
      ..color = _p.ink.withValues(alpha: a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    if (!seen) edge.strokeWidth = 1.5;

    // Shape by type: meadow = circle (home), corridor = circle w/ badge,
    // hub/plaza = rounded square, room = small square.
    if (n.type == NodeType.room) {
      final r = Rect.fromCenter(center: c, width: tile * 0.9, height: tile * 0.9);
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
      canvas.drawRRect(rr, fill);
      canvas.drawRRect(rr, edge);
      _glyph(canvas, solved ? SymbolId.unlocked : null, c, tile * 0.55, a);
    } else if (n.type == NodeType.hub) {
      final r = Rect.fromCenter(center: c, width: tile * 1.2, height: tile * 1.2);
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
      canvas.drawRRect(rr, fill);
      canvas.drawRRect(rr, edge);
    } else {
      canvas.drawCircle(c, tile * 0.6, fill);
      canvas.drawCircle(c, tile * 0.6, edge);
      final badge =
          n.type == NodeType.meadow ? SymbolId.spawn : _streetBadge[n.id];
      _glyph(canvas, badge, c, tile * 0.7, a);
    }
  }

  void _glyph(Canvas canvas, SymbolId? id, Offset c, double s, double alpha) {
    if (id == null) return;
    canvas.save();
    canvas.translate(c.dx - s / 2, c.dy - s / 2);
    drawSymbol(canvas, id, s, _p.ink.withValues(alpha: alpha));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;
}
