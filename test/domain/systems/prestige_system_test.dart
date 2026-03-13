import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/domain/models/game_state.dart';
import 'package:ai_evolution/domain/systems/prestige_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canPrestige and multiplier logic work', () {
    final state = GameState.initial();
    expect(PrestigeSystem.canPrestige(state), isFalse);
    expect(
      PrestigeSystem.canPrestige(
        state.copyWith(totalCoinsEarned: GameNumber.fromDouble(999999)),
      ),
      isFalse,
    );
    expect(
      PrestigeSystem.canPrestige(
        state.copyWith(totalCoinsEarned: GameNumber.fromDouble(1e6)),
      ),
      isTrue,
    );
    expect(
      PrestigeSystem.calculatePrestigeMultiplier(GameNumber.fromDouble(1e6))
          .toDouble(),
      closeTo(1.1, 0.05),
    );
    expect(
      PrestigeSystem.calculatePrestigeMultiplier(GameNumber.fromDouble(1e9))
          .toDouble(),
      closeTo(1.4, 0.05),
    );
    expect(
      PrestigeSystem.calculatePrestigeMultiplier(GameNumber.fromDouble(100))
          .toDouble(),
      closeTo(1.0, 0.01),
    );
  });

  test('performPrestige resets run state and preserves allowed fields', () {
    final base = GameState.initial();
    final prePrestige = base.copyWith(
      coins: GameNumber.fromDouble(5000000),
      totalCoinsEarned: GameNumber.fromDouble(5000000),
      totalTaps: 500,
      generators: {},
      tutorialComplete: true,
      unlockedAchievements: {'ach_1'},
    );
    final afterPrestige = PrestigeSystem.performPrestige(prePrestige);

    expect(afterPrestige.coins.isZero, isTrue);
    expect(afterPrestige.totalCoinsEarned.isZero, isTrue);
    expect(afterPrestige.totalTaps, 0);
    expect(afterPrestige.generators, isEmpty);
    expect(afterPrestige.prestigeCount, 1);
    expect(afterPrestige.prestigeMultiplier.toDouble(), greaterThan(1.0));
    expect(afterPrestige.tutorialComplete, isTrue);
    expect(afterPrestige.unlockedAchievements.contains('ach_1'), isTrue);
    expect(PrestigeSystem.performPrestige(base), same(base));
  });
}
