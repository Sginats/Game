import '../../../lib/core/math/game_number.dart';
import '../../../lib/domain/models/game_state.dart';
import '../../../lib/domain/models/generator.dart';
import '../../../lib/domain/models/upgrade.dart';
import '../../../lib/domain/systems/upgrade_system.dart';

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

  final prodUpgrade = UpgradeDefinition(
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

  // --- purchaseUpgrade: tap multiplier ---
  final state = GameState.initial().copyWith(
    coins: GameNumber.fromDouble(1000),
  );

  final afterTapUpg = UpgradeSystem.purchaseUpgrade(state, tapUpgrade);
  expectTrue(
    afterTapUpg.upgrades.containsKey('upg_tap'),
    'tap upgrade purchased',
  );
  expectTrue(
    afterTapUpg.upgrades['upg_tap']!.level == 1,
    'tap upgrade level 1',
  );
  expectTrue(
    (afterTapUpg.tapMultiplier.toDouble() - 2.0).abs() < 0.01,
    'tapMultiplier doubled',
  );
  expectTrue(afterTapUpg.coins < state.coins, 'coins spent on upgrade');

  // --- purchaseUpgrade: production multiplier ---
  final afterProdUpg = UpgradeSystem.purchaseUpgrade(
    state.copyWith(coins: GameNumber.fromDouble(500)),
    prodUpgrade,
  );
  expectTrue(
    (afterProdUpg.productionMultiplier.toDouble() - 1.5).abs() < 0.01,
    'productionMultiplier updated',
  );

  // --- Can't afford ---
  final poorState = GameState.initial().copyWith(
    coins: GameNumber.fromDouble(1),
  );
  final noUpg = UpgradeSystem.purchaseUpgrade(poorState, tapUpgrade);
  expectTrue(identical(noUpg, poorState), 'upgrade fails when poor');

  // --- Max level ---
  final maxState = state.copyWith(
    upgrades: {'upg_tap': const UpgradeState(definitionId: 'upg_tap', level: 5)},
  );
  final noUpg2 = UpgradeSystem.purchaseUpgrade(maxState, tapUpgrade);
  expectTrue(identical(noUpg2, maxState), 'upgrade fails at max level');

  print('\n$passed passed, $failed failed');
  if (failed > 0) throw Exception('Tests failed');
}
