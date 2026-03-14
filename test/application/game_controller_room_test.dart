import 'package:ai_evolution/application/controllers/game_controller.dart';
import 'package:ai_evolution/application/services/config_service.dart';
import 'package:ai_evolution/application/services/room_scene_service.dart';
import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/core/time/time_provider.dart';
import 'package:ai_evolution/domain/models/game_state.dart';
import 'package:ai_evolution/domain/models/generator.dart';
import 'package:ai_evolution/domain/models/era.dart';
import 'package:ai_evolution/domain/models/gameplay_extensions.dart';
import 'package:ai_evolution/domain/models/upgrade.dart';
import 'package:flutter_test/flutter_test.dart';

class FixedTimeProvider implements TimeProvider {
  DateTime _now;
  FixedTimeProvider(this._now);

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
}

Map<String, dynamic> _buildRoomJson({
  required String id,
  required int order,
  String? unlockRequirement,
  int twistThreshold = 25,
}) {
  return {
    'id': id,
    'name': 'Room $order',
    'subtitle': 'Subtitle $order',
    'order': order,
    'introText': 'Welcome to room $order.',
    'completionText': 'Room $order complete. Well done.',
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
      },
      {
        'id': '${id}_stage_2',
        'name': 'Stage 2',
        'description': 'Second stage',
        'requiredUpgrades': 15,
        'environmentChanges': ['new_desk'],
        'unlocked': false,
      },
    ],
    'ambientAudioLayers': [],
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
      'title': 'Room $order Shift',
      'description': 'Something changes.',
      'triggerCondition': 'upgrades >= $twistThreshold',
      'effectDescription': 'New mechanics unlock.',
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
      'events': [],
      'chainBonusMultiplier': 1.0,
      'pityThreshold': 10,
      'spawnRateMultiplier': 1.0,
      'midTwistEvents': [],
    },
  };
}

