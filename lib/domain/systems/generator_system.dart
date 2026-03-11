import '../../core/math/game_number.dart';
import '../mechanics/cost_calculator.dart';
import '../models/game_state.dart';
import '../models/generator.dart';

/// Pure functions for the generator system.
///
/// generatorProduction = base × level × multiplier × globalMultiplier
class GeneratorSystem {
  /// Calculate production for a single generator.
  static GameNumber calculateGeneratorProduction(
    GeneratorDefinition definition,
    GeneratorState state,
    GameNumber globalMultiplier,
  ) {
    if (state.level <= 0) return const GameNumber.zero();

    return definition.baseProduction *
        GameNumber.fromInt(state.level) *
        state.multiplier *
        globalMultiplier;
  }

  /// Calculate total production across all generators.
  static GameNumber calculateTotalProduction(
    Map<String, GeneratorDefinition> definitions,
    Map<String, GeneratorState> generators,
    GameNumber globalMultiplier,
  ) {
    GameNumber total = const GameNumber.zero();

    for (final entry in generators.entries) {
      final definition = definitions[entry.key];
      if (definition == null) continue;

      total = total +
          calculateGeneratorProduction(definition, entry.value, globalMultiplier);
    }

    return total;
  }

  /// Purchase [quantity] levels of a generator. Returns state unchanged if
  /// the player cannot afford it.
  static GameState purchaseGenerator(
    GameState state,
    GeneratorDefinition definition,
    int quantity,
  ) {
    if (quantity <= 0) return state;

    final current = state.generators[definition.id];
    final currentLevel = current?.level ?? 0;

    final totalCost = CostCalculator.calculateTotalCost(
      definition.baseCost,
      definition.costGrowthRate,
      currentLevel,
      quantity,
    );

    if (state.coins < totalCost) return state;

    final newGenerators = Map<String, GeneratorState>.from(state.generators);
    newGenerators[definition.id] = (current ??
            GeneratorState(definitionId: definition.id))
        .copyWith(level: currentLevel + quantity);

    return state.copyWith(
      coins: state.coins - totalCost,
      generators: newGenerators,
    );
  }
}
