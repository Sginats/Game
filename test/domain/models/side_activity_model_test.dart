import 'package:ai_evolution/domain/models/side_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SideActivityType has expected values', () {
    expect(SideActivityType.values.length, 16);
    expect(SideActivityType.calibrationConsole.name, 'calibrationConsole');
    expect(SideActivityType.roomRestore.name, 'roomRestore');
  });

  test('SideActivityReward serializes and deserializes', () {
    const reward = SideActivityReward(
      type: 'currency',
      value: 50.0,
      description: 'Earn 50 scrap.',
      rarity: 'rare',
    );

    final json = reward.toJson();
    final restored = SideActivityReward.fromJson(json);

    expect(restored.type, 'currency');
    expect(restored.value, 50.0);
    expect(restored.description, 'Earn 50 scrap.');
    expect(restored.rarity, 'rare');
  });

  test('SideActivityDefinition serializes with all fields', () {
    const def = SideActivityDefinition(
      id: 'sa_calibrate_01',
      roomId: 'room_01',
      name: 'Calibration Console',
      description: 'Calibrate the machine for bonus output.',
      type: SideActivityType.calibrationConsole,
      difficultyTier: 2,
      durationSeconds: 45.0,
      rewards: [
        SideActivityReward(
          type: 'currency',
          value: 25.0,
          description: 'Bonus scrap.',
        ),
      ],
      repeatableDaily: true,
      repeatableWeekly: false,
      secretUnlockId: 'secret_calibration',
      upgradeUnlockId: null,
      companionDropId: 'comp_calibration_bot',
    );

    final json = def.toJson();
    final restored = SideActivityDefinition.fromJson(json);

    expect(restored.id, 'sa_calibrate_01');
    expect(restored.roomId, 'room_01');
    expect(restored.type, SideActivityType.calibrationConsole);
    expect(restored.difficultyTier, 2);
    expect(restored.durationSeconds, 45.0);
    expect(restored.rewards.length, 1);
    expect(restored.repeatableDaily, isTrue);
    expect(restored.repeatableWeekly, isFalse);
    expect(restored.secretUnlockId, 'secret_calibration');
    expect(restored.companionDropId, 'comp_calibration_bot');
  });

  test('SideActivityDefinition defaults work', () {
    const def = SideActivityDefinition(
      id: 'sa_min',
      roomId: 'room_01',
      name: 'Minimal',
      description: 'Test.',
      type: SideActivityType.signalScan,
    );

    expect(def.difficultyTier, 1);
    expect(def.durationSeconds, 30.0);
    expect(def.rewards, isEmpty);
    expect(def.repeatableDaily, isFalse);
    expect(def.repeatableWeekly, isFalse);
    expect(def.secretUnlockId, isNull);
    expect(def.upgradeUnlockId, isNull);
    expect(def.companionDropId, isNull);
  });

  test('SideActivityProgress serializes and deserializes', () {
    final completed = DateTime(2026, 3, 10);
    final progress = SideActivityProgress(
      activityId: 'sa_calibrate_01',
      completionCount: 5,
      bestScore: 95.0,
      lastCompletedAt: completed,
      dailyCompletions: 2,
      weeklyCompletions: 4,
      unlocked: true,
    );

    final json = progress.toJson();
    final restored = SideActivityProgress.fromJson(json);

    expect(restored.activityId, 'sa_calibrate_01');
    expect(restored.completionCount, 5);
    expect(restored.bestScore, 95.0);
    expect(restored.lastCompletedAt, isNotNull);
    expect(restored.dailyCompletions, 2);
    expect(restored.weeklyCompletions, 4);
    expect(restored.unlocked, isTrue);
  });

  test('SideActivityProgress defaults are initial values', () {
    const progress = SideActivityProgress(activityId: 'sa_test');
    expect(progress.completionCount, 0);
    expect(progress.bestScore, 0.0);
    expect(progress.lastCompletedAt, isNull);
    expect(progress.dailyCompletions, 0);
    expect(progress.weeklyCompletions, 0);
    expect(progress.unlocked, isFalse);
  });

  test('SideActivityProgress copyWith works', () {
    const progress = SideActivityProgress(
      activityId: 'sa_1',
      completionCount: 3,
      bestScore: 80.0,
    );
    final updated = progress.copyWith(completionCount: 4, bestScore: 90.0);
    expect(updated.completionCount, 4);
    expect(updated.bestScore, 90.0);
    expect(updated.activityId, 'sa_1');
    expect(progress.completionCount, 3);
  });

  test('SideActivityState serializes and deserializes', () {
    const state = SideActivityState(
      progresses: {
        'sa_1': SideActivityProgress(
          activityId: 'sa_1',
          completionCount: 2,
          unlocked: true,
        ),
      },
      totalActivitiesCompleted: 10,
      ticketsAvailable: 3,
    );

    final json = state.toJson();
    final restored = SideActivityState.fromJson(json);

    expect(restored.progresses.length, 1);
    expect(restored.progresses['sa_1']!.completionCount, 2);
    expect(restored.progresses['sa_1']!.unlocked, isTrue);
    expect(restored.totalActivitiesCompleted, 10);
    expect(restored.ticketsAvailable, 3);
  });

  test('SideActivityState defaults are empty', () {
    const state = SideActivityState();
    expect(state.progresses, isEmpty);
    expect(state.totalActivitiesCompleted, 0);
    expect(state.ticketsAvailable, 0);
  });

  test('SideActivityState copyWith works', () {
    const state = SideActivityState(ticketsAvailable: 5);
    final updated = state.copyWith(totalActivitiesCompleted: 20);
    expect(updated.totalActivitiesCompleted, 20);
    expect(updated.ticketsAvailable, 5);
  });
}
