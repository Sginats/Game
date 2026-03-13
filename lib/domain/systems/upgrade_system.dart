import '../mechanics/cost_calculator.dart';
import '../models/game_state.dart';
import '../models/generator.dart';
import '../models/upgrade.dart';

/// Pure functions for the upgrade system.
class UpgradeSystem {
  /// Purchase an upgrade. Returns state unchanged if unaffordable or at max level.
  static GameState purchaseUpgrade(
    GameState state,
    UpgradeDefinition definition, {
    int quantity = 1,
  }) {
    if (quantity <= 0) return state;
    var updatedState = state;

    for (var i = 0; i < quantity; i++) {
      final current = updatedState.upgrades[definition.id];
      final currentLevel = current?.level ?? 0;

      if (currentLevel >= definition.maxLevel) return updatedState;

      final cost = CostCalculator.calculateCost(
        definition.baseCost,
        definition.costGrowthRate,
        currentLevel,
      );

      if (updatedState.coins < cost) return updatedState;

      final newUpgrades = Map<String, UpgradeState>.from(updatedState.upgrades);
      newUpgrades[definition.id] = (current ??
              UpgradeState(definitionId: definition.id))
          .copyWith(level: currentLevel + 1);

      updatedState = updatedState.copyWith(
        coins: updatedState.coins - cost,
        upgrades: newUpgrades,
      );

      switch (definition.type) {
        case UpgradeType.tapMultiplier:
          updatedState = updatedState.copyWith(
            tapMultiplier:
                updatedState.tapMultiplier * definition.effectPerLevel,
          );
          break;

        case UpgradeType.productionMultiplier:
          updatedState = updatedState.copyWith(
            productionMultiplier:
                updatedState.productionMultiplier * definition.effectPerLevel,
          );
          break;

        case UpgradeType.generatorMultiplier:
          if (definition.targetGeneratorId != null) {
            final genState =
                updatedState.generators[definition.targetGeneratorId!];
            if (genState != null) {
              final newGenerators =
                  Map<String, GeneratorState>.from(updatedState.generators);
              newGenerators[definition.targetGeneratorId!] = genState.copyWith(
                multiplier: genState.multiplier * definition.effectPerLevel,
              );
              updatedState = updatedState.copyWith(generators: newGenerators);
            }
          }
          break;
      }
    }

    return updatedState;
  }
}
