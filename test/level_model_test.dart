import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesign/game/level/level_model.dart';

const worldJson = '''
{
  "version": 1,
  "start": "corridor_01",
  "nodes": [
    {"id": "corridor_01", "type": "corridor", "file": "corridor_01.json",
     "exits": {"east": "hub_01"}},
    {"id": "hub_01", "type": "hub", "file": "hub_01.json",
     "rooms": ["room_s1", "room_s2"],
     "unlock": {"rule": "anyOf", "count": 1},
     "exits": {"west": "corridor_01", "east": "corridor_02"}},
    {"id": "room_s1", "type": "room", "file": "room_s1.json", "parent": "hub_01"},
    {"id": "room_s2", "type": "room", "file": "room_s2.json", "parent": "hub_01"},
    {"id": "corridor_02", "type": "corridor", "file": "corridor_02.json",
     "exits": {"west": "hub_01"}}
  ]
}
''';

const roomJson = '''
{
  "version": 1,
  "id": "room_s1",
  "type": "room",
  "name": "dev label",
  "size": {"w": 24, "h": 14},
  "puzzle": "stub_switch",
  "entryPoints": {"back": {"x": 2.5, "y": 11}},
  "start": {"x": 2.5, "y": 11},
  "entities": [
    {"type": "floor", "x": 0.5, "y": 12, "w": 23, "h": 1.5},
    {"id": "doorBack", "type": "door", "x": 1.6, "y": 10, "w": 1.2, "h": 2,
     "props": {"exit": "back"}},
    {"id": "switch", "type": "lever", "x": 16, "y": 10.75, "w": 1, "h": 1.25}
  ]
}
''';

WorldData world() =>
    WorldData.fromJson(jsonDecode(worldJson) as Map<String, dynamic>);

void main() {
  group('WorldData parsing', () {
    test('parses nodes, exits, rooms, unlock', () {
      final w = world();
      expect(w.start, 'corridor_01');
      expect(w.nodes.length, 5);
      expect(w.node('corridor_01').exits['east'], 'hub_01');
      expect(w.node('hub_01').rooms, ['room_s1', 'room_s2']);
      expect(w.node('hub_01').unlock!.rule, 'anyOf');
      expect(w.node('room_s1').parent, 'hub_01');
    });

    test('rejects a start node that does not exist', () {
      final bad = jsonDecode(worldJson) as Map<String, dynamic>;
      bad['start'] = 'nowhere';
      expect(() => WorldData.fromJson(bad), throwsFormatException);
    });
  });

  group('WorldData.resolve (transitions)', () {
    test('corridor → hub enters at the hub door leading back', () {
      final t = world().resolve('corridor_01', 'east')!;
      expect(t.targetId, 'hub_01');
      expect(t.entryKey, 'west');
    });

    test('hub → room via the room-id exit enters at "back"', () {
      final t = world().resolve('hub_01', 'room_s1')!;
      expect(t.targetId, 'room_s1');
      expect(t.entryKey, 'back');
    });

    test('room → "back" returns to the parent hub at the room door', () {
      final t = world().resolve('room_s1', 'back')!;
      expect(t.targetId, 'hub_01');
      expect(t.entryKey, 'room_s1');
    });

    test('hub → onward corridor enters at its west door', () {
      final t = world().resolve('hub_01', 'east')!;
      expect(t.targetId, 'corridor_02');
      expect(t.entryKey, 'west');
    });

    test('unknown exits resolve to null', () {
      expect(world().resolve('corridor_01', 'north'), isNull);
    });
  });

  group('UnlockRule', () {
    const hubRooms = ['room_s1', 'room_s2', 'room_s3'];

    test('anyOf 1: any single solved room satisfies', () {
      final rule = UnlockRule.anyOf(1);
      expect(rule.isSatisfied({}, hubRooms), isFalse);
      expect(rule.isSatisfied({'room_s2'}, hubRooms), isTrue);
      expect(rule.isSatisfied({'unrelated_room'}, hubRooms), isFalse);
    });

    test('anyOf 2: needs two of the hub rooms', () {
      final rule = UnlockRule.anyOf(2);
      expect(rule.isSatisfied({'room_s1'}, hubRooms), isFalse);
      expect(rule.isSatisfied({'room_s1', 'room_s3'}, hubRooms), isTrue);
    });

    test('specific: the named rooms must all be solved', () {
      final rule = UnlockRule.specific(['room_s2']);
      expect(rule.isSatisfied({'room_s1', 'room_s3'}, hubRooms), isFalse);
      expect(rule.isSatisfied({'room_s2'}, hubRooms), isTrue);
    });

    test('unknown rule fails parsing loudly', () {
      expect(() => UnlockRule.fromJson({'rule': 'magic'}),
          throwsFormatException);
    });
  });

  group('LevelData parsing', () {
    test('parses size, points, entities, props', () {
      final l =
          LevelData.fromJson(jsonDecode(roomJson) as Map<String, dynamic>);
      expect(l.id, 'room_s1');
      expect(l.widthTiles, 24);
      expect(l.puzzle, 'stub_switch');
      expect(l.entryPoints['back']!.x, 2.5);
      expect(l.entities.length, 3);
      final door = l.entities[1];
      expect(door.id, 'doorBack');
      expect(door.props['exit'], 'back');
    });
  });
}
