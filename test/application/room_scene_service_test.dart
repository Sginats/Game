import 'package:ai_evolution/application/services/room_scene_service.dart';
import 'package:ai_evolution/domain/models/room_scene.dart';
import 'package:ai_evolution/domain/models/scene_event.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _buildRoomJson({
  required String id,
  required int order,
  String? unlockRequirement,
}) {
  return {
    'id': id,
    'name': 'Room $order',
    'subtitle': 'Subtitle $order',
    'order': order,
    'introText': 'Intro text for room $order.',
    'completionText': 'Completion text for room $order.',
    'guideTone': 'neutral',
    'guideIntroLine': 'Welcome to room $order.',
    'currency': 'Coins',
    'mechanicEmphasis': 'tap',
    'themeColors': {
      'primary': '#FFFFFF',
      'accent': '#000000',
      'background': '#111111',
    },
    'transformationStages': [
      {
        'id': '${id}_stage_1',
        'name': 'Stage 1',
        'description': 'First stage',
        'requiredUpgrades': 5,
        'environmentChanges': ['lights_on'],
        'unlocked': false,
      }
    ],
    'ambientAudioLayers': [
      {
        'id': '${id}_ambient',
        'name': 'Ambient',
        'assetPath': 'assets/audio/rooms/${id}_ambient.ogg',
        'volume': 0.5,
        'triggerCondition': 'always',
        'looping': true,
      }
    ],
    'secrets': [
      {
        'id': '${id}_secret_1',
        'title': 'Hidden Cache',
        'description': 'A secret stash.',
        'hint': 'Look carefully.',
        'clueSource': 'environment',
        'rewardType': 'relicFragment',
        'rewardValue': '1',
        'discovered': false,
      }
    ],
    'midSceneTwist': {
      'id': '${id}_twist',
      'title': 'Twist',
      'description': 'Something changes.',
      'triggerCondition': 'upgrades >= 25',
      'effectDescription': 'New events appear.',
      'activated': false,
    },
    'eventPoolId': 'pool_$id',
    'upgradeCategories': ['tap', 'automation'],
    'loreEntries': ['${id}_lore_1'],
    'unlockRequirement': unlockRequirement,
    'completed': false,
    'currentTransformationStage': 0,
    'eventPool': {
      'roomId': id,
      'events': [
        {
          'id': '${id}_evt_1',
          'roomId': id,
          'title': 'Test Event',
          'description': 'A test event.',
          'flavorText': 'Flavor.',
          'category': 'instant',
          'rarity': 'common',
          'durationSeconds': 10.0,
          'choices': [],
          'rewards': [
            {
              'type': 'instantCurrency',
              'value': 5.0,
              'description': 'Gain coins',
            }
          ],
          'chainBonus': 0.1,
          'requiredTwistActive': false,
          'requiredUpgradeCount': 0,
          'weight': 10,
        }
      ],
      'chainBonusMultiplier': 1.0,
      'pityThreshold': 10,
      'spawnRateMultiplier': 1.0,
      'midTwistEvents': [],
    },
  };
}

