import 'package:ai_evolution/application/controllers/game_controller.dart';
import 'package:ai_evolution/application/services/config_service.dart';
import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/core/time/time_provider.dart';
import 'package:ai_evolution/domain/models/generator.dart';
import 'package:ai_evolution/domain/models/upgrade.dart';
import 'package:flutter_test/flutter_test.dart';

class FixedTimeProvider implements TimeProvider {
  DateTime _now;
  FixedTimeProvider(this._now);

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
}

void main() {
  late GeneratorDefinition genDef;
  late UpgradeDefinition tapUpgrade;
  late ConfigService config;
  late FixedTimeProvider time;

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
  });

  test('tap, purchase, and production flow works', () {
    final controller = GameController(config: config, timeProvider: time);

    expect(controller.state.coins.isZero, isTrue);

    expect(controller.tap(), isTrue);
    expect(controller.state.coins.toDouble(), greaterThan(0.9));
    expect(controller.state.totalTaps, 1);

    for (var i = 0; i < 99; i++) {
      time.advance(const Duration(milliseconds: 600));
      expect(controller.tap(), isTrue);
    }
    expect(controller.state.coins.toDouble(), greaterThan(100));
    expect(controller.state.totalTaps, 100);

    expect(controller.purchaseGenerator('gen_1'), isTrue);
    expect(controller.state.generators['gen_1']!.level, 1);
    expect(controller.productionPerSecond.toDouble(), closeTo(5, 0.1));

    controller.tick(1.0);
    expect(controller.state.coins.toDouble(), greaterThan(85));

    for (var i = 0; i < 10; i++) {
      time.advance(const Duration(milliseconds: 600));
      expect(controller.tap(), isTrue);
    }
    expect(controller.purchaseUpgrade('upg_tap'), isTrue);
    expect(controller.state.tapMultiplier.toDouble(), closeTo(2, 0.01));
    expect(controller.purchaseGenerator('nonexistent'), isFalse);
    expect(controller.canPrestige, isFalse);
  });

  test('upgrade purchase mode quantities are applied correctly', () {
    final controller = GameController(config: config, timeProvider: time);
    controller.setState(
      controller.state.copyWith(
        coins: GameNumber.fromDouble(10000),
      ),
    );

    expect(controller.purchaseUpgrade('upg_tap', quantity: 3), isTrue);
    expect(controller.state.upgrades['upg_tap']!.level, 3);
    expect(controller.state.tapMultiplier.toDouble(), closeTo(8, 0.01));

    expect(controller.purchaseUpgrade('upg_tap', quantity: 100), isTrue);
    expect(controller.state.upgrades['upg_tap']!.level, 5);
  });

  test('tap cooldown blocks spam and recovers over time', () {
    final controller = GameController(config: config, timeProvider: time);

    expect(controller.canTap, isTrue);
    expect(controller.tap(), isTrue);
    expect(controller.canTap, isFalse);
    expect(controller.tap(), isFalse);

    time.advance(const Duration(milliseconds: 250));
    expect(controller.tapCooldownProgress, lessThan(1));

    time.advance(const Duration(milliseconds: 400));
    expect(controller.canTap, isTrue);
    expect(controller.tap(), isTrue);
  });
}
