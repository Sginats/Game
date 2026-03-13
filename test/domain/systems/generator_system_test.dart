import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/domain/models/game_state.dart';
import 'package:ai_evolution/domain/models/generator.dart';
import 'package:ai_evolution/domain/systems/generator_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GeneratorDefinition genDef;
  late GameNumber globalMult;

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
    globalMult = GameNumber.fromDouble(1);
  });

  test('production calculations are correct', () {
    expect(
      GeneratorSystem.calculateGeneratorProduction(
        genDef,
        GeneratorState(definitionId: 'gen_1', level: 0),
        globalMult,
      ).isZero,
      isTrue,
    );
    expect(
      GeneratorSystem.calculateGeneratorProduction(
        genDef,
        GeneratorState(definitionId: 'gen_1', level: 2),
        globalMult,
      ).toDouble(),
      closeTo(10, 0.1),
    );
    expect(
      GeneratorSystem.calculateTotalProduction(
        {'gen_1': genDef},
        {'gen_1': GeneratorState(definitionId: 'gen_1', level: 3)},
        globalMult,
      ).toDouble(),
      closeTo(15, 0.1),
    );
  });

  test('purchaseGenerator succeeds or fails based on affordability', () {
    final richState = GameState.initial().copyWith(
      coins: GameNumber.fromDouble(100),
    );
    final afterBuy = GeneratorSystem.purchaseGenerator(richState, genDef, 1);
    expect(afterBuy.generators.containsKey('gen_1'), isTrue);
    expect(afterBuy.generators['gen_1']!.level, 1);
    expect(afterBuy.coins < richState.coins, isTrue);

    final poorState = GameState.initial().copyWith(
      coins: GameNumber.fromDouble(1),
    );
    expect(
      GeneratorSystem.purchaseGenerator(poorState, genDef, 1),
      same(poorState),
    );
  });
}
