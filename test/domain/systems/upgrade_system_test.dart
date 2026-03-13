import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/domain/models/game_state.dart';
import 'package:ai_evolution/domain/models/upgrade.dart';
import 'package:ai_evolution/domain/systems/upgrade_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UpgradeDefinition tapUpgrade;
  late UpgradeDefinition prodUpgrade;

  setUp(() {
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

    prodUpgrade = UpgradeDefinition(
      id: 'upg_prod',
      name: 'Prod Boost',
      description: 'Test',
      type: UpgradeType.productionMultiplier,
      eraId: 'era_1',
      baseCost: GameNumber.fromDouble(100),
      costGrowthRate: 2.0,
      maxLevel: 3,
      effectPerLevel: GameNumber.fromDouble(1.5),
    );
  });

  test('purchaseUpgrade applies effects and respects constraints', () {
    final state = GameState.initial().copyWith(
      coins: GameNumber.fromDouble(1000),
    );

    final afterTapUpg = UpgradeSystem.purchaseUpgrade(state, tapUpgrade);
    expect(afterTapUpg.upgrades.containsKey('upg_tap'), isTrue);
    expect(afterTapUpg.upgrades['upg_tap']!.level, 1);
    expect(afterTapUpg.tapMultiplier.toDouble(), closeTo(2.0, 0.01));
    expect(afterTapUpg.coins < state.coins, isTrue);

    final afterProdUpg = UpgradeSystem.purchaseUpgrade(
      state.copyWith(coins: GameNumber.fromDouble(500)),
      prodUpgrade,
    );
    expect(
      afterProdUpg.productionMultiplier.toDouble(),
      closeTo(1.5, 0.01),
    );

    final poorState = GameState.initial().copyWith(
      coins: GameNumber.fromDouble(1),
    );
    expect(UpgradeSystem.purchaseUpgrade(poorState, tapUpgrade), same(poorState));

    final maxState = state.copyWith(
      upgrades: {
        'upg_tap': const UpgradeState(definitionId: 'upg_tap', level: 5),
      },
    );
    expect(UpgradeSystem.purchaseUpgrade(maxState, tapUpgrade), same(maxState));
  });

  test('purchaseUpgrade supports multi-buy and max clamping', () {
    final state = GameState.initial().copyWith(
      coins: GameNumber.fromDouble(1000),
    );

    final afterTriple =
        UpgradeSystem.purchaseUpgrade(state, tapUpgrade, quantity: 3);
    expect(afterTriple.upgrades['upg_tap']!.level, 3);
    expect(afterTriple.tapMultiplier.toDouble(), closeTo(8.0, 0.01));

    final nearMax = GameState.initial().copyWith(
      coins: GameNumber.fromDouble(10000),
      upgrades: {
        'upg_tap': const UpgradeState(definitionId: 'upg_tap', level: 4),
      },
      tapMultiplier: GameNumber.fromDouble(16),
    );
    final clamped =
        UpgradeSystem.purchaseUpgrade(nearMax, tapUpgrade, quantity: 100);
    expect(clamped.upgrades['upg_tap']!.level, 5);
    expect(clamped.tapMultiplier.toDouble(), closeTo(32.0, 0.01));
  });
}
