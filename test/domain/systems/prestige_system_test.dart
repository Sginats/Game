import '../../../lib/core/math/game_number.dart';
import '../../../lib/domain/models/game_state.dart';
import '../../../lib/domain/systems/prestige_system.dart';

void main() {
  var passed = 0;
  var failed = 0;

  void expectTrue(bool condition, String name) {
    if (condition) {
      passed++;
    } else {
      print('FAIL: $name');
      failed++;
    }
  }

  // --- Cannot prestige without enough coins ---
  final state = GameState.initial();
  expectTrue(!PrestigeSystem.canPrestige(state), 'Cannot prestige at start');

  final poorState = state.copyWith(
    totalCoinsEarned: GameNumber.fromDouble(999999),
  );
  expectTrue(!PrestigeSystem.canPrestige(poorState), 'Cannot prestige below threshold');

  // --- Can prestige at threshold ---
  final richState = state.copyWith(
    totalCoinsEarned: GameNumber.fromDouble(1e6),
  );
  expectTrue(PrestigeSystem.canPrestige(richState), 'Can prestige at 1M');

  // --- Prestige multiplier calculation ---
  final mult1m = PrestigeSystem.calculatePrestigeMultiplier(
    GameNumber.fromDouble(1e6),
  );
  // log10(1e6) = 6, bonus = (6-5)*0.1 = 0.1, mult = 1.1
  expectTrue((mult1m.toDouble() - 1.1).abs() < 0.05, 'Prestige mult at 1M ≈ 1.1');

  final mult1b = PrestigeSystem.calculatePrestigeMultiplier(
    GameNumber.fromDouble(1e9),
  );
  // log10(1e9) = 9, bonus = (9-5)*0.1 = 0.4, mult = 1.4
  expectTrue((mult1b.toDouble() - 1.4).abs() < 0.05, 'Prestige mult at 1B ≈ 1.4');

  // --- Below threshold gives 1x ---
  final multLow = PrestigeSystem.calculatePrestigeMultiplier(
    GameNumber.fromDouble(100),
  );
  expectTrue((multLow.toDouble() - 1.0).abs() < 0.01, 'Below threshold = 1x');

  // --- Perform prestige ---
  final prePrestige = state.copyWith(
    coins: GameNumber.fromDouble(5000000),
    totalCoinsEarned: GameNumber.fromDouble(5000000),
    totalTaps: 500,
    generators: {},
    tutorialComplete: true,
    unlockedAchievements: {'ach_1'},
  );
  final afterPrestige = PrestigeSystem.performPrestige(prePrestige);

  expectTrue(afterPrestige.coins.isZero, 'Prestige resets coins');
  expectTrue(afterPrestige.totalCoinsEarned.isZero, 'Prestige resets totalCoinsEarned');
  expectTrue(afterPrestige.totalTaps == 0, 'Prestige resets totalTaps');
  expectTrue(afterPrestige.generators.isEmpty, 'Prestige resets generators');
  expectTrue(afterPrestige.prestigeCount == 1, 'Prestige count incremented');
  expectTrue(afterPrestige.prestigeMultiplier.toDouble() > 1.0, 'Prestige multiplier > 1');
  expectTrue(afterPrestige.tutorialComplete, 'Prestige keeps tutorialComplete');
  expectTrue(afterPrestige.unlockedAchievements.contains('ach_1'), 'Prestige keeps achievements');

  // --- Cannot prestige if below threshold ---
  final noPrestige = PrestigeSystem.performPrestige(state);
  expectTrue(identical(noPrestige, state), 'No prestige below threshold');

  print('\n$passed passed, $failed failed');
  if (failed > 0) throw Exception('Tests failed');
}
