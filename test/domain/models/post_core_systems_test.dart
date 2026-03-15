import 'package:ai_evolution/domain/models/post_core_systems.dart';
import 'package:ai_evolution/application/services/post_core_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _buildSampleConfig() {
  return {
    'masteryGoals': [
      for (final type in MasteryGoalType.values)
        {
          'id': 'mg_${type.name}',
          'roomId': 'room_01',
          'type': type.name,
          'title': 'Goal ${type.name}',
          'description': 'Achieve ${type.name}',
          'targetValue': 10,
          'currentValue': 0,
          'completed': false,
          'rewardType': 'cosmetic',
          'rewardId': 'reward_${type.name}',
        },
    ],
    'relicSets': [
      {
        'id': 'rset_ancient',
        'name': 'Ancient Set',
        'description': 'Collect ancient relics.',
        'theme': 'ancient',
        'requiredRelicIds': ['relic_a', 'relic_b'],
        'setBonusDescription': '2x production',
        'setBonusType': 'production',
        'setBonusMagnitude': 2.0,
      },
    ],
    'multiRoomSecrets': [
      {
        'id': 'mrs_hidden',
        'title': 'The Hidden Truth',
        'description': 'A secret spanning rooms.',
        'clues': [
          {
            'id': 'clue_01',
            'roomId': 'room_01',
            'clueText': 'Look under the mat.',
            'order': 1,
            'discovered': false,
          },
          {
            'id': 'clue_02',
            'roomId': 'room_02',
            'clueText': 'Behind the painting.',
            'order': 2,
            'discovered': false,
          },
        ],
        'payoffDescription': 'The truth is revealed.',
        'payoffRoomId': 'room_02',
        'rewardType': 'cosmetic',
        'rewardId': 'reward_hidden',
        'solved': false,
      },
    ],
    'contracts': [
      {
        'id': 'ct_combo',
        'roomId': 'room_01',
        'title': 'Combo Master',
        'description': 'Reach combo 50.',
        'metric': 'combo',
        'targetValue': 50,
        'currentValue': 0,
        'completed': false,
        'rewardType': 'cosmetic',
        'rewardId': 'reward_combo',
      },
      {
        'id': 'ct_speed',
        'roomId': 'room_01',
        'title': 'Speed Runner',
        'description': 'Clear in under 60s.',
        'metric': 'clearTime',
        'targetValue': 60,
        'currentValue': 0,
        'completed': false,
        'rewardType': 'cosmetic',
        'rewardId': 'reward_speed',
      },
    ],
    'archiveRewards': [
      {
        'id': 'ar_lore_5',
        'archiveSection': 'lore',
        'requiredEntries': 5,
        'rewardType': 'cosmetic',
        'rewardDescription': 'Unlock lore badge.',
        'rewardValue': 1.0,
        'claimed': false,
      },
      {
        'id': 'ar_lore_10',
        'archiveSection': 'lore',
        'requiredEntries': 10,
        'rewardType': 'cosmetic',
        'rewardDescription': 'Unlock lore crown.',
        'rewardValue': 2.0,
        'claimed': false,
      },
    ],
    'revisitUnlocks': {
      'room_01': [
        {
          'id': 'rv_hidden_path',
          'roomId': 'room_01',
          'title': 'Hidden Path',
          'description': 'A hidden path opens.',
          'triggerCondition': 'room_02_complete',
          'unlockType': 'path',
          'unlocked': false,
          'discovered': false,
        },
      ],
    },
    'atmospheres': {
      'room_01': {
        'roomId': 'room_01',
        'elements': [
          {
            'id': 'el_dust',
            'roomId': 'room_01',
            'elementType': 'particle',
            'description': 'Dust motes floating.',
            'triggerCondition': 'always',
            'intensity': 0.5,
            'reactive': false,
          },
        ],
        'lightingPreset': 'warm',
        'landmarkReactivity': 'responsive',
        'scarsHistory': ['burn_mark'],
      },
    },
    'featuredRotation': [
      {
        'roomId': 'room_01',
        'weekKey': '2024-W03',
        'rewardMultiplier': 1.5,
        'specialEventId': 'evt_special',
        'codexGainBonus': 0.1,
        'relicFragmentChanceBonus': 0.05,
        'visualThemeAccent': '#FF0000',
      },
    ],
    'guideSideObjectives': [
      {
        'id': 'gso_explore',
        'title': 'Explore Thoroughly',
        'description': 'Visit every corner.',
        'condition': 'exploration >= 100',
        'completed': false,
        'rewardDescription': 'Guide approves.',
      },
    ],
    'cosmeticRewards': [
      {
        'id': 'cos_badge',
        'name': 'Room Badge',
        'description': 'A shiny badge.',
        'type': 'roomBadge',
        'roomId': 'room_01',
        'unlocked': false,
      },
      {
        'id': 'cos_theme',
        'name': 'Dark Theme',
        'description': 'A dark ambient theme.',
        'type': 'ambientTheme',
        'unlocked': false,
      },
    ],
  };
}