void main() {
  late GeneratorDefinition genDef;
  late UpgradeDefinition tapUpgrade;
  late ConfigService config;
  late FixedTimeProvider time;
  late RoomSceneService roomService;

  setUp(() {
    genDef = GeneratorDefinition(
      id: 'gen_1',
      name: 'Test Gen',
      description: 'Test',
      eraId: 'era_1',
      baseCost: GameNumber.fromDouble(10),
      costGrowthRate: 1.15,
      baseProduction: GameNumber.fromDouble(5),
    );

    tapUpgrade = UpgradeDefinition(
      id: 'upg_tap',
      name: 'Tap Boost',
      description: 'Test',
      type: UpgradeType.tapMultiplier,
      eraId: 'era_1',
      baseCost: GameNumber.fromDouble(50),
      costGrowthRate: 1.5,
      maxLevel: 5,
      effectPerLevel: GameNumber.fromDouble(2),
    );

    config = ConfigService(
      baseTapValue: GameNumber.fromDouble(1),
      baseTapMultiplier: GameNumber.fromDouble(1),
      generators: {'gen_1': genDef},
      upgrades: {'upg_tap': tapUpgrade},
      eras: const [],
      maxOfflineHours: 8,
      autoSaveIntervalSeconds: 30,
      tickRateMs: 100,
    );

    time = FixedTimeProvider(DateTime(2026, 1, 1));

    roomService = RoomSceneService(roomJsonList: [
      _buildRoomJson(id: 'room_01', order: 1),
      _buildRoomJson(id: 'room_02', order: 2, unlockRequirement: 'room_01'),
      _buildRoomJson(id: 'room_03', order: 3, unlockRequirement: 'room_02'),
    ]);
  });

  test('controller starts with room_01 as current room', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    expect(controller.currentRoomId, 'room_01');
  });

  test('setCurrentEra synchronizes current room when era order is available', () {
    final syncedConfig = ConfigService(
      baseTapValue: GameNumber.fromDouble(1),
      baseTapMultiplier: GameNumber.fromDouble(1),
      generators: {'gen_1': genDef},
      upgrades: {'upg_tap': tapUpgrade},
      eras: const [
        Era(
          id: 'era_1',
          name: 'Room 1',
          description: 'Test',
          order: 1,
          currency: 'Coins',
          rule: 'Rule',
        ),
        Era(
          id: 'era_2',
          name: 'Room 2',
          description: 'Test',
          order: 2,
          currency: 'Coins',
          rule: 'Rule',
        ),
      ],
      maxOfflineHours: 8,
      autoSaveIntervalSeconds: 30,
      tickRateMs: 100,
    );
    final state = GameState.initial().copyWith(unlockedEras: {'era_1', 'era_2'});
    final controller = GameController(
      config: syncedConfig,
      timeProvider: time,
      initialState: state,
      roomSceneService: roomService,
    );

    expect(controller.setCurrentEra('era_2'), isTrue);
    expect(controller.currentRoomId, 'room_02');
  });

  test('currentRoom returns room data from service', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    final room = controller.currentRoom;
    expect(room, isNotNull);
    expect(room!.name, 'Room 1');
  });

  test('transitionToRoom succeeds for unlocked rooms', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    // Room 1 is unlocked by default (no requirement)
    expect(controller.transitionToRoom('room_01'), isTrue);
    expect(controller.currentRoomId, 'room_01');
  });

  test('transitionToRoom fails for locked rooms', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    // Room 2 requires room_01 to be completed
    expect(controller.transitionToRoom('room_02'), isFalse);
  });

  test('transitionToRoom succeeds after completing prerequisite', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    // Complete room_01
    expect(controller.completeCurrentRoom(), isTrue);
    // Now room_02 should be unlocked
    expect(controller.transitionToRoom('room_02'), isTrue);
    expect(controller.currentRoomId, 'room_02');
  });

  test('completeCurrentRoom marks room as completed', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    expect(controller.currentRoomState.completed, isFalse);
    expect(controller.completeCurrentRoom(), isTrue);
    expect(controller.currentRoomState.completed, isTrue);
  });

  test('completeCurrentRoom cannot complete twice', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    expect(controller.completeCurrentRoom(), isTrue);
    expect(controller.completeCurrentRoom(), isFalse);
  });

  test('completeCurrentRoom updates meta-progression', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    expect(controller.metaProgression.roomsCompleted, isEmpty);
    controller.completeCurrentRoom();
    expect(controller.metaProgression.roomsCompleted, contains('room_01'));
    expect(controller.metaProgression.totalPrestigeTokens, 1);
  });

  test('completeCurrentRoom grants relic, heirloom, memory, and archive entry', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );

    expect(controller.completeCurrentRoom(), isTrue);
    expect(
      controller.metaProgression.relics.any((item) => item.id == 'relic_room_01'),
      isTrue,
    );
    expect(
      controller.metaProgression.sceneHeirlooms.any(
        (item) => item.id == 'heirloom_room_01',
      ),
      isTrue,
    );
    expect(
      controller.metaProgression.memoryFragments.any(
        (item) => item.id == 'memory_room_01',
      ),
      isTrue,
    );
    expect(
      controller.codexState.entries.any((item) => item.id == 'relic_room_01'),
      isTrue,
    );
  });

  test('completeCurrentRoom adds codex lore entry', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    final baselineLoreCount = controller.codexState.sceneLore.length;
    controller.completeCurrentRoom();
    expect(controller.codexState.sceneLore.length, baselineLoreCount + 1);
    expect(controller.codexState.sceneLore.last.id, 'lore_complete_room_01');
  });

  test('roomsCompleted increments with each room completion', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    expect(controller.roomsCompleted, 0);
    controller.completeCurrentRoom();
    expect(controller.roomsCompleted, 1);
    controller.transitionToRoom('room_02');
    controller.completeCurrentRoom();
    expect(controller.roomsCompleted, 2);
  });

  test('discoverRoomSecret tracks secret', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    expect(controller.discoverRoomSecret('room_01_secret_1'), isTrue);
    expect(
      controller.currentRoomState.secretsDiscovered,
      contains('room_01_secret_1'),
    );
    // Cannot discover same secret twice
    expect(controller.discoverRoomSecret('room_01_secret_1'), isFalse);
  });

  test('discoverRoomSecret updates meta and codex', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    final baselineSecretCount = controller.codexState.secretArchive.length;
    controller.discoverRoomSecret('room_01_secret_1');
    expect(
      controller.metaProgression.secretsArchived,
      contains('room_01_secret_1'),
    );
    expect(controller.codexState.secretArchive.length, baselineSecretCount);
    final archived = controller.codexState.secretArchive.firstWhere(
      (entry) => entry.id == 'room_01_secret_1',
    );
    expect(archived.discovered, isTrue);
  });

  test('discoverRoomSecret grants memory, shard, and reward archive entry', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );

    expect(controller.discoverRoomSecret('room_01_secret_1'), isTrue);
    expect(
      controller.metaProgression.memoryFragments.any(
        (item) => item.id == 'secret_memory_room_01_secret_1',
      ),
      isTrue,
    );
    expect(
      controller.metaProgression.blueprintShards.any(
        (item) => item.id == 'secret_shard_room_01_secret_1',
      ),
      isTrue,
    );
    expect(
      controller.codexState.entries.any(
        (item) => item.id == 'secret_reward_room_01_secret_1',
      ),
      isTrue,
    );
  });

  test('activateRoomTwist activates twist', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    expect(controller.twistActivated, isFalse);
    expect(controller.activateRoomTwist(), isTrue);
    expect(controller.twistActivated, isTrue);
    // Cannot activate twice
    expect(controller.activateRoomTwist(), isFalse);
  });

  test('guideTrustLevel returns appropriate label', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    // Default guide affinity is 2.0 (from GameState.initial)
    // guideTier = 1 + (2.0 ~/ 6).clamp(0, 4) = 1
    expect(controller.guideTrustLevel, 'Cautious');
  });

  test('guideTrustLevel changes with affinity', () {
    final stateWithHighAffinity = GameState.initial().copyWith(
      guideAffinity: 18.0,
    );
    final controller = GameController(
      config: config,
      timeProvider: time,
      initialState: stateWithHighAffinity,
      roomSceneService: roomService,
    );
    // guideTier = 1 + (18.0 ~/ 6).clamp(0, 4) = 1 + 3 = 4
    expect(controller.guideTrustLevel, 'Trusted');
  });

  test('recordGuideMemory adds to codex', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    final baselineMemories = controller.codexState.guideMemories.length;
    controller.recordGuideMemory(
      id: 'mem_test',
      title: 'Test Memory',
      content: 'A test guide memory.',
    );
    expect(controller.codexState.guideMemories.length, baselineMemories + 1);
    expect(controller.codexState.guideMemories.last.id, 'mem_test');
  });

  test('recordGuideMemory avoids duplicates', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    controller.recordGuideMemory(
      id: 'mem_test',
      title: 'Test Memory',
      content: 'A test guide memory.',
    );
    controller.recordGuideMemory(
      id: 'mem_test',
      title: 'Test Memory',
      content: 'A test guide memory.',
    );
    expect(controller.codexState.guideMemories.length, 1);
  });

  test('totalRooms returns count from room service', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    expect(controller.totalRooms, 3);
  });

  test('nextRoom returns correct next room', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    expect(controller.nextRoom?.id, 'room_02');
  });

  test('controller works without roomSceneService', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
    );
    // Should not crash when room service is null
    expect(controller.currentRoom, isNull);
    expect(controller.nextRoom, isNull);
    expect(controller.transitionToRoom('room_01'), isFalse);
    expect(controller.totalRooms, 20); // default fallback
  });

  test('guide affinity increases on room actions', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );
    final initialAffinity = controller.guideAffinity;
    controller.discoverRoomSecret('room_01_secret_1');
    expect(controller.guideAffinity, greaterThan(initialAffinity));
  });

  test('claimChallengeReward updates meta, codex, and claim state', () {
    const challenge = ChallengeState(
      id: 'weekly_room_mastery',
      period: ChallengePeriod.weekly,
      metric: ChallengeMetric.upgradesBought,
      title: 'Weekly Room Mastery',
      description: 'Complete a weekly mastery pass.',
      target: 10,
      progress: 10,
      completed: true,
      seasonKey: '2026-W01',
    );
    final seeded = GameState.initial().copyWith(
      totalCoinsEarned: GameNumber.fromDouble(10000),
      challenges: [challenge],
    );
    final controller = GameController(
      config: config,
      timeProvider: time,
      initialState: seeded,
      roomSceneService: roomService,
    );

    expect(controller.claimChallengeReward('weekly_room_mastery'), isTrue);
    expect(controller.metaProgression.challengesCleared, 1);
    expect(
      controller.metaProgression.blueprintShards.any(
        (item) => item.id == 'challenge_weekly_room_mastery',
      ),
      isTrue,
    );
    expect(
      controller.codexState.entries.any(
        (item) => item.id == 'challenge_weekly_room_mastery',
      ),
      isTrue,
    );
    expect(
      controller.challenges
          .firstWhere((item) => item.id == 'weekly_room_mastery')
          .claimed,
      isTrue,
    );
  });

  test('prestige preserves meta-progression and codex', () {
    // Start with enough coins for prestige
    final rich = GameState.initial().copyWith(
      coins: GameNumber.fromDouble(2000000),
      totalCoinsEarned: GameNumber.fromDouble(2000000),
    );
    final controller = GameController(
      config: config,
      timeProvider: time,
      initialState: rich,
      roomSceneService: roomService,
    );
    controller.completeCurrentRoom();
    expect(controller.metaProgression.roomsCompleted, isNotEmpty);
    expect(controller.codexState.sceneLore, isNotEmpty);

    final metaBefore = controller.metaProgression;
    final codexBefore = controller.codexState;

    if (controller.canPrestige) {
      controller.prestige();
      // Meta-progression and codex should survive prestige
      expect(controller.metaProgression.roomsCompleted, metaBefore.roomsCompleted);
      expect(controller.codexState.sceneLore.length, codexBefore.sceneLore.length);
    }
  });

  test('bootstraps room collections from room service', () {
    final controller = GameController(
      config: config,
      timeProvider: time,
      roomSceneService: roomService,
    );

    expect(controller.codexState.secretArchive.length, 3);
    expect(controller.codexState.sceneLore.length, 3);
    expect(controller.codexState.entries.length, 3);
  });
}
