import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/domain/mechanics/offline_progression.dart';
import 'package:ai_evolution/domain/models/game_state.dart';
import 'package:ai_evolution/domain/models/generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculateOfflineEarnings handles normal and capped cases', () {
    final production = GameNumber.fromDouble(10);
    const maxHours = 8;

    expect(
      OfflineProgression.calculateOfflineEarnings(production, 100, maxHours)
          .toDouble(),
      closeTo(1000, 0.1),
    );
    expect(
      OfflineProgression.calculateOfflineEarnings(
        const GameNumber.zero(),
        100,
        maxHours,
      ).isZero,
      isTrue,
    );
    expect(
      OfflineProgression.calculateOfflineEarnings(production, 0, maxHours)
          .isZero,
      isTrue,
    );
    expect(
      OfflineProgression.calculateOfflineEarnings(
        production,
        100000,
        maxHours,
      ).toDouble(),
      closeTo(10.0 * 28800, 1.0),
    );
  });

  test('applyOfflineEarnings updates state correctly', () {
    final genDef = GeneratorDefinition(
      id: 'gen_1',
      name: 'Test',
      description: 'Test',
      eraId: 'era_1',
      baseCost: GameNumber.fromDouble(10),
      costGrowthRate: 1.15,
      baseProduction: GameNumber.fromDouble(5),
    );

    final baseTime = DateTime(2026, 1, 1);
    final state = GameState(
      coins: GameNumber.fromDouble(100),
      totalCoinsEarned: GameNumber.fromDouble(100),
      tapMultiplier: GameNumber.fromDouble(1),
      productionMultiplier: GameNumber.fromDouble(1),
      generators: {
        'gen_1': GeneratorState(definitionId: 'gen_1', level: 2),
      },
      upgrades: const {},
      unlockedEras: const {'era_1'},
      currentEraId: 'era_1',
      lastSaveTime: baseTime,
    );

    final newState = OfflineProgression.applyOfflineEarnings(
      state,
      {'gen_1': genDef},
      baseTime.add(const Duration(seconds: 60)),
      8,
    );

    expect(newState.coins.toDouble(), closeTo(700, 1.0));
  });
}