void main() {
  test('RoomSceneService initializes and returns rooms by id', () {
    final service = RoomSceneService(roomJsonList: [
      _buildRoomJson(id: 'room_01', order: 1),
      _buildRoomJson(id: 'room_02', order: 2, unlockRequirement: 'room_01'),
    ]);

    expect(service.totalRooms, 2);

    final room1 = service.getRoomById('room_01');
    expect(room1, isNotNull);
    expect(room1!.name, 'Room 1');
    expect(room1.order, 1);
    expect(room1.mechanicEmphasis, RoomMechanicEmphasis.tap);

    final room2 = service.getRoomById('room_02');
    expect(room2, isNotNull);
    expect(room2!.unlockRequirement, 'room_01');
  });

  test('getRoomByOrder returns correct room', () {
    final service = RoomSceneService(roomJsonList: [
      _buildRoomJson(id: 'room_01', order: 1),
      _buildRoomJson(id: 'room_02', order: 2, unlockRequirement: 'room_01'),
    ]);

    final room = service.getRoomByOrder(2);
    expect(room, isNotNull);
    expect(room!.id, 'room_02');
  });

  test('allRooms returns sorted list', () {
    final service = RoomSceneService(roomJsonList: [
      _buildRoomJson(id: 'room_03', order: 3, unlockRequirement: 'room_02'),
      _buildRoomJson(id: 'room_01', order: 1),
      _buildRoomJson(id: 'room_02', order: 2, unlockRequirement: 'room_01'),
    ]);

    final rooms = service.allRooms;
    expect(rooms.length, 3);
    expect(rooms[0].id, 'room_01');
    expect(rooms[1].id, 'room_02');
    expect(rooms[2].id, 'room_03');
  });

  test('getEventPool returns event pool for room', () {
    final service = RoomSceneService(roomJsonList: [
      _buildRoomJson(id: 'room_01', order: 1),
    ]);

    final pool = service.getEventPool('room_01');
    expect(pool, isNotNull);
    expect(pool!.roomId, 'room_01');
    expect(pool.events.length, 1);
    expect(pool.events.first.title, 'Test Event');
    expect(pool.events.first.category, SceneEventCategory.instant);
  });

  test('getNextRoom returns next room in order', () {
    final service = RoomSceneService(roomJsonList: [
      _buildRoomJson(id: 'room_01', order: 1),
      _buildRoomJson(id: 'room_02', order: 2, unlockRequirement: 'room_01'),
      _buildRoomJson(id: 'room_03', order: 3, unlockRequirement: 'room_02'),
    ]);

    final next = service.getNextRoom('room_01');
    expect(next, isNotNull);
    expect(next!.id, 'room_02');

    final last = service.getNextRoom('room_03');
    expect(last, isNull);
  });

  test('isRoomUnlocked checks unlock requirements', () {
    final service = RoomSceneService(roomJsonList: [
      _buildRoomJson(id: 'room_01', order: 1),
      _buildRoomJson(id: 'room_02', order: 2, unlockRequirement: 'room_01'),
    ]);

    expect(service.isRoomUnlocked('room_01', {}), isTrue);
    expect(service.isRoomUnlocked('room_02', {}), isFalse);
    expect(service.isRoomUnlocked('room_02', {'room_01'}), isTrue);
  });

  test('returns null for non-existent rooms', () {
    final service = RoomSceneService(roomJsonList: [
      _buildRoomJson(id: 'room_01', order: 1),
    ]);

    expect(service.getRoomById('nonexistent'), isNull);
    expect(service.getRoomByOrder(99), isNull);
    expect(service.getEventPool('nonexistent'), isNull);
  });

  test('skips malformed entries during initialization', () {
    final service = RoomSceneService(roomJsonList: [
      _buildRoomJson(id: 'room_01', order: 1),
      {'name': 'Missing id'},
      {'id': 'missing_order', 'name': 'Missing order'},
    ]);

    expect(service.totalRooms, 1);
  });

  test('RoomSceneState serialization roundtrip', () {
    const state = RoomSceneState(
      roomId: 'room_01',
      completed: true,
      currentTransformationStage: 3,
      secretsDiscovered: {'secret_1', 'secret_2'},
      twistActivated: true,
      upgradesPurchased: 42,
      eventsCompleted: 15,
      bestChain: 7,
    );

    final json = state.toJson();
    final restored = RoomSceneState.fromJson(json);

    expect(restored.roomId, 'room_01');
    expect(restored.completed, isTrue);
    expect(restored.currentTransformationStage, 3);
    expect(restored.secretsDiscovered, contains('secret_1'));
    expect(restored.secretsDiscovered, contains('secret_2'));
    expect(restored.twistActivated, isTrue);
    expect(restored.upgradesPurchased, 42);
    expect(restored.eventsCompleted, 15);
    expect(restored.bestChain, 7);
  });
}
