import 'package:ai_evolution/application/services/side_activity_service.dart';
import 'package:ai_evolution/domain/models/side_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SideActivityService service;

  setUp(() {
    service = SideActivityService(jsonList: [
      {
        'id': 'sa_salvage_01',
        'roomId': 'room_01',
        'name': 'Scrap Salvage',
        'description': 'Dig through junk.',
        'type': 'salvageExcavation',
        'difficultyTier': 1,
        'durationSeconds': 20.0,
        'rewards': [
          {
            'type': 'currency',
            'value': 15.0,
            'description': 'Bonus scrap',
            'rarity': 'common',
          }
        ],
        'repeatableDaily': true,
        'repeatableWeekly': false,
      },
      {
        'id': 'sa_hack_06',
        'roomId': 'room_06',
        'name': 'Server Hack',
        'description': 'Hack the server.',
        'type': 'terminalHack',
        'difficultyTier': 3,
        'durationSeconds': 45.0,
        'rewards': [],
        'repeatableDaily': false,
        'repeatableWeekly': true,
      },
    ]);
  });

  test('loads definitions from JSON', () {
    expect(service.totalDefinitions, 2);
  });

  test('getDefinition returns correct activity', () {
    final def = service.getDefinition('sa_salvage_01');
    expect(def, isNotNull);
    expect(def!.name, 'Scrap Salvage');
    expect(def.type, SideActivityType.salvageExcavation);
    expect(def.difficultyTier, 1);
  });

  test('getDefinition returns null for unknown id', () {
    expect(service.getDefinition('unknown'), isNull);
  });

  test('getDefinitionsForRoom filters correctly', () {
    final room01 = service.getDefinitionsForRoom('room_01');
    expect(room01.length, 1);
    expect(room01.first.id, 'sa_salvage_01');

    final room06 = service.getDefinitionsForRoom('room_06');
    expect(room06.length, 1);
    expect(room06.first.id, 'sa_hack_06');

    final empty = service.getDefinitionsForRoom('room_99');
    expect(empty, isEmpty);
  });

  test('allDefinitions returns all loaded', () {
    expect(service.allDefinitions.length, 2);
  });

  test('getProgress returns progress from state', () {
    const state = SideActivityState(
      progresses: {
        'sa_salvage_01': SideActivityProgress(
          activityId: 'sa_salvage_01',
          completionCount: 3,
          unlocked: true,
        ),
      },
    );

    final progress = service.getProgress(state, 'sa_salvage_01');
    expect(progress, isNotNull);
    expect(progress!.completionCount, 3);
    expect(service.getProgress(state, 'sa_hack_06'), isNull);
  });

  test('isUnlocked checks progress state', () {
    const state = SideActivityState(
      progresses: {
        'sa_salvage_01': SideActivityProgress(
          activityId: 'sa_salvage_01',
          unlocked: true,
        ),
        'sa_hack_06': SideActivityProgress(
          activityId: 'sa_hack_06',
          unlocked: false,
        ),
      },
    );

    expect(service.isUnlocked(state, 'sa_salvage_01'), isTrue);
    expect(service.isUnlocked(state, 'sa_hack_06'), isFalse);
    expect(service.isUnlocked(state, 'unknown'), isFalse);
  });

  test('canRepeatDaily checks daily limit', () {
    final def = service.getDefinition('sa_salvage_01')!;

    const fresh = SideActivityProgress(activityId: 'sa_salvage_01');
    expect(service.canRepeatDaily(def, fresh), isTrue);

    const used = SideActivityProgress(
      activityId: 'sa_salvage_01',
      dailyCompletions: 1,
    );
    expect(service.canRepeatDaily(def, used), isFalse);

    // Non-repeatable daily
    final hackDef = service.getDefinition('sa_hack_06')!;
    expect(service.canRepeatDaily(hackDef, null), isFalse);
  });

  test('canRepeatWeekly checks weekly limit', () {
    final hackDef = service.getDefinition('sa_hack_06')!;

    const fresh = SideActivityProgress(activityId: 'sa_hack_06');
    expect(service.canRepeatWeekly(hackDef, fresh), isTrue);

    const used = SideActivityProgress(
      activityId: 'sa_hack_06',
      weeklyCompletions: 1,
    );
    expect(service.canRepeatWeekly(hackDef, used), isFalse);

    // Non-repeatable weekly
    final salvageDef = service.getDefinition('sa_salvage_01')!;
    expect(service.canRepeatWeekly(salvageDef, null), isFalse);
  });
}
