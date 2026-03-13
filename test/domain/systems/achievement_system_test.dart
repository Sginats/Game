import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/domain/models/achievement.dart';
import 'package:ai_evolution/domain/models/game_state.dart';
import 'package:ai_evolution/domain/models/generator.dart';
import 'package:ai_evolution/domain/systems/achievement_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<AchievementDefinition> achievements;

  setUp(() {
    achievements = [
      AchievementDefinition(
        id: 'ach_taps',
        name: 'Tapper',
        description: 'Tap 10 times',
        icon: '👆',
        type: AchievementType.totalTaps,
        threshold: GameNumber.fromInt(10),
      ),
      AchievementDefinition(
        id: 'ach_coins',
        name: 'Rich',
        description: 'Earn 100 coins',
        icon: '💰',
        type: AchievementType.totalCoins,
        threshold: GameNumber.fromInt(100),
      ),
      AchievementDefinition(
        id: 'ach_gen',
        name: 'Builder',
        description: 'Have 5 gen_1',
        icon: '🤖',
        type: AchievementType.generatorLevel,
        threshold: GameNumber.fromInt(5),
        targetId: 'gen_1',
      ),
      AchievementDefinition(
        id: 'ach_prod',
        name: 'Factory',
        description: 'Reach 50/sec',
        icon: '🏭',
        type: AchievementType.productionRate,
        threshold: GameNumber.fromInt(50),
      ),
      AchievementDefinition(
        id: 'ach_combo',
        name: 'Combo King',
        description: 'Reach a 20 combo',
        icon: '🔥',
        type: AchievementType.strongestCombo,
        threshold: GameNumber.fromInt(20),
      ),
    ];
  });

  test('checkAchievements finds eligible achievements', () {
    final baseState = GameState.initial();
    final production = GameNumber.fromDouble(10);
    expect(
      AchievementSystem.checkAchievements(baseState, achievements, production),
      isEmpty,
    );

    final richState = baseState.copyWith(
      totalTaps: 15,
      totalCoinsEarned: GameNumber.fromDouble(200),
    );
    final unlocked =
        AchievementSystem.checkAchievements(richState, achievements, production);
    expect(unlocked, contains('ach_taps'));
    expect(unlocked, contains('ach_coins'));

    final genState = baseState.copyWith(
      generators: {
        'gen_1': GeneratorState(definitionId: 'gen_1', level: 5),
      },
    );
    expect(
      AchievementSystem.checkAchievements(genState, achievements, production),
      contains('ach_gen'),
    );
    expect(
      AchievementSystem.checkAchievements(
        baseState,
        achievements,
        GameNumber.fromDouble(100),
      ),
      contains('ach_prod'),
    );
  });

  test('strongestCombo achievement unlocks when threshold met', () {
    final baseState = GameState.initial();
    final production = GameNumber.fromDouble(0);

    // Below threshold – should not unlock
    final lowComboState = baseState.copyWith(strongestCombo: 10);
    expect(
      AchievementSystem.checkAchievements(
          lowComboState, achievements, production),
      isNot(contains('ach_combo')),
    );

    // At threshold – should unlock
    final atComboState = baseState.copyWith(strongestCombo: 20);
    expect(
      AchievementSystem.checkAchievements(
          atComboState, achievements, production),
      contains('ach_combo'),
    );

    // Above threshold – should also unlock
    final highComboState = baseState.copyWith(strongestCombo: 50);
    expect(
      AchievementSystem.checkAchievements(
          highComboState, achievements, production),
      contains('ach_combo'),
    );

    // Already unlocked – should not appear again
    final alreadyUnlocked = baseState.copyWith(
      strongestCombo: 30,
      unlockedAchievements: {'ach_combo'},
    );
    expect(
      AchievementSystem.checkAchievements(
          alreadyUnlocked, achievements, production),
      isNot(contains('ach_combo')),
    );
  });

  test('applyAchievements updates unlocked set', () {
    final state = GameState.initial();
    final applied = AchievementSystem.applyAchievements(
      state,
      {'ach_taps', 'ach_coins'},
    );
    expect(applied.unlockedAchievements.length, 2);
    expect(applied.unlockedAchievements.contains('ach_taps'), isTrue);
    expect(AchievementSystem.applyAchievements(state, {}), same(state));
  });
}
