import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/domain/models/era.dart';
import 'package:ai_evolution/domain/models/game_state.dart';
import 'package:ai_evolution/domain/models/game_systems.dart';
import 'package:ai_evolution/domain/models/generator.dart';
import 'package:ai_evolution/domain/models/upgrade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('era model serializes and uses defaults', () {
    final era = Era.fromJson({
      'id': 'era_1',
      'name': 'Junk Corner',
      'description': 'First era',
      'order': 1,
      'unlockRequirement': null,
      'currency': 'Scrap',
      'rule': 'Taps stronger than automation',
    });
    expect(era.id, 'era_1');
    expect(era.order, 1);
    expect(era.currency, 'Scrap');
    expect(Era.fromJson(era.toJson()).rule, 'Taps stronger than automation');

    final legacy = Era.fromJson({
      'id': 'era_old',
      'name': 'Old Era',
      'description': 'Legacy',
      'order': 99,
    });
    expect(legacy.currency, 'Scrap');
    expect(legacy.rule, '');
  });

  test('generator and upgrade models serialize', () {
    final genDef = GeneratorDefinition.fromJson({
      'id': 'gen_1',
      'name': 'Proc',
      'description': 'Test',
      'eraId': 'era_1',
      'baseCost': '10',
      'costGrowthRate': '1.15',
      'baseProduction': '1',
      'unlockRequirement': null,
    });
    expect(genDef.id, 'gen_1');
    expect(genDef.baseCost.toDouble(), closeTo(10, 0.1));

    final genState = GeneratorState(definitionId: 'gen_1', level: 5);
    expect(GeneratorState.fromJson(genState.toJson()).level, 5);
    expect(genState.copyWith(level: 10).level, 10);

    final upgDef = UpgradeDefinition.fromJson({
      'id': 'upg_1',
      'name': 'Test',
      'description': 'Test upgrade',
      'type': 'tapMultiplier',
      'eraId': 'era_1',
      'baseCost': '50',
      'costGrowthRate': '1.5',
      'maxLevel': 10,
      'effectPerLevel': '2',
    });
    expect(upgDef.type, UpgradeType.tapMultiplier);
    expect(upgDef.maxLevel, 10);

    const upgState = UpgradeState(definitionId: 'upg_1', level: 3);
    expect(UpgradeState.fromJson(upgState.toJson()).level, 3);
  });

  test('game state and system enums preserve expected defaults', () {
    final state = GameState.initial();
    expect(state.coins.isZero, isTrue);
    expect(state.unlockedEras.contains('era_1'), isTrue);

    final modified = state.copyWith(coins: GameNumber.fromDouble(100));
    expect(modified.coins.toDouble(), closeTo(100, 0.1));
    expect(state.coins.isZero, isTrue);
    expect(GameState.fromJson(modified.toJson()).coins.toDouble(), closeTo(100, 0.1));

    final prestigeState = state.copyWith(
      totalTaps: 50,
      prestigeCount: 2,
      prestigeMultiplier: GameNumber.fromDouble(1.5),
      unlockedAchievements: {'ach_1', 'ach_2'},
      tutorialComplete: true,
    );
    final decoded = GameState.fromJson(prestigeState.toJson());
    expect(decoded.totalTaps, 50);
    expect(decoded.prestigeCount, 2);
    expect(decoded.tutorialComplete, isTrue);
    expect(decoded.unlockedAchievements.length, 2);

    expect(PurchaseMode.max.label, 'MAX');
    expect(AITrait.transcendent.label, 'Transcendent');
    expect(Ending.fromJson({
      'id': 'ending_mercy',
      'name': 'Mercy',
      'description': 'The AI chooses compassion.',
    }).name, 'Mercy');
    expect(UpgradeCategory.values.length, 5);
  });
}
