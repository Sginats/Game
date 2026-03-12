import '../../../lib/core/math/game_number.dart';
import '../../../lib/domain/models/achievement.dart';
import '../../../lib/domain/models/game_state.dart';
import '../../../lib/domain/models/generator.dart';
import '../../../lib/domain/systems/achievement_system.dart';

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

  // --- Setup ---
  final achievements = [
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
  ];

  final production = GameNumber.fromDouble(10);

  // --- No achievements met initially ---
  final state = GameState.initial();
  final initial = AchievementSystem.checkAchievements(state, achievements, production);
  expectTrue(initial.isEmpty, 'No achievements at start');

  // --- Total taps achievement ---
  final tappedState = state.copyWith(totalTaps: 15);
  final tapped = AchievementSystem.checkAchievements(tappedState, achievements, production);
  expectTrue(tapped.contains('ach_taps'), 'Taps achievement unlocked');
  expectTrue(!tapped.contains('ach_coins'), 'Coins achievement not unlocked');

  // --- Total coins achievement ---
  final richState = state.copyWith(
    totalCoinsEarned: GameNumber.fromDouble(200),
    totalTaps: 15,
  );
  final rich = AchievementSystem.checkAchievements(richState, achievements, production);
  expectTrue(rich.contains('ach_taps'), 'Taps achievement unlocked with rich state');
  expectTrue(rich.contains('ach_coins'), 'Coins achievement unlocked');

  // --- Generator level achievement ---
  final genState = state.copyWith(
    generators: {
      'gen_1': GeneratorState(definitionId: 'gen_1', level: 5),
    },
  );
  final gen = AchievementSystem.checkAchievements(genState, achievements, production);
  expectTrue(gen.contains('ach_gen'), 'Generator achievement unlocked');

  // --- Production rate achievement ---
  final highProd = GameNumber.fromDouble(100);
  final prod = AchievementSystem.checkAchievements(state, achievements, highProd);
  expectTrue(prod.contains('ach_prod'), 'Production achievement unlocked');

  // --- Already unlocked achievements are not re-reported ---
  final unlockedState = state.copyWith(
    totalTaps: 15,
    unlockedAchievements: {'ach_taps'},
  );
  final already = AchievementSystem.checkAchievements(unlockedState, achievements, production);
  expectTrue(!already.contains('ach_taps'), 'Already unlocked not re-reported');

  // --- Apply achievements ---
  final applied = AchievementSystem.applyAchievements(state, {'ach_taps', 'ach_coins'});
  expectTrue(applied.unlockedAchievements.length == 2, 'Achievements applied');
  expectTrue(applied.unlockedAchievements.contains('ach_taps'), 'ach_taps in set');

  // --- Apply empty set returns same state ---
  final unchanged = AchievementSystem.applyAchievements(state, {});
  expectTrue(identical(unchanged, state), 'Empty apply returns same state');

  print('\n$passed passed, $failed failed');
  if (failed > 0) throw Exception('Tests failed');
}
