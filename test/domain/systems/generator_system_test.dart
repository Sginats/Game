import '../../../lib/core/math/game_number.dart';
import '../../../lib/domain/models/game_state.dart';
import '../../../lib/domain/models/generator.dart';
import '../../../lib/domain/systems/generator_system.dart';

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

  final globalMult = GameNumber.fromDouble(1);

  // --- calculateGeneratorProduction ---
  // Level 0 → zero production
  final zeroProd = GeneratorSystem.calculateGeneratorProduction(
    genDef,
    GeneratorState(definitionId: 'gen_1', level: 0),
    globalMult,
  );
  expectTrue(zeroProd.isZero, 'level 0 = zero production');

  // Level 2 → 5 * 2 * 1 * 1 = 10
  final prod2 = GeneratorSystem.calculateGeneratorProduction(
    genDef,
    GeneratorState(definitionId: 'gen_1', level: 2),
    globalMult,
  );
  expectTrue((prod2.toDouble() - 10).abs() < 0.1, 'level 2 production = 10');

  // --- calculateTotalProduction ---
  final total = GeneratorSystem.calculateTotalProduction(
    {'gen_1': genDef},
    {'gen_1': GeneratorState(definitionId: 'gen_1', level: 3)},
    globalMult,
  );
  expectTrue((total.toDouble() - 15).abs() < 0.1, 'total production with level 3 = 15');

  // --- purchaseGenerator ---
  final state = GameState.initial().copyWith(
    coins: GameNumber.fromDouble(100),
  );

  // Purchase 1
  final afterBuy = GeneratorSystem.purchaseGenerator(state, genDef, 1);
  expectTrue(afterBuy.generators.containsKey('gen_1'), 'generator purchased');
  expectTrue(afterBuy.generators['gen_1']!.level == 1, 'generator level is 1');
  expectTrue(afterBuy.coins < state.coins, 'coins decreased');

  // Can't afford
  final poorState = GameState.initial().copyWith(
    coins: GameNumber.fromDouble(1), // too little
  );
  final noBuy = GeneratorSystem.purchaseGenerator(poorState, genDef, 1);
  expectTrue(identical(noBuy, poorState), 'purchase fails when too poor');

  print('\n$passed passed, $failed failed');
  if (failed > 0) throw Exception('Tests failed');
}
