/// Tests that verify the stateVersion counter and related performance
/// optimisations in GameController behave correctly.
import 'package:ai_evolution/application/controllers/game_controller.dart';
import 'package:ai_evolution/application/services/config_service.dart';
import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/core/time/time_provider.dart';
import 'package:ai_evolution/domain/models/generator.dart';
import 'package:ai_evolution/domain/models/upgrade.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedTime implements TimeProvider {
  DateTime _now;
  _FixedTime(this._now);
  @override
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

void main() {
  late ConfigService config;
  late _FixedTime time;
  late GeneratorDefinition genDef;
  late UpgradeDefinition upgDef;

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
    upgDef = UpgradeDefinition(
      id: 'upg_1',
      name: 'Tap Boost',
      description: 'Test',
      type: UpgradeType.tapMultiplier,
      category: UpgradeCategory.tap,
      eraId: 'era_1',
      baseCost: GameNumber.fromDouble(20),
      costGrowthRate: 1.2,
      multiplier: 2.0,
    );
    time = _FixedTime(DateTime(2025));
    config = ConfigService(
      baseTapValue: GameNumber.fromDouble(1),
      baseTapMultiplier: GameNumber.fromDouble(1),
      generators: {'gen_1': genDef},
      upgrades: {'upg_1': upgDef},
      eras: const [],
      maxOfflineHours: 8,
      autoSaveIntervalSeconds: 30,
      tickRateMs: 250,
    );
  });

  GameController _makeController({double coins = 0}) {
    final c = GameController(config: config, timeProvider: time);
    if (coins > 0) {
      c.setState(c.state.copyWith(coins: GameNumber.fromDouble(coins)));
    }
    return c;
  }

  group('stateVersion counter', () {
    test('starts at 0', () {
      final c = _makeController();
      expect(c.stateVersion, 0);
    });

    test('increments on successful purchaseGenerator', () {
      final c = _makeController(coins: 1000);
      final before = c.stateVersion;
      final ok = c.purchaseGenerator('gen_1');
      expect(ok, isTrue);
      expect(c.stateVersion, greaterThan(before));
    });

    test('increments on successful purchaseUpgrade', () {
      final c = _makeController(coins: 1000);
      final before = c.stateVersion;
      final ok = c.purchaseUpgrade('upg_1');
      expect(ok, isTrue);
      expect(c.stateVersion, greaterThan(before));
    });

    test('does NOT increment when purchaseGenerator fails (insufficient coins)', () {
      final c = _makeController(coins: 0);
      final before = c.stateVersion;
      final ok = c.purchaseGenerator('gen_1');
      expect(ok, isFalse);
      expect(c.stateVersion, before);
    });

    test('does NOT increment when purchaseUpgrade fails (insufficient coins)', () {
      final c = _makeController(coins: 0);
      final before = c.stateVersion;
      final ok = c.purchaseUpgrade('upg_1');
      expect(ok, isFalse);
      expect(c.stateVersion, before);
    });

    test('each successful purchase increments the version monotonically', () {
      final c = _makeController(coins: 1000000);
      final v0 = c.stateVersion;
      c.purchaseGenerator('gen_1');
      final v1 = c.stateVersion;
      c.purchaseGenerator('gen_1');
      final v2 = c.stateVersion;
      c.purchaseUpgrade('upg_1');
      final v3 = c.stateVersion;

      expect(v1, greaterThan(v0));
      expect(v2, greaterThan(v1));
      expect(v3, greaterThan(v2));
    });

    test('does NOT increment on setCurrentEra when era is already current', () {
      final c = _makeController();
      // era_1 is the default current era; calling setCurrentEra on it again
      // should be a no-op that returns true without bumping the version.
      final before = c.stateVersion;
      c.setCurrentEra('era_1');
      expect(c.stateVersion, before);
    });

    test('stateVersion is stable during idle tick (no purchases, no era unlock)', () {
      // Give the generator one level so production runs
      final c = _makeController(coins: 1000);
      c.purchaseGenerator('gen_1');
      final versionAfterPurchase = c.stateVersion;
      // Tick several times without purchasing; config has no additional eras
      // to unlock, so version should remain constant.
      c.tick(0.25);
      c.tick(0.25);
      c.tick(0.25);
      expect(c.stateVersion, versionAfterPurchase);
    });
  });
}
