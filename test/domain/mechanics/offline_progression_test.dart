import '../../../lib/core/math/game_number.dart';
import '../../../lib/domain/models/game_state.dart';
import '../../../lib/domain/models/generator.dart';
import '../../../lib/domain/mechanics/offline_progression.dart';

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

  // --- calculateOfflineEarnings ---
  final production = GameNumber.fromDouble(10); // 10 coins/sec
  const maxHours = 8;

  // Normal case: 100 seconds offline
  final earnings = OfflineProgression.calculateOfflineEarnings(production, 100, maxHours);
  expectTrue((earnings.toDouble() - 1000).abs() < 0.1, 'offline 100s = 1000 coins');

  // Zero production
  final zeroEarn = OfflineProgression.calculateOfflineEarnings(const GameNumber.zero(), 100, maxHours);
  expectTrue(zeroEarn.isZero, 'zero production = zero earnings');

  // Zero time
  final zeroTime = OfflineProgression.calculateOfflineEarnings(production, 0, maxHours);
  expectTrue(zeroTime.isZero, 'zero time = zero earnings');

  // Capped at 8 hours = 28800 seconds
  final capped = OfflineProgression.calculateOfflineEarnings(production, 100000, maxHours);
  final maxExpected = 10.0 * 28800;
  expectTrue((capped.toDouble() - maxExpected).abs() < 1.0, 'earnings capped at 8h');

  // --- applyOfflineEarnings ---
  final genDef = GeneratorDefinition(
    id: 'gen_1',
    name: 'Test',
    description: 'Test',
    eraId: 'era_1',
    baseCost: GameNumber.fromDouble(10),
    costGrowthRate: 1.15,
    baseProduction: GameNumber.fromDouble(5),
  );

  final baseTime = DateTime(2026, 1, 1, 0, 0, 0);
  final state = GameState(
    coins: GameNumber.fromDouble(100),
    totalCoinsEarned: GameNumber.fromDouble(100),
    tapMultiplier: GameNumber.fromDouble(1),
    productionMultiplier: GameNumber.fromDouble(1),
    generators: {
      'gen_1': GeneratorState(definitionId: 'gen_1', level: 2),
    },
    upgrades: const {},
    unlockedEras: const {'era_1'},
    lastSaveTime: baseTime,
  );

  // Come back 60 seconds later
  final currentTime = baseTime.add(const Duration(seconds: 60));
  final newState = OfflineProgression.applyOfflineEarnings(
    state,
    {'gen_1': genDef},
    currentTime,
    maxHours,
  );

  // Production = 5 * 2 * 1 * 1 = 10/sec, 60 sec = 600 coins
  final expectedCoins = 100 + 600.0;
  expectTrue(
    (newState.coins.toDouble() - expectedCoins).abs() < 1.0,
    'applyOfflineEarnings: coins updated',
  );

  print('\n$passed passed, $failed failed');
  if (failed > 0) throw Exception('Tests failed');
}
