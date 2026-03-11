import '../mechanics/cost_calculator.dart';
import '../models/game_state.dart';
import '../models/generator.dart';
import '../models/upgrade.dart';

/// Pure functions for the upgrade system.
class UpgradeSystem {
  /// Purchase an upgrade. Returns state unchanged if unaffordable or at max level.
  static GameState purchaseUpgrade(
    GameState state,
    UpgradeDefinition definition,
  ) {
    final current = state.upgrades[definition.id];
    final currentLevel = current?.level ?? 0;

    // Check max level
    if (currentLevel >= definition.maxLevel) return state;

    // Calculate cost
    final cost = CostCalculator.calculateCost(
      definition.baseCost,
      definition.costGrowthRate,
      currentLevel,
    );

    // Check affordability
    if (state.coins < cost) return state;

    // Update upgrade level
    final newUpgrades = Map<String, UpgradeState>.from(state.upgrades);
    newUpgrades[definition.id] = (current ??
            UpgradeState(definitionId: definition.id))
        .copyWith(level: currentLevel + 1);

    // Apply effect based on type
    GameState newState = state.copyWith(
      coins: state.coins - cost,
      upgrades: newUpgrades,
    );

    switch (definition.type) {
      case UpgradeType.tapMultiplier:
        newState = newState.copyWith(
          tapMultiplier: newState.tapMultiplier * definition.effectPerLevel,
        );
        break;

      case UpgradeType.productionMultiplier:
        newState = newState.copyWith(
          productionMultiplier:
              newState.productionMultiplier * definition.effectPerLevel,
        );
        break;

      case UpgradeType.generatorMultiplier:
        if (definition.targetGeneratorId != null) {
          final genState = newState.generators[definition.targetGeneratorId!];
          if (genState != null) {
            final newGenerators =
                Map<String, GeneratorState>.from(newState.generators);
            newGenerators[definition.targetGeneratorId!] = genState.copyWith(
              multiplier: genState.multiplier * definition.effectPerLevel,
            );
            newState = newState.copyWith(generators: newGenerators);
          }
        }
        break;
    }

    return newState;
  }
}