void main() {
  // ─── 1. RoomMasteryGoal serialization ───────────────────────────────

  group('RoomMasteryGoal serialization', () {
    test('roundtrip toJson/fromJson', () {
      const goal = RoomMasteryGoal(
        id: 'mg_fast',
        roomId: 'room_01',
        type: MasteryGoalType.fastestClear,
        title: 'Speed Demon',
        description: 'Clear the room quickly.',
        targetValue: 30,
        currentValue: 15,
        completed: false,
        rewardType: 'cosmetic',
        rewardId: 'reward_fast',
      );

      final json = goal.toJson();
      expect(json['id'], 'mg_fast');
      expect(json['type'], 'fastestClear');

      final restored = RoomMasteryGoal.fromJson(json);
      expect(restored.id, goal.id);
      expect(restored.roomId, goal.roomId);
      expect(restored.type, goal.type);
      expect(restored.title, goal.title);
      expect(restored.description, goal.description);
      expect(restored.targetValue, goal.targetValue);
      expect(restored.currentValue, goal.currentValue);
      expect(restored.completed, goal.completed);
      expect(restored.rewardType, goal.rewardType);
      expect(restored.rewardId, goal.rewardId);
    });
  });

  // ─── 2. RoomMasteryProfile serialization ────────────────────────────

  group('RoomMasteryProfile serialization', () {
    test('roundtrip with goals list', () {
      const profile = RoomMasteryProfile(
        roomId: 'room_01',
        starsEarned: 5,
        rank: 'gold',
        goals: [
          RoomMasteryGoal(
            id: 'mg_combo',
            roomId: 'room_01',
            type: MasteryGoalType.highComboClear,
            title: 'Combo King',
            description: 'Hit combo 50.',
            targetValue: 50,
            currentValue: 50,
            completed: true,
            rewardType: 'cosmetic',
            rewardId: 'reward_combo',
          ),
        ],
        bestClearTimeSeconds: 120,
        bestCombo: 50,
        allSecretsFound: true,
        archiveComplete: false,
      );

      final json = profile.toJson();
      final restored = RoomMasteryProfile.fromJson(json);

      expect(restored.roomId, profile.roomId);
      expect(restored.starsEarned, profile.starsEarned);
      expect(restored.rank, profile.rank);
      expect(restored.goals, hasLength(1));
      expect(restored.goals.first.id, 'mg_combo');
      expect(restored.goals.first.completed, isTrue);
      expect(restored.bestClearTimeSeconds, profile.bestClearTimeSeconds);
      expect(restored.bestCombo, profile.bestCombo);
      expect(restored.allSecretsFound, isTrue);
      expect(restored.archiveComplete, isFalse);
    });
  });

  // ─── 3. GuideMood / GuideTrustPath enums ───────────────────────────

  group('GuideMood/GuideTrustPath enums', () {
    test('GuideMood has 7 values', () {
      expect(GuideMood.values.length, 7);
    });

    test('GuideTrustPath has 4 values', () {
      expect(GuideTrustPath.values.length, 4);
    });
  });

  // ─── 4. GuideSideObjective serialization ────────────────────────────

  group('GuideSideObjective serialization', () {
    test('roundtrip toJson/fromJson', () {
      const objective = GuideSideObjective(
        id: 'gso_explore',
        title: 'Explore Thoroughly',
        description: 'Visit every corner.',
        condition: 'exploration >= 100',
        completed: true,
        rewardDescription: 'Guide approves.',
      );

      final json = objective.toJson();
      expect(json['id'], 'gso_explore');
      expect(json['completed'], isTrue);

      final restored = GuideSideObjective.fromJson(json);
      expect(restored.id, objective.id);
      expect(restored.title, objective.title);
      expect(restored.description, objective.description);
      expect(restored.condition, objective.condition);
      expect(restored.completed, objective.completed);
      expect(restored.rewardDescription, objective.rewardDescription);
    });
  });

  // ─── 5. GuideState serialization ────────────────────────────────────

  group('GuideState serialization', () {
    test('roundtrip with all fields', () {
      const state = GuideState(
        currentMood: GuideMood.fascinated,
        trustPath: GuideTrustPath.highTrust,
        trustLevel: 8,
        affinityScore: 3.5,
        sideObjectives: [
          GuideSideObjective(
            id: 'gso_1',
            title: 'Task',
            description: 'Do it.',
            condition: 'always',
            rewardDescription: 'Good.',
          ),
        ],
        completedObjectiveIds: {'gso_0'},
        behaviorCounters: {'carefulPlay': 3, 'recklessPlay': 1},
        unlockedDialogueBranches: {'branch_a', 'branch_b'},
      );

      final json = state.toJson();
      final restored = GuideState.fromJson(json);

      expect(restored.currentMood, GuideMood.fascinated);
      expect(restored.trustPath, GuideTrustPath.highTrust);
      expect(restored.trustLevel, 8);
      expect(restored.affinityScore, 3.5);
      expect(restored.sideObjectives, hasLength(1));
      expect(restored.sideObjectives.first.id, 'gso_1');
      expect(restored.completedObjectiveIds, contains('gso_0'));
      expect(restored.behaviorCounters['carefulPlay'], 3);
      expect(restored.behaviorCounters['recklessPlay'], 1);
      expect(restored.unlockedDialogueBranches, contains('branch_a'));
      expect(restored.unlockedDialogueBranches, contains('branch_b'));
    });
  });

  // ─── 6. RelicSetDefinition serialization ────────────────────────────

  group('RelicSetDefinition serialization', () {
    test('roundtrip toJson/fromJson', () {
      const def = RelicSetDefinition(
        id: 'rset_ancient',
        name: 'Ancient Set',
        description: 'Collect ancient relics.',
        theme: 'ancient',
        requiredRelicIds: ['relic_a', 'relic_b'],
        setBonusDescription: '2x production',
        setBonusType: 'production',
        setBonusMagnitude: 2.0,
      );

      final json = def.toJson();
      expect(json['id'], 'rset_ancient');
      expect(json['requiredRelicIds'], hasLength(2));

      final restored = RelicSetDefinition.fromJson(json);
      expect(restored.id, def.id);
      expect(restored.name, def.name);
      expect(restored.description, def.description);
      expect(restored.theme, def.theme);
      expect(restored.requiredRelicIds, def.requiredRelicIds);
      expect(restored.setBonusDescription, def.setBonusDescription);
      expect(restored.setBonusType, def.setBonusType);
      expect(restored.setBonusMagnitude, def.setBonusMagnitude);
    });
  });

  // ─── 7. RelicSetProgress serialization ──────────────────────────────

  group('RelicSetProgress serialization', () {
    test('roundtrip with Sets', () {
      const progress = RelicSetProgress(
        setId: 'rset_ancient',
        collectedRelicIds: {'relic_a', 'relic_b'},
        completed: true,
        bonusActive: true,
      );

      final json = progress.toJson();
      expect(json['setId'], 'rset_ancient');
      expect(json['collectedRelicIds'], hasLength(2));

      final restored = RelicSetProgress.fromJson(json);
      expect(restored.setId, progress.setId);
      expect(restored.collectedRelicIds, contains('relic_a'));
      expect(restored.collectedRelicIds, contains('relic_b'));
      expect(restored.completed, isTrue);
      expect(restored.bonusActive, isTrue);
    });
  });

  // ─── 8. DelayedConsequence serialization ────────────────────────────

  group('DelayedConsequence serialization', () {
    test('roundtrip with outcomeData map', () {
      final consequence = DelayedConsequence(
        id: 'dc_bonus',
        sourceEventId: 'evt_choice',
        sourceRoomId: 'room_01',
        description: 'A delayed bonus.',
        timing: ConsequenceTiming.futureRoom,
        targetRoomId: 'room_02',
        outcomeType: 'bonus',
        outcomeDescription: 'Extra coins next room.',
        outcomeData: const {'amount': 100, 'type': 'coins'},
        resolved: false,
        createdAt: DateTime.utc(2024, 1, 15, 10, 30),
      );

      final json = consequence.toJson();
      expect(json['id'], 'dc_bonus');
      expect(json['timing'], 'futureRoom');
      expect(json['outcomeData'], isA<Map>());
      expect(json['createdAt'], isNotNull);

      final restored = DelayedConsequence.fromJson(json);
      expect(restored.id, consequence.id);
      expect(restored.sourceEventId, consequence.sourceEventId);
      expect(restored.sourceRoomId, consequence.sourceRoomId);
      expect(restored.description, consequence.description);
      expect(restored.timing, ConsequenceTiming.futureRoom);
      expect(restored.targetRoomId, 'room_02');
      expect(restored.outcomeType, consequence.outcomeType);
      expect(restored.outcomeDescription, consequence.outcomeDescription);
      expect(restored.outcomeData['amount'], 100);
      expect(restored.outcomeData['type'], 'coins');
      expect(restored.resolved, isFalse);
      expect(restored.createdAt, consequence.createdAt);
    });
  });

  // ─── 9. RevisitUnlock serialization ─────────────────────────────────

  group('RevisitUnlock serialization', () {
    test('roundtrip toJson/fromJson', () {
      const unlock = RevisitUnlock(
        id: 'rv_path',
        roomId: 'room_01',
        title: 'Hidden Path',
        description: 'A hidden path opens.',
        triggerCondition: 'room_02_complete',
        unlockType: 'path',
        unlocked: true,
        discovered: true,
      );

      final json = unlock.toJson();
      expect(json['id'], 'rv_path');
      expect(json['unlocked'], isTrue);

      final restored = RevisitUnlock.fromJson(json);
      expect(restored.id, unlock.id);
      expect(restored.roomId, unlock.roomId);
      expect(restored.title, unlock.title);
      expect(restored.description, unlock.description);
      expect(restored.triggerCondition, unlock.triggerCondition);
      expect(restored.unlockType, unlock.unlockType);
      expect(restored.unlocked, isTrue);
      expect(restored.discovered, isTrue);
    });
  });

  // ─── 10. ArchiveCompletionReward serialization ──────────────────────

  group('ArchiveCompletionReward serialization', () {
    test('roundtrip toJson/fromJson', () {
      const reward = ArchiveCompletionReward(
        id: 'ar_lore_5',
        archiveSection: 'lore',
        requiredEntries: 5,
        rewardType: 'cosmetic',
        rewardDescription: 'Unlock lore badge.',
        rewardValue: 1.5,
        claimed: true,
      );

      final json = reward.toJson();
      expect(json['id'], 'ar_lore_5');
      expect(json['claimed'], isTrue);

      final restored = ArchiveCompletionReward.fromJson(json);
      expect(restored.id, reward.id);
      expect(restored.archiveSection, reward.archiveSection);
      expect(restored.requiredEntries, reward.requiredEntries);
      expect(restored.rewardType, reward.rewardType);
      expect(restored.rewardDescription, reward.rewardDescription);
      expect(restored.rewardValue, reward.rewardValue);
      expect(restored.claimed, isTrue);
    });
  });

  // ─── 11. MicroLifeElement serialization ─────────────────────────────

  group('MicroLifeElement serialization', () {
    test('roundtrip toJson/fromJson', () {
      const element = MicroLifeElement(
        id: 'el_dust',
        roomId: 'room_01',
        elementType: 'particle',
        description: 'Dust motes floating.',
        triggerCondition: 'always',
        intensity: 0.7,
        reactive: true,
      );

      final json = element.toJson();
      expect(json['id'], 'el_dust');
      expect(json['reactive'], isTrue);

      final restored = MicroLifeElement.fromJson(json);
      expect(restored.id, element.id);
      expect(restored.roomId, element.roomId);
      expect(restored.elementType, element.elementType);
      expect(restored.description, element.description);
      expect(restored.triggerCondition, element.triggerCondition);
      expect(restored.intensity, element.intensity);
      expect(restored.reactive, isTrue);
    });
  });

  // ─── 12. RoomAtmosphereConfig serialization ─────────────────────────

  group('RoomAtmosphereConfig serialization', () {
    test('roundtrip toJson/fromJson', () {
      const config = RoomAtmosphereConfig(
        roomId: 'room_01',
        elements: [
          MicroLifeElement(
            id: 'el_spark',
            roomId: 'room_01',
            elementType: 'effect',
            description: 'Sparks fly.',
          ),
        ],
        lightingPreset: 'neon',
        landmarkReactivity: 'responsive',
        scarsHistory: ['burn_mark', 'crack'],
      );

      final json = config.toJson();
      expect(json['roomId'], 'room_01');
      expect(json['elements'], hasLength(1));
      expect(json['scarsHistory'], hasLength(2));

      final restored = RoomAtmosphereConfig.fromJson(json);
      expect(restored.roomId, config.roomId);
      expect(restored.elements, hasLength(1));
      expect(restored.elements.first.id, 'el_spark');
      expect(restored.lightingPreset, 'neon');
      expect(restored.landmarkReactivity, 'responsive');
      expect(restored.scarsHistory, ['burn_mark', 'crack']);
    });
  });

  // ─── 13. FeaturedRoomConfig serialization ───────────────────────────

  group('FeaturedRoomConfig serialization', () {
    test('roundtrip toJson/fromJson', () {
      const config = FeaturedRoomConfig(
        roomId: 'room_01',
        weekKey: '2024-W03',
        rewardMultiplier: 1.5,
        specialEventId: 'evt_special',
        challengeModifierId: 'mod_hard',
        codexGainBonus: 0.1,
        relicFragmentChanceBonus: 0.05,
        visualThemeAccent: '#FF0000',
      );

      final json = config.toJson();
      expect(json['roomId'], 'room_01');
      expect(json['weekKey'], '2024-W03');

      final restored = FeaturedRoomConfig.fromJson(json);
      expect(restored.roomId, config.roomId);
      expect(restored.weekKey, config.weekKey);
      expect(restored.rewardMultiplier, config.rewardMultiplier);
      expect(restored.specialEventId, 'evt_special');
      expect(restored.challengeModifierId, 'mod_hard');
      expect(restored.codexGainBonus, config.codexGainBonus);
      expect(restored.relicFragmentChanceBonus,
          config.relicFragmentChanceBonus);
      expect(restored.visualThemeAccent, '#FF0000');
    });
  });

  // ─── 14. PersonalBestRecord serialization ───────────────────────────

  group('PersonalBestRecord serialization', () {
    test('roundtrip with milestoneTimings', () {
      final record = PersonalBestRecord(
        roomId: 'room_01',
        bestPaceSeconds: 45,
        bestCombo: 30,
        bestEventChain: 5,
        bestCompletionStyle: 'aggressive',
        milestoneTimings: const {'first_upgrade': 10, 'half_done': 25},
        recordDate: DateTime.utc(2024, 1, 15, 10, 30),
      );

      final json = record.toJson();
      expect(json['roomId'], 'room_01');
      expect(json['milestoneTimings'], isA<Map>());
      expect(json['recordDate'], isNotNull);

      final restored = PersonalBestRecord.fromJson(json);
      expect(restored.roomId, record.roomId);
      expect(restored.bestPaceSeconds, record.bestPaceSeconds);
      expect(restored.bestCombo, record.bestCombo);
      expect(restored.bestEventChain, record.bestEventChain);
      expect(restored.bestCompletionStyle, 'aggressive');
      expect(restored.milestoneTimings['first_upgrade'], 10);
      expect(restored.milestoneTimings['half_done'], 25);
      expect(restored.recordDate, record.recordDate);
    });
  });

  // ─── 15. MultiRoomSecretClue serialization ──────────────────────────

  group('MultiRoomSecretClue serialization', () {
    test('roundtrip toJson/fromJson', () {
      const clue = MultiRoomSecretClue(
        id: 'clue_01',
        roomId: 'room_01',
        clueText: 'Look under the mat.',
        order: 1,
        discovered: true,
      );

      final json = clue.toJson();
      expect(json['id'], 'clue_01');
      expect(json['discovered'], isTrue);

      final restored = MultiRoomSecretClue.fromJson(json);
      expect(restored.id, clue.id);
      expect(restored.roomId, clue.roomId);
      expect(restored.clueText, clue.clueText);
      expect(restored.order, clue.order);
      expect(restored.discovered, isTrue);
    });
  });

  // ─── 16. MultiRoomSecret serialization ──────────────────────────────

  group('MultiRoomSecret serialization', () {
    test('roundtrip with clues list', () {
      const secret = MultiRoomSecret(
        id: 'mrs_hidden',
        title: 'The Hidden Truth',
        description: 'A secret spanning rooms.',
        clues: [
          MultiRoomSecretClue(
            id: 'clue_01',
            roomId: 'room_01',
            clueText: 'Look under the mat.',
            order: 1,
          ),
          MultiRoomSecretClue(
            id: 'clue_02',
            roomId: 'room_02',
            clueText: 'Behind the painting.',
            order: 2,
          ),
        ],
        payoffDescription: 'The truth is revealed.',
        payoffRoomId: 'room_02',
        rewardType: 'cosmetic',
        rewardId: 'reward_hidden',
        solved: false,
      );

      final json = secret.toJson();
      expect(json['clues'], hasLength(2));

      final restored = MultiRoomSecret.fromJson(json);
      expect(restored.id, secret.id);
      expect(restored.title, secret.title);
      expect(restored.description, secret.description);
      expect(restored.clues, hasLength(2));
      expect(restored.clues[0].id, 'clue_01');
      expect(restored.clues[1].id, 'clue_02');
      expect(restored.payoffDescription, secret.payoffDescription);
      expect(restored.payoffRoomId, secret.payoffRoomId);
      expect(restored.rewardType, secret.rewardType);
      expect(restored.rewardId, secret.rewardId);
      expect(restored.solved, isFalse);
    });
  });

  // ─── 17. MasteryContract serialization ──────────────────────────────

  group('MasteryContract serialization', () {
    test('roundtrip toJson/fromJson', () {
      const contract = MasteryContract(
        id: 'ct_combo',
        roomId: 'room_01',
        title: 'Combo Master',
        description: 'Reach combo 50.',
        metric: 'combo',
        targetValue: 50,
        currentValue: 25,
        completed: false,
        rewardType: 'cosmetic',
        rewardId: 'reward_combo',
      );

      final json = contract.toJson();
      expect(json['id'], 'ct_combo');
      expect(json['currentValue'], 25);

      final restored = MasteryContract.fromJson(json);
      expect(restored.id, contract.id);
      expect(restored.roomId, contract.roomId);
      expect(restored.title, contract.title);
      expect(restored.description, contract.description);
      expect(restored.metric, contract.metric);
      expect(restored.targetValue, contract.targetValue);
      expect(restored.currentValue, contract.currentValue);
      expect(restored.completed, isFalse);
      expect(restored.rewardType, contract.rewardType);
      expect(restored.rewardId, contract.rewardId);
    });
  });

  // ─── 18. RoomSummaryReport serialization ────────────────────────────

  group('RoomSummaryReport serialization', () {
    test('roundtrip toJson/fromJson', () {
      final report = RoomSummaryReport(
        roomId: 'room_01',
        generatedAt: DateTime.utc(2024, 1, 15, 10, 30),
        items: const [
          RoomSummaryItem(
            category: 'mastery',
            description: 'Speed Demon completed',
            relatedId: 'mg_fast',
          ),
          RoomSummaryItem(
            category: 'personalBest',
            description: 'Pace: 45s, Combo: 30',
          ),
        ],
        totalNewEntries: 2,
        totalNewSecrets: 1,
        masteryStarsGained: 3,
      );

      final json = report.toJson();
      expect(json['roomId'], 'room_01');
      expect(json['items'], hasLength(2));

      final restored = RoomSummaryReport.fromJson(json);
      expect(restored.roomId, report.roomId);
      expect(restored.generatedAt, report.generatedAt);
      expect(restored.items, hasLength(2));
      expect(restored.items[0].category, 'mastery');
      expect(restored.items[0].relatedId, 'mg_fast');
      expect(restored.items[1].relatedId, isNull);
      expect(restored.totalNewEntries, 2);
      expect(restored.totalNewSecrets, 1);
      expect(restored.masteryStarsGained, 3);
    });
  });

  // ─── 19. CosmeticReward serialization ───────────────────────────────

  group('CosmeticReward serialization', () {
    test('roundtrip toJson/fromJson', () {
      const reward = CosmeticReward(
        id: 'cos_badge',
        name: 'Room Badge',
        description: 'A shiny badge.',
        type: CosmeticRewardType.roomBadge,
        roomId: 'room_01',
        unlocked: true,
      );

      final json = reward.toJson();
      expect(json['id'], 'cos_badge');
      expect(json['type'], 'roomBadge');
      expect(json['unlocked'], isTrue);

      final restored = CosmeticReward.fromJson(json);
      expect(restored.id, reward.id);
      expect(restored.name, reward.name);
      expect(restored.description, reward.description);
      expect(restored.type, CosmeticRewardType.roomBadge);
      expect(restored.roomId, 'room_01');
      expect(restored.unlocked, isTrue);
    });
  });

  // ─── 20. CommunityStats serialization ───────────────────────────────

  group('CommunityStats serialization', () {
    test('roundtrip toJson/fromJson', () {
      const stats = CommunityStats(
        roomCompletionPercentages: {'room_01': 75.5, 'room_02': 30.0},
        mostCommonRoutePerRoom: {'room_01': 'route_a'},
        rareSecretFoundPercentages: {'secret_x': 5.2},
        globalAnomalyTotal: 42,
        featuredRoomParticipation: {'room_01': 1500},
      );

      final json = stats.toJson();
      expect(json['globalAnomalyTotal'], 42);

      final restored = CommunityStats.fromJson(json);
      expect(restored.roomCompletionPercentages['room_01'], 75.5);
      expect(restored.roomCompletionPercentages['room_02'], 30.0);
      expect(restored.mostCommonRoutePerRoom['room_01'], 'route_a');
      expect(restored.rareSecretFoundPercentages['secret_x'], 5.2);
      expect(restored.globalAnomalyTotal, 42);
      expect(restored.featuredRoomParticipation['room_01'], 1500);
    });
  });

  // ─── 21–22. PostCoreState serialization ─────────────────────────────

  group('PostCoreState serialization', () {
    test('full roundtrip of aggregate state', () {
      final state = PostCoreState(
        roomMastery: const {
          'room_01': RoomMasteryProfile(
            roomId: 'room_01',
            starsEarned: 5,
            rank: 'gold',
          ),
        },
        guideState: const GuideState(
          currentMood: GuideMood.proud,
          trustPath: GuideTrustPath.highTrust,
          trustLevel: 8,
          affinityScore: 3.5,
          behaviorCounters: {'carefulPlay': 3},
        ),
        relicSetProgress: const [
          RelicSetProgress(
            setId: 'rset_ancient',
            collectedRelicIds: {'relic_a'},
          ),
        ],
        pendingConsequences: [
          DelayedConsequence(
            id: 'dc_1',
            sourceEventId: 'evt_1',
            sourceRoomId: 'room_01',
            description: 'A consequence.',
            timing: ConsequenceTiming.futureRoom,
            targetRoomId: 'room_02',
            outcomeType: 'bonus',
            outcomeDescription: 'Extra coins.',
            createdAt: DateTime.utc(2024, 1, 15),
          ),
        ],
        resolvedConsequences: const [],
        revisitUnlocks: const {
          'room_01': [
            RevisitUnlock(
              id: 'rv_1',
              roomId: 'room_01',
              title: 'Hidden Path',
              description: 'A path.',
              triggerCondition: 'room_02_complete',
              unlockType: 'path',
              unlocked: true,
              discovered: true,
            ),
          ],
        },
        archiveRewards: const [
          ArchiveCompletionReward(
            id: 'ar_1',
            archiveSection: 'lore',
            requiredEntries: 5,
            rewardType: 'cosmetic',
            rewardDescription: 'Badge.',
            claimed: true,
          ),
        ],
        currentFeaturedRoom: const FeaturedRoomConfig(
          roomId: 'room_01',
          weekKey: '2024-W03',
          rewardMultiplier: 1.5,
        ),
        personalBests: {
          'room_01': PersonalBestRecord(
            roomId: 'room_01',
            bestPaceSeconds: 45,
            bestCombo: 30,
            milestoneTimings: const {'half': 20},
            recordDate: DateTime.utc(2024, 1, 15),
          ),
        },
        multiRoomSecrets: const [
          MultiRoomSecret(
            id: 'mrs_1',
            title: 'Secret',
            description: 'A secret.',
            clues: [
              MultiRoomSecretClue(
                id: 'clue_a',
                roomId: 'room_01',
                clueText: 'Clue A.',
              ),
            ],
            payoffDescription: 'Payoff.',
            payoffRoomId: 'room_02',
            rewardType: 'cosmetic',
            rewardId: 'reward_1',
          ),
        ],
        activeContracts: const [
          MasteryContract(
            id: 'ct_1',
            roomId: 'room_01',
            title: 'Contract',
            description: 'Do stuff.',
            metric: 'combo',
            targetValue: 50,
            rewardType: 'cosmetic',
            rewardId: 'reward_ct',
          ),
        ],
        completedContracts: const [],
        cosmeticRewards: const [
          CosmeticReward(
            id: 'cos_1',
            name: 'Badge',
            description: 'A badge.',
            type: CosmeticRewardType.roomBadge,
            unlocked: true,
          ),
        ],
        communityStats: const CommunityStats(
          roomCompletionPercentages: {'room_01': 75.5},
          globalAnomalyTotal: 42,
        ),
      );

      final json = state.toJson();
      final restored = PostCoreState.fromJson(json);

      // Room mastery
      expect(restored.roomMastery.containsKey('room_01'), isTrue);
      expect(restored.roomMastery['room_01']!.starsEarned, 5);
      expect(restored.roomMastery['room_01']!.rank, 'gold');

      // Guide state
      expect(restored.guideState.currentMood, GuideMood.proud);
      expect(restored.guideState.trustLevel, 8);
      expect(restored.guideState.affinityScore, 3.5);
      expect(restored.guideState.behaviorCounters['carefulPlay'], 3);

      // Relic set progress
      expect(restored.relicSetProgress, hasLength(1));
      expect(restored.relicSetProgress.first.setId, 'rset_ancient');
      expect(
          restored.relicSetProgress.first.collectedRelicIds,
          contains('relic_a'));

      // Pending consequences
      expect(restored.pendingConsequences, hasLength(1));
      expect(restored.pendingConsequences.first.id, 'dc_1');
      expect(restored.pendingConsequences.first.targetRoomId, 'room_02');
      expect(
          restored.pendingConsequences.first.createdAt,
          DateTime.utc(2024, 1, 15));

      // Resolved consequences
      expect(restored.resolvedConsequences, isEmpty);

      // Revisit unlocks
      expect(restored.revisitUnlocks.containsKey('room_01'), isTrue);
      expect(restored.revisitUnlocks['room_01']!, hasLength(1));
      expect(restored.revisitUnlocks['room_01']!.first.unlocked, isTrue);

      // Archive rewards
      expect(restored.archiveRewards, hasLength(1));
      expect(restored.archiveRewards.first.claimed, isTrue);

      // Featured room
      expect(restored.currentFeaturedRoom, isNotNull);
      expect(restored.currentFeaturedRoom!.roomId, 'room_01');
      expect(restored.currentFeaturedRoom!.rewardMultiplier, 1.5);

      // Personal bests
      expect(restored.personalBests.containsKey('room_01'), isTrue);
      expect(restored.personalBests['room_01']!.bestPaceSeconds, 45);
      expect(restored.personalBests['room_01']!.bestCombo, 30);
      expect(
          restored.personalBests['room_01']!.milestoneTimings['half'], 20);
      expect(
          restored.personalBests['room_01']!.recordDate,
          DateTime.utc(2024, 1, 15));

      // Multi-room secrets
      expect(restored.multiRoomSecrets, hasLength(1));
      expect(restored.multiRoomSecrets.first.id, 'mrs_1');
      expect(restored.multiRoomSecrets.first.clues, hasLength(1));

      // Active contracts
      expect(restored.activeContracts, hasLength(1));
      expect(restored.activeContracts.first.id, 'ct_1');

      // Completed contracts
      expect(restored.completedContracts, isEmpty);

      // Cosmetic rewards
      expect(restored.cosmeticRewards, hasLength(1));
      expect(restored.cosmeticRewards.first.unlocked, isTrue);

      // Community stats
      expect(restored.communityStats, isNotNull);
      expect(
          restored.communityStats!.roomCompletionPercentages['room_01'],
          75.5);
      expect(restored.communityStats!.globalAnomalyTotal, 42);
    });

    test('empty defaults work with fromJson({})', () {
      final state = PostCoreState.fromJson({});

      expect(state.roomMastery, isEmpty);
      expect(state.guideState.currentMood, GuideMood.calm);
      expect(state.guideState.trustLevel, 1);
      expect(state.relicSetProgress, isEmpty);
      expect(state.pendingConsequences, isEmpty);
      expect(state.resolvedConsequences, isEmpty);
      expect(state.revisitUnlocks, isEmpty);
      expect(state.archiveRewards, isEmpty);
      expect(state.currentFeaturedRoom, isNull);
      expect(state.personalBests, isEmpty);
      expect(state.multiRoomSecrets, isEmpty);
      expect(state.activeContracts, isEmpty);
      expect(state.completedContracts, isEmpty);
      expect(state.cosmeticRewards, isEmpty);
      expect(state.communityStats, isNull);
    });
  });

  // ─── 23–37. PostCoreService tests ───────────────────────────────────

  group('PostCoreService', () {
    test('initialization loads sample config without crashing', () {
      final service = PostCoreService(configJson: _buildSampleConfig());
      expect(service, isNotNull);
    });

    test('masteryGoalsForRoom returns 7 goals for room_01', () {
      final service = PostCoreService(configJson: _buildSampleConfig());
      final goals = service.masteryGoalsForRoom('room_01');
      expect(goals.length, 7);
      // Each goal type should be present.
      final types = goals.map((g) => g.type).toSet();
      expect(types, containsAll(MasteryGoalType.values));
    });

    test('computeMasteryRank returns correct ranks', () {
      final service = PostCoreService(configJson: _buildSampleConfig());
      expect(service.computeMasteryRank(0), 'bronze');
      expect(service.computeMasteryRank(1), 'bronze');
      expect(service.computeMasteryRank(2), 'silver');
      expect(service.computeMasteryRank(3), 'silver');
      expect(service.computeMasteryRank(4), 'gold');
      expect(service.computeMasteryRank(5), 'gold');
      expect(service.computeMasteryRank(6), 'platinum');
      expect(service.computeMasteryRank(7), 'diamond');
      expect(service.computeMasteryRank(10), 'diamond');
    });

    test('updateGuideMood changes mood based on events', () {
      final service = PostCoreService(configJson: _buildSampleConfig());
      const initial = GuideState();

      // Known event — recklessPlay → suspicious, trust -1.
      final afterReckless =
          service.updateGuideMood(initial, event: 'recklessPlay');
      expect(afterReckless.currentMood, GuideMood.suspicious);
      expect(afterReckless.trustLevel, 0); // 1 + (-1) clamped to 0
      expect(afterReckless.behaviorCounters['recklessPlay'], 1);

      // Known event — followGuide → proud, trust +1.
      final afterFollow =
          service.updateGuideMood(initial, event: 'followGuide');
      expect(afterFollow.currentMood, GuideMood.proud);
      expect(afterFollow.trustLevel, 2); // 1 + 1 = 2

      // Unknown event — state unchanged.
      final unchanged =
          service.updateGuideMood(initial, event: 'unknownEvent');
      expect(unchanged.currentMood, GuideMood.calm);
      expect(unchanged.trustLevel, 1);
    });

    test('addConsequence adds to pendingConsequences', () {
      final service = PostCoreService(configJson: _buildSampleConfig());
      const state = PostCoreState();

      const consequence = DelayedConsequence(
        id: 'dc_test',
        sourceEventId: 'evt_1',
        sourceRoomId: 'room_01',
        description: 'A delayed consequence.',
        timing: ConsequenceTiming.futureRoom,
        targetRoomId: 'room_02',
        outcomeType: 'bonus',
        outcomeDescription: 'Extra coins.',
      );

      final newState = service.addConsequence(state, consequence);
      expect(newState.pendingConsequences, hasLength(1));
      expect(newState.pendingConsequences.first.id, 'dc_test');
    });

    test('resolveConsequence moves from pending to resolved', () {
      final service = PostCoreService(configJson: _buildSampleConfig());
      const consequence = DelayedConsequence(
        id: 'dc_test',
        sourceEventId: 'evt_1',
        sourceRoomId: 'room_01',
        description: 'A delayed consequence.',
        timing: ConsequenceTiming.futureRoom,
        outcomeType: 'bonus',
        outcomeDescription: 'Extra coins.',
      );

      const state = PostCoreState(pendingConsequences: [consequence]);
      final newState = service.resolveConsequence(state, 'dc_test');

      expect(newState.pendingConsequences, isEmpty);
      expect(newState.resolvedConsequences, hasLength(1));
      expect(newState.resolvedConsequences.first.id, 'dc_test');
      expect(newState.resolvedConsequences.first.resolved, isTrue);
    });

    test('pendingForRoom filters by room', () {
      final service = PostCoreService(configJson: _buildSampleConfig());
      const state = PostCoreState(
        pendingConsequences: [
          DelayedConsequence(
            id: 'dc_a',
            sourceEventId: 'evt_1',
            sourceRoomId: 'room_01',
            description: 'For room_01.',
            timing: ConsequenceTiming.laterInRoom,
            outcomeType: 'bonus',
            outcomeDescription: 'Coins.',
          ),
          DelayedConsequence(
            id: 'dc_b',
            sourceEventId: 'evt_2',
            sourceRoomId: 'room_01',
            description: 'Targets room_02.',
            timing: ConsequenceTiming.futureRoom,
            targetRoomId: 'room_02',
            outcomeType: 'penalty',
            outcomeDescription: 'Slow.',
          ),
          DelayedConsequence(
            id: 'dc_c',
            sourceEventId: 'evt_3',
            sourceRoomId: 'room_02',
            description: 'From room_02.',
            timing: ConsequenceTiming.laterInRoom,
            outcomeType: 'bonus',
            outcomeDescription: 'Coins.',
          ),
        ],
      );

      final room01 = service.pendingForRoom(state, 'room_01');
      // dc_a: no targetRoomId, sourceRoomId == room_01 → match
      // dc_b: targetRoomId == room_02 → no match
      // dc_c: no targetRoomId, sourceRoomId == room_02 → no match
      expect(room01, hasLength(1));
      expect(room01.first.id, 'dc_a');

      final room02 = service.pendingForRoom(state, 'room_02');
      // dc_a: no target, source room_01 → no match
      // dc_b: targetRoomId == room_02 → match
      // dc_c: no target, source room_02 → match
      expect(room02, hasLength(2));
    });

    test('checkArchiveRewards claims rewards at thresholds', () {
      final service = PostCoreService(configJson: _buildSampleConfig());
      const state = PostCoreState();

      // discoveredCount 7 → ar_lore_5 (req 5) claimed, ar_lore_10 (req 10) not.
      final newState = service.checkArchiveRewards(
        state,
        section: 'lore',
        discoveredCount: 7,
      );

      expect(newState.archiveRewards, hasLength(2));
      final claimed =
          newState.archiveRewards.where((r) => r.claimed).toList();
      expect(claimed, hasLength(1));
      expect(claimed.first.id, 'ar_lore_5');

      // discoveredCount 10 → both claimed.
      final bothClaimed = service.checkArchiveRewards(
        newState,
        section: 'lore',
        discoveredCount: 10,
      );
      final allClaimed =
          bothClaimed.archiveRewards.where((r) => r.claimed).toList();
      expect(allClaimed, hasLength(2));
    });

    test('updatePersonalBest stores and updates record', () {
      final service = PostCoreService(configJson: _buildSampleConfig());
      const state = PostCoreState();

      // First record — should be stored.
      final record = PersonalBestRecord(
        roomId: 'room_01',
        bestPaceSeconds: 60,
        bestCombo: 20,
        bestEventChain: 3,
        recordDate: DateTime.utc(2024, 1, 15),
      );
      final afterFirst = service.updatePersonalBest(state, record);
      expect(afterFirst.personalBests.containsKey('room_01'), isTrue);
      expect(afterFirst.personalBests['room_01']!.bestPaceSeconds, 60);
      expect(afterFirst.personalBests['room_01']!.bestCombo, 20);

      // Better pace — should update pace, keep combo.
      final betterPace = PersonalBestRecord(
        roomId: 'room_01',
        bestPaceSeconds: 40,
        bestCombo: 15,
        bestEventChain: 2,
        recordDate: DateTime.utc(2024, 2, 1),
      );
      final afterBetter = service.updatePersonalBest(afterFirst, betterPace);
      expect(afterBetter.personalBests['room_01']!.bestPaceSeconds, 40);
      expect(afterBetter.personalBests['room_01']!.bestCombo, 20); // kept

      // Worse record — no change.
      final worse = PersonalBestRecord(
        roomId: 'room_01',
        bestPaceSeconds: 70,
        bestCombo: 10,
        recordDate: DateTime.utc(2024, 3, 1),
      );
      final afterWorse = service.updatePersonalBest(afterBetter, worse);
      expect(afterWorse.personalBests['room_01']!.bestPaceSeconds, 40);
      expect(afterWorse.personalBests['room_01']!.bestCombo, 20);
    });

    test('discoverClue marks clue as discovered', () {
      final service = PostCoreService(configJson: _buildSampleConfig());
      const state = PostCoreState();

      // Discover first clue — secret initialised from definitions.
      final afterFirst =
          service.discoverClue(state, 'mrs_hidden', 'clue_01');
      expect(afterFirst.multiRoomSecrets, hasLength(1));
      expect(afterFirst.multiRoomSecrets.first.id, 'mrs_hidden');

      final clues = afterFirst.multiRoomSecrets.first.clues;
      expect(clues, hasLength(2));
      expect(clues[0].discovered, isTrue);
      expect(clues[1].discovered, isFalse);

      // Discover second clue.
      final afterSecond =
          service.discoverClue(afterFirst, 'mrs_hidden', 'clue_02');
      final updatedClues = afterSecond.multiRoomSecrets.first.clues;
      expect(updatedClues[0].discovered, isTrue);
      expect(updatedClues[1].discovered, isTrue);

      // Re-discover same clue — no change.
      final afterDuplicate =
          service.discoverClue(afterSecond, 'mrs_hidden', 'clue_02');
      expect(afterDuplicate.multiRoomSecrets, hasLength(1));
    });

    test('updateContractProgress updates progress and checks completion',
        () {
      final service = PostCoreService(configJson: _buildSampleConfig());

      // Seed state with an active contract.
      const state = PostCoreState(
        activeContracts: [
          MasteryContract(
            id: 'ct_combo',
            roomId: 'room_01',
            title: 'Combo Master',
            description: 'Reach combo 50.',
            metric: 'combo',
            targetValue: 50,
            currentValue: 0,
            rewardType: 'cosmetic',
            rewardId: 'reward_combo',
          ),
        ],
      );

      // Partial progress — stays active.
      final partial =
          service.updateContractProgress(state, 'ct_combo', 25);
      expect(partial.activeContracts, hasLength(1));
      expect(partial.activeContracts.first.currentValue, 25);
      expect(partial.completedContracts, isEmpty);

      // Meets target — moves to completed.
      final completed =
          service.updateContractProgress(partial, 'ct_combo', 50);
      expect(completed.activeContracts, isEmpty);
      expect(completed.completedContracts, hasLength(1));
      expect(completed.completedContracts.first.id, 'ct_combo');
      expect(completed.completedContracts.first.completed, isTrue);
      expect(completed.completedContracts.first.currentValue, 50);
    });

    test('unlockCosmetic marks as unlocked', () {
      final service = PostCoreService(configJson: _buildSampleConfig());
      const state = PostCoreState();

      // Unlock a defined cosmetic.
      final afterUnlock = service.unlockCosmetic(state, 'cos_badge');
      expect(afterUnlock.cosmeticRewards, hasLength(1));
      expect(afterUnlock.cosmeticRewards.first.id, 'cos_badge');
      expect(afterUnlock.cosmeticRewards.first.unlocked, isTrue);

      // Re-unlock — no change.
      final afterDuplicate =
          service.unlockCosmetic(afterUnlock, 'cos_badge');
      expect(afterDuplicate.cosmeticRewards, hasLength(1));

      // Unknown id — no change.
      final afterUnknown =
          service.unlockCosmetic(state, 'cos_nonexistent');
      expect(afterUnknown.cosmeticRewards, isEmpty);
    });

    test('generateSummary produces non-empty report', () {
      final service = PostCoreService(configJson: _buildSampleConfig());

      final state = PostCoreState(
        personalBests: {
          'room_01': PersonalBestRecord(
            roomId: 'room_01',
            bestPaceSeconds: 45,
            bestCombo: 30,
            recordDate: DateTime.utc(2024, 1, 15),
          ),
        },
        revisitUnlocks: const {
          'room_01': [
            RevisitUnlock(
              id: 'rv_1',
              roomId: 'room_01',
              title: 'Hidden Path',
              description: 'A path.',
              triggerCondition: 'room_02_complete',
              unlockType: 'path',
              unlocked: true,
              discovered: true,
            ),
          ],
        },
      );

      final report = service.generateSummary('room_01', state);
      expect(report.roomId, 'room_01');
      expect(report.generatedAt, isNotNull);
      expect(report.items, isNotEmpty);
      expect(report.totalNewEntries, greaterThan(0));
    });

    test('handles empty config without crashing', () {
      final service = PostCoreService(configJson: const {});
      expect(service, isNotNull);
      expect(service.masteryGoalsForRoom('room_01'), isEmpty);
      expect(service.relicSets, isEmpty);
      expect(service.multiRoomSecrets, isEmpty);
      expect(service.contractsForRoom('room_01'), isEmpty);
      expect(service.allCosmetics, isEmpty);
    });

    test('handles malformed entries gracefully', () {
      final service = PostCoreService(configJson: {
        'masteryGoals': [
          {'name': 'Missing id field'},
          42,
          {
            'id': 'mg_valid',
            'roomId': 'room_01',
            'type': 'fastestClear',
            'title': 'Valid',
            'description': 'Valid goal.',
            'targetValue': 10,
            'rewardType': 'cosmetic',
            'rewardId': 'reward_v',
          },
        ],
        'relicSets': 'not_a_list',
        'contracts': [
          'not_a_map',
          {'missing': 'id'},
        ],
        'cosmeticRewards': [
          {'id': 'cos_ok', 'name': 'OK', 'description': 'Fine.',
           'type': 'roomBadge'},
          {'bad_entry': true},
        ],
      });

      // Only valid entries are parsed.
      expect(service.masteryGoalsForRoom('room_01'), hasLength(1));
      expect(service.relicSets, isEmpty);
      expect(service.contractsForRoom('any'), isEmpty);
      expect(service.allCosmetics, hasLength(1));
    });
  });
}
