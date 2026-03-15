import 'package:ai_evolution/domain/models/room_scene.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoomLaw', () {
    test('serializes and deserializes', () {
      const law = RoomLaw(
        id: 'law_patience',
        name: 'Law of Patience',
        description: 'Rewards waiting',
        mechanic: 'passive_bonus',
      );

      final json = law.toJson();
      expect(json['id'], 'law_patience');
      expect(json['name'], 'Law of Patience');
      expect(json['mechanic'], 'passive_bonus');

      final restored = RoomLaw.fromJson(json);
      expect(restored.id, law.id);
      expect(restored.name, law.name);
      expect(restored.description, law.description);
      expect(restored.mechanic, law.mechanic);
    });
  });

  group('RoomLandmark', () {
    test('serializes and deserializes', () {
      const landmark = RoomLandmark(
        id: 'lm_scrap_throne',
        name: 'The Scrap Throne',
        description: 'A pile of junk evolving into a throne.',
        evolutionStages: ['Junk Pile', 'Sorted Heap', 'Seat', 'Throne', 'Masterwork'],
        currentStage: 2,
      );

      final json = landmark.toJson();
      expect(json['id'], 'lm_scrap_throne');
      expect(json['evolutionStages'], hasLength(5));
      expect(json['currentStage'], 2);

      final restored = RoomLandmark.fromJson(json);
      expect(restored.id, landmark.id);
      expect(restored.name, landmark.name);
      expect(restored.evolutionStages, hasLength(5));
      expect(restored.currentStage, 2);
    });

    test('defaults to stage 0 and empty stages', () {
      final landmark = RoomLandmark.fromJson({
        'id': 'lm_test',
        'name': 'Test',
        'description': 'Test landmark',
      });
      expect(landmark.currentStage, 0);
      expect(landmark.evolutionStages, isEmpty);
    });
  });

  group('RoomHazard', () {
    test('serializes and deserializes', () {
      const hazard = RoomHazard(
        id: 'haz_rust',
        name: 'Rust Creep',
        description: 'Components degrade.',
        triggerCondition: 'idle > 60s',
        penalty: 'production_decay',
      );

      final json = hazard.toJson();
      expect(json['id'], 'haz_rust');
      expect(json['triggerCondition'], 'idle > 60s');

      final restored = RoomHazard.fromJson(json);
      expect(restored.id, hazard.id);
      expect(restored.penalty, 'production_decay');
    });
  });

  group('RoomStabilizer', () {
    test('serializes and deserializes', () {
      const stabilizer = RoomStabilizer(
        id: 'stab_grease',
        name: 'Grease and Grit',
        description: 'Manual maintenance stabilizes.',
        mechanic: 'tap_maintenance',
      );

      final json = stabilizer.toJson();
      expect(json['id'], 'stab_grease');

      final restored = RoomStabilizer.fromJson(json);
      expect(restored.id, stabilizer.id);
      expect(restored.mechanic, 'tap_maintenance');
    });
  });

  group('RoomScene with new fields', () {
    test('parses roomLaw, landmark, hazard, stabilizer, completionCeremony from JSON', () {
      final json = _buildMinimalRoomJson();
      json['roomLaw'] = {
        'id': 'law_test',
        'name': 'Test Law',
        'description': 'A test law',
        'mechanic': 'passive_bonus',
      };
      json['landmark'] = {
        'id': 'lm_test',
        'name': 'Test Landmark',
        'description': 'Evolving object',
        'evolutionStages': ['Stage 1', 'Stage 2', 'Stage 3'],
        'currentStage': 0,
      };
      json['hazard'] = {
        'id': 'haz_test',
        'name': 'Test Hazard',
        'description': 'A danger',
        'triggerCondition': 'always',
        'penalty': 'slowdown',
      };
      json['stabilizer'] = {
        'id': 'stab_test',
        'name': 'Test Stabilizer',
        'description': 'Counter hazard',
        'mechanic': 'tap_maintenance',
      };
      json['completionCeremony'] = 'The room transforms into light.';

      final room = RoomScene.fromJson(json);
      expect(room.roomLaw, isNotNull);
      expect(room.roomLaw!.name, 'Test Law');
      expect(room.landmark, isNotNull);
      expect(room.landmark!.evolutionStages, hasLength(3));
      expect(room.hazard, isNotNull);
      expect(room.hazard!.penalty, 'slowdown');
      expect(room.stabilizer, isNotNull);
      expect(room.stabilizer!.mechanic, 'tap_maintenance');
      expect(room.completionCeremony, 'The room transforms into light.');
    });

    test('handles missing optional new fields gracefully', () {
      final json = _buildMinimalRoomJson();
      final room = RoomScene.fromJson(json);
      expect(room.roomLaw, isNull);
      expect(room.landmark, isNull);
      expect(room.hazard, isNull);
      expect(room.stabilizer, isNull);
      expect(room.completionCeremony, isNull);
    });

    test('copyWith preserves new fields', () {
      final json = _buildMinimalRoomJson();
      json['roomLaw'] = {
        'id': 'law_test',
        'name': 'Test Law',
        'description': 'Desc',
        'mechanic': 'test',
      };
      json['completionCeremony'] = 'Original ceremony';

      final room = RoomScene.fromJson(json);
      final updated = room.copyWith(completionCeremony: 'New ceremony');
      expect(updated.roomLaw!.name, 'Test Law');
      expect(updated.completionCeremony, 'New ceremony');
    });

    test('toJson includes new fields', () {
      final json = _buildMinimalRoomJson();
      json['roomLaw'] = {
        'id': 'law_test',
        'name': 'Test Law',
        'description': 'Desc',
        'mechanic': 'test',
      };
      json['completionCeremony'] = 'Victory!';

      final room = RoomScene.fromJson(json);
      final output = room.toJson();
      expect(output['roomLaw'], isNotNull);
      expect((output['roomLaw'] as Map)['name'], 'Test Law');
      expect(output['completionCeremony'], 'Victory!');
    });
  });

  group('Expanded enums', () {
    test('RoomMechanicEmphasis has 10 values', () {
      expect(RoomMechanicEmphasis.values.length, 10);
    });
  });
}

Map<String, dynamic> _buildMinimalRoomJson() {
  return {
    'id': 'room_test',
    'name': 'Test Room',
    'subtitle': 'A test room',
    'order': 1,
    'introText': 'Welcome.',
    'completionText': 'Done.',
    'guideTone': 'neutral',
    'guideIntroLine': 'Hi.',
    'currency': 'Coins',
    'mechanicEmphasis': 'tap',
    'themeColors': {
      'primary': '#FFFFFF',
      'accent': '#000000',
      'background': '#111111',
    },
    'eventPoolId': 'pool_test',
  };
}
