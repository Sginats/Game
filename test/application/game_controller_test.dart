import '../../lib/core/math/game_number.dart';
import '../../lib/core/time/time_provider.dart';
import '../../lib/domain/models/game_state.dart';
import '../../lib/domain/models/generator.dart';
import '../../lib/domain/models/upgrade.dart';
import '../../lib/application/controllers/game_controller.dart';
import '../../lib/application/services/config_service.dart';

/// Test time provider for deterministic testing.
class FixedTimeProvider implements TimeProvider {
  DateTime _now;
  FixedTimeProvider(this._now);

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
}

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

  final genDef = GeneratorDefinition(
    id: 'gen_1',
    name: 'Test Gen',
    description: 'Test',
    eraId: 'era_1',
    baseCost: GameNumber.fromDouble(10),
    costGrowthRate: 1.15,
    baseProduction: GameNumber.fromDouble(5),
  );

  final tapUpgrade = UpgradeDefinition(
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

  final config = ConfigService(
    baseTapValue: GameNumber.fromDouble(1),
    baseTapMultiplier: GameNumber.fromDouble(1),
    generators: {'gen_1': genDef},
    upgrades: {'upg_tap': tapUpgrade},
    eras: const [],
    maxOfflineHours: 8,
    autoSaveIntervalSeconds: 30,
    tickRateMs: 100,
  );

  final time = FixedTimeProvider(DateTime(2026, 1, 1));

  // --- Initial state ---
  final controller = GameController(config: config, timeProvider: time);
  expectTrue(controller.state.coins.isZero, 'initial coins = 0');

  // --- Tap ---
  controller.tap();
  expectTrue(
    (controller.state.coins.toDouble() - 1).abs() < 0.01,
    'tap adds 1 coin',
  );

  // Multiple taps to get coins for purchases
  for (int i = 0; i < 99; i++) {
    controller.tap();
  }
  expectTrue(
    (controller.state.coins.toDouble() - 100).abs() < 0.1,
    '100 taps = 100 coins',
  );

  // --- Purchase generator ---
  final bought = controller.purchaseGenerator('gen_1');
  expectTrue(bought, 'purchase generator succeeded');
  expectTrue(controller.state.generators['gen_1']!.level == 1, 'gen level 1');

  // --- Production ---
  final production = controller.productionPerSecond;
  expectTrue(
    (production.toDouble() - 5).abs() < 0.1,
    'production = 5/sec with level 1',
  );

  // --- Tick ---
  controller.tick(1.0); // 1 second
  final coinsAfterTick = controller.state.coins.toDouble();
  // Should have gained ~5 coins from production
  expectTrue(coinsAfterTick > 85, 'tick produces coins');

  // --- Purchase upgrade ---
  // Tap more to afford
  for (int i = 0; i < 100; i++) {
    controller.tap();
  }
  final upgBought = controller.purchaseUpgrade('upg_tap');
  expectTrue(upgBought, 'purchase upgrade succeeded');
  expectTrue(
    (controller.state.tapMultiplier.toDouble() - 2).abs() < 0.01,
    'tap multiplier updated to 2',
  );

  // --- Invalid purchase ---
  final invalid = controller.purchaseGenerator('nonexistent');
  expectTrue(!invalid, 'nonexistent generator fails');

  print('\n$passed passed, $failed failed');
  if (failed > 0) throw Exception('Tests failed');
}
