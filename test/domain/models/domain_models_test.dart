import '../../../lib/core/math/game_number.dart';
import '../../../lib/domain/models/game_state.dart';
import '../../../lib/domain/models/generator.dart';
import '../../../lib/domain/models/upgrade.dart';
import '../../../lib/domain/models/era.dart';

void main() {
  var passed = 0;
  var failed = 0;

  void expect(dynamic actual, dynamic expected, String name) {
    if (actual == expected) {
      passed++;
    } else {
      print('FAIL: $name — expected $expected, got $actual');
      failed++;
    }
  }

  void expectTrue(bool condition, String name) {
    if (condition) {
      passed++;
    } else {
      print('FAIL: $name');
      failed++;
    }
  }

  // --- Era ---
  final era = Era.fromJson({
    'id': 'era_1',
    'name': 'Dawn',
    'description': 'First era',
    'order': 1,
    'unlockRequirement': null,
  });
  expect(era.id, 'era_1', 'Era.fromJson id');
  expect(era.order, 1, 'Era.fromJson order');

  // --- GeneratorDefinition ---
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
  expect(genDef.id, 'gen_1', 'GeneratorDefinition.fromJson id');
  expectTrue((genDef.baseCost.toDouble() - 10).abs() < 0.1, 'GenDef baseCost');
  expectTrue((genDef.costGrowthRate - 1.15).abs() < 0.01, 'GenDef growthRate');

  // --- GeneratorState ---
  final genState = GeneratorState(definitionId: 'gen_1', level: 5);
  expect(genState.level, 5, 'GeneratorState level');
  final genCopy = genState.copyWith(level: 10);
  expect(genCopy.level, 10, 'GeneratorState copyWith');

  final genJson = genState.toJson();
  final genFromJson = GeneratorState.fromJson(genJson);
  expect(genFromJson.definitionId, 'gen_1', 'GeneratorState JSON round-trip');
  expect(genFromJson.level, 5, 'GeneratorState JSON round-trip level');

  // --- UpgradeDefinition ---
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
  expect(upgDef.id, 'upg_1', 'UpgradeDefinition.fromJson id');
  expect(upgDef.type, UpgradeType.tapMultiplier, 'UpgradeDefinition type');
  expect(upgDef.maxLevel, 10, 'UpgradeDefinition maxLevel');

  // --- UpgradeState ---
  final upgState = UpgradeState(definitionId: 'upg_1', level: 3);
  expect(upgState.level, 3, 'UpgradeState level');
  final upgJson = upgState.toJson();
  final upgFromJson = UpgradeState.fromJson(upgJson);
  expect(upgFromJson.level, 3, 'UpgradeState JSON round-trip');

  // --- GameState ---
  final state = GameState.initial();
  expectTrue(state.coins.isZero, 'Initial coins are zero');
  expectTrue(state.unlockedEras.contains('era_1'), 'Era 1 unlocked initially');

  final modifiedState = state.copyWith(
    coins: GameNumber.fromDouble(100),
  );
  expectTrue((modifiedState.coins.toDouble() - 100).abs() < 0.1, 'copyWith coins');
  expectTrue(state.coins.isZero, 'Original state unchanged');

  // GameState JSON round-trip
  final stateJson = modifiedState.toJson();
  final stateFromJson = GameState.fromJson(stateJson);
  expectTrue(
    (stateFromJson.coins.toDouble() - 100).abs() < 0.1,
    'GameState JSON round-trip coins',
  );

  // New fields
  expect(state.totalTaps, 0, 'Initial totalTaps = 0');
  expect(state.prestigeCount, 0, 'Initial prestigeCount = 0');
  expect(state.tutorialComplete, false, 'Initial tutorial not complete');
  expectTrue(state.unlockedAchievements.isEmpty, 'Initial no achievements');

  final prestigeState = state.copyWith(
    totalTaps: 50,
    prestigeCount: 2,
    prestigeMultiplier: GameNumber.fromDouble(1.5),
    unlockedAchievements: {'ach_1', 'ach_2'},
    tutorialComplete: true,
  );
  expect(prestigeState.totalTaps, 50, 'copyWith totalTaps');
  expect(prestigeState.prestigeCount, 2, 'copyWith prestigeCount');
  expectTrue(
    (prestigeState.prestigeMultiplier.toDouble() - 1.5).abs() < 0.01,
    'copyWith prestigeMultiplier',
  );
  expect(prestigeState.tutorialComplete, true, 'copyWith tutorialComplete');
  expect(prestigeState.unlockedAchievements.length, 2, 'copyWith achievements');

  // New fields JSON round-trip
  final pJson = prestigeState.toJson();
  final pFromJson = GameState.fromJson(pJson);
  expect(pFromJson.totalTaps, 50, 'JSON round-trip totalTaps');
  expect(pFromJson.prestigeCount, 2, 'JSON round-trip prestigeCount');
  expect(pFromJson.tutorialComplete, true, 'JSON round-trip tutorialComplete');
  expect(pFromJson.unlockedAchievements.length, 2, 'JSON round-trip achievements');

  print('\n$passed passed, $failed failed');
  if (failed > 0) throw Exception('Tests failed');
}
