// Castle map generator. Reads assets/levels/world.json (+ each level file for
// its code), runs the maze validators, and writes:
//   • an ASCII map to stdout
//   • build/castle_map.html  (a standalone SVG graph you open in a browser)
//
// Run it after any world change:   dart run tool/castle_map.dart
// Nothing here ships in the game — it's a dev/validation/navigation aid.

import 'dart:convert';
import 'dart:io';

import 'package:thesign/game/level/level_model.dart';
import 'package:thesign/game/level/world_validator.dart';

const _levelsDir = 'assets/levels';
const _allowedGates = {'exit_hall', 'secret_stack'};

void main() {
  final world = WorldData.fromJson(
    jsonDecode(File('$_levelsDir/world.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  // Pull each node's short code + puzzle from its level file.
  final code = <String, String>{};
  final puzzle = <String, String?>{};
  for (final n in world.nodes.values) {
    try {
      final lvl = LevelData.fromJson(
        jsonDecode(File('$_levelsDir/${n.file}').readAsStringSync())
            as Map<String, dynamic>,
      );
      code[n.id] = lvl.code;
      puzzle[n.id] = lvl.puzzle;
    } catch (_) {
      code[n.id] = n.id;
    }
  }

  _printAscii(world, code, puzzle);
  Directory('build').createSync(recursive: true);
  File('build/castle_map.html').writeAsStringSync(_buildHtml(world, code, puzzle));
  stdout.writeln('\nWrote build/castle_map.html');
}

// --- door classification -----------------------------------------------------

enum DoorKind { open, locked, secret }

DoorKind _doorKind(WorldData world, String from, String exit, String target) {
  if (exit == 'secret' || target.startsWith('secret_')) return DoorKind.secret;
  return world.isSolveGated(from, exit) ? DoorKind.locked : DoorKind.open;
}

// --- ASCII -------------------------------------------------------------------

void _printAscii(
    WorldData world, Map<String, String> code, Map<String, String?> puzzle) {
  String c(String id) => code[id] ?? id;
  final out = stdout;

  out.writeln('=== CASTLE MAP  (${world.nodes.length} nodes) ===');
  out.writeln('start: ${c(world.start)}  (${world.start})\n');

  out.writeln('VALIDATION');
  void section(String name, List<String> violations) {
    if (violations.isEmpty) {
      out.writeln('  $name: OK');
    } else {
      out.writeln('  $name: ${violations.length} VIOLATION(S)');
      for (final v in violations) {
        out.writeln('     ! $v');
      }
    }
  }

  section('kindness ', findKindnessViolations(world, allowedGates: _allowedGates));
  section('direction', findDirectionViolations(world));
  section('liveness ', findCorridorLivenessViolations(world));

  out.writeln('\nLEGEND:  -->  open   ==>  opens-on-solve   ~~>  secret\n');

  for (final type in NodeType.values) {
    final nodes = world.nodes.values.where((n) => n.type == type).toList()
      ..sort((a, b) => c(a.id).compareTo(c(b.id)));
    if (nodes.isEmpty) continue;
    out.writeln('${type.name.toUpperCase()}S');
    for (final n in nodes) {
      final pz = puzzle[n.id];
      final entry = n.entries.isEmpty ? '' : '  entry:${n.entries.join("/")}';
      final pzl = pz == null ? '' : '  [$pz]';
      out.writeln('  ${c(n.id).padRight(4)} ${n.id}$pzl$entry');
      for (final e in n.exits.entries) {
        final arrow = switch (_doorKind(world, n.id, e.key, e.value)) {
          DoorKind.open => '-->',
          DoorKind.locked => '==>',
          DoorKind.secret => '~~>',
        };
        out.writeln(
            '         ${e.key.padRight(8)} $arrow ${c(e.value).padRight(4)} (${e.value})');
      }
    }
    out.writeln('');
  }
}

// --- HTML / SVG --------------------------------------------------------------

String _buildHtml(
    WorldData world, Map<String, String> code, Map<String, String?> puzzle) {
  // BFS-depth columns from start (undirected) → left-to-right layered layout.
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
  final queue = [world.start];
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

  // Group by depth → assign x (column) and y (row).
  final byDepth = <int, List<String>>{};
  for (final id in world.nodes.keys) {
    byDepth.putIfAbsent(depth[id]!, () => []).add(id);
  }
  for (final list in byDepth.values) {
    list.sort();
  }
  const colW = 220.0;
  const rowH = 96.0;
  const boxW = 150.0;
  const boxH = 60.0;
  final pos = <String, ({double x, double y})>{};
  final maxRows = byDepth.values.map((l) => l.length).fold(0, (a, b) => a > b ? a : b);
  byDepth.forEach((d, list) {
    for (var i = 0; i < list.length; i++) {
      final yOffset = (maxRows - list.length) / 2;
      pos[list[i]] =
          (x: 60 + d * colW, y: 50 + (i + yOffset) * rowH);
    }
  });
  final width = 120 + (byDepth.keys.fold(0, (a, b) => a > b ? a : b) + 1) * colW;
  final height = 100 + maxRows * rowH;

  String fill(NodeType t) => switch (t) {
        NodeType.corridor => '#cfe8ff',
        NodeType.hub => '#d6f5d6',
        NodeType.room => '#fff7cc',
        NodeType.meadow => '#d8d0f0',
      };

  final edges = StringBuffer();
  final drawn = <String>{};
  for (final n in world.nodes.values) {
    final a = pos[n.id]!;
    for (final e in n.exits.entries) {
      final key = ([n.id, e.value]..sort()).join('|');
      if (!drawn.add(key)) continue; // one line per undirected pair
      final b = pos[e.value];
      if (b == null) continue;
      final kind = _doorKind(world, n.id, e.key, e.value);
      final color = switch (kind) {
        DoorKind.open => '#2e9468',
        DoorKind.locked => '#c4452e',
        DoorKind.secret => '#999',
      };
      final dash = kind == DoorKind.secret ? 'stroke-dasharray="6 5"' : '';
      edges.writeln(
          '<line x1="${a.x + boxW / 2}" y1="${a.y + boxH / 2}" '
          'x2="${b.x + boxW / 2}" y2="${b.y + boxH / 2}" '
          'stroke="$color" stroke-width="2.5" $dash />');
    }
  }

  final boxes = StringBuffer();
  for (final n in world.nodes.values) {
    final p = pos[n.id]!;
    final pz = puzzle[n.id];
    final sub = pz ??
        (n.entries.isNotEmpty ? 'entry:${n.entries.join("/")}' : n.type.name);
    final isStart = n.id == world.start;
    boxes.writeln('''
<g>
  <rect x="${p.x}" y="${p.y}" width="$boxW" height="$boxH" rx="8"
        fill="${fill(n.type)}" stroke="${isStart ? '#1e4e8c' : '#101010'}"
        stroke-width="${isStart ? 3.5 : 1.6}" />
  <text x="${p.x + 10}" y="${p.y + 22}" font-weight="700" font-size="16">${code[n.id]}</text>
  <text x="${p.x + 10}" y="${p.y + 38}" font-size="11" fill="#333">${n.id}</text>
  <text x="${p.x + 10}" y="${p.y + 52}" font-size="10" fill="#666">$sub</text>
</g>''');
  }

  final kindness = findKindnessViolations(world, allowedGates: _allowedGates);
  final direction = findDirectionViolations(world);
  final liveness = findCorridorLivenessViolations(world);
  String badge(String name, List<String> v) => v.isEmpty
      ? '<span style="color:#2e9468">[OK] $name</span>'
      : '<span style="color:#c4452e">[X] $name (${v.length})</span>';
  final allViolations = [...kindness, ...direction, ...liveness];

  return '''<!doctype html>
<html><head><meta charset="utf-8"><title>Castle map — The Sign</title>
<style>
 body{font-family:system-ui,sans-serif;margin:16px;background:#faf8f0}
 .bar{margin-bottom:10px;font-size:14px}
 .bar span{margin-right:18px}
 .legend{font-size:13px;color:#444;margin-bottom:8px}
 .legend b{padding:2px 6px;border-radius:4px}
 .viol{color:#c4452e;font-size:13px;white-space:pre-wrap}
 svg{background:#fff;border:1px solid #ddd;border-radius:8px}
</style></head><body>
<h2>Castle map — The Sign <span style="font-weight:400;font-size:14px;color:#888">(${world.nodes.length} nodes, start ${code[world.start]})</span></h2>
<div class="bar">${badge('kindness', kindness)} ${badge('direction', direction)} ${badge('liveness', liveness)}</div>
<div class="legend">
  <b style="background:#cfe8ff">corridor</b>
  <b style="background:#d6f5d6">hub</b>
  <b style="background:#fff7cc">room</b>
  &nbsp;—&nbsp;
  <span style="color:#2e9468">▬ open</span>
  <span style="color:#c4452e">▬ opens-on-solve</span>
  <span style="color:#999">▭ secret</span>
</div>
${allViolations.isEmpty ? '' : '<div class="viol">! ${allViolations.join('\n! ')}</div>'}
<svg width="$width" height="$height" viewBox="0 0 $width $height">
$edges
$boxes
</svg>
</body></html>''';
}
