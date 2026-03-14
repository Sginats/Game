import 'package:ai_evolution/domain/models/companion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CompanionTrait serializes and deserializes', () {
    const trait = CompanionTrait(
      id: 'trait_fast',
      name: 'Quick Processor',
      description: 'Processes tasks faster.',
      effectType: 'speed',
      magnitude: 1.5,
    );

    final json = trait.toJson();
    final restored = CompanionTrait.fromJson(json);

    expect(restored.id, 'trait_fast');
    expect(restored.name, 'Quick Processor');
    expect(restored.effectType, 'speed');
    expect(restored.magnitude, 1.5);
  });

  test('CompanionAbility serializes and deserializes', () {
    const ability = CompanionAbility(
      id: 'ability_scan',
      name: 'Data Scan',
      description: 'Scans for resources.',
      cooldownSeconds: 30.0,
      tokenGenerationType: 'scrap',
      tokenAmount: 5.0,
    );

    final json = ability.toJson();
    final restored = CompanionAbility.fromJson(json);

    expect(restored.id, 'ability_scan');
    expect(restored.cooldownSeconds, 30.0);
    expect(restored.tokenGenerationType, 'scrap');
    expect(restored.tokenAmount, 5.0);
  });

  test('CompanionDefinition serializes with all fields', () {
    const def = CompanionDefinition(
      id: 'comp_scout_drone',
      name: 'Scout Drone',
      description: 'A small drone that scouts for resources.',
      type: CompanionType.drone,
      rarity: CompanionRarity.rare,
      sceneAffinity: 'room_01',
      traits: [
        CompanionTrait(
          id: 'trait_1',
          name: 'Scavenger',
          description: 'Finds extra scrap.',
          effectType: 'resourceBonus',
          magnitude: 0.1,
        ),
      ],
      abilities: [
        CompanionAbility(
          id: 'ab_1',
          name: 'Quick Scan',
          description: 'Scans nearby area.',
          cooldownSeconds: 15.0,
          tokenGenerationType: 'scrap',
          tokenAmount: 3.0,
        ),
      ],
      evolutionStage: 1,
      maxEvolutionStage: 5,
      collectionGroup: 'junk_drones',
      automationRate: 0.5,
      resourceBonusPercent: 10.0,
      fusionMaterial: false,
      unlockMethod: 'discovered',
    );

    final json = def.toJson();
    final restored = CompanionDefinition.fromJson(json);

    expect(restored.id, 'comp_scout_drone');
    expect(restored.type, CompanionType.drone);
    expect(restored.rarity, CompanionRarity.rare);
    expect(restored.sceneAffinity, 'room_01');
    expect(restored.traits.length, 1);
    expect(restored.abilities.length, 1);
    expect(restored.maxEvolutionStage, 5);
    expect(restored.automationRate, 0.5);
    expect(restored.resourceBonusPercent, 10.0);
    expect(restored.unlockMethod, 'discovered');
  });

  test('CompanionState serializes and deserializes', () {
    const state = CompanionState(
      definitionId: 'comp_scout_drone',
      level: 3,
      experience: 150.0,
      evolutionStage: 2,
      equipped: true,
      abilityCooldowns: {'ab_1': 5.0},
      tokensGenerated: 42,
      acquired: true,
    );

    final json = state.toJson();
    final restored = CompanionState.fromJson(json);

    expect(restored.definitionId, 'comp_scout_drone');
    expect(restored.level, 3);
    expect(restored.experience, 150.0);
    expect(restored.evolutionStage, 2);
    expect(restored.equipped, isTrue);
    expect(restored.abilityCooldowns['ab_1'], 5.0);
    expect(restored.tokensGenerated, 42);
    expect(restored.acquired, isTrue);
  });

  test('CompanionState copyWith preserves unmodified fields', () {
    const state = CompanionState(
      definitionId: 'comp_1',
      level: 5,
      experience: 200.0,
      equipped: true,
    );

    final updated = state.copyWith(level: 6);
    expect(updated.level, 6);
    expect(updated.experience, 200.0);
    expect(updated.equipped, isTrue);
    expect(state.level, 5);
  });

  test('CompanionCollectionBonus serializes and deserializes', () {
    const bonus = CompanionCollectionBonus(
      id: 'col_junk',
      name: 'Junk Collector',
      description: 'Own all junk drones.',
      requiredCompanionIds: ['comp_1', 'comp_2', 'comp_3'],
      bonusType: 'productionMultiplier',
      bonusMagnitude: 1.25,
      fulfilled: false,
    );

    final json = bonus.toJson();
    final restored = CompanionCollectionBonus.fromJson(json);

    expect(restored.id, 'col_junk');
    expect(restored.requiredCompanionIds.length, 3);
    expect(restored.bonusMagnitude, 1.25);
    expect(restored.fulfilled, isFalse);
  });

  test('CompanionSystemState serializes and deserializes', () {
    const system = CompanionSystemState(
      ownedCompanions: [
        CompanionState(
          definitionId: 'comp_1',
          level: 2,
          acquired: true,
        ),
      ],
      activeSlots: 4,
      collectionBonuses: [
        CompanionCollectionBonus(
          id: 'col_1',
          name: 'Test Set',
          description: 'A test collection.',
          requiredCompanionIds: ['comp_1'],
          bonusType: 'tapBonus',
          bonusMagnitude: 1.1,
          fulfilled: true,
        ),
      ],
      totalTokensGenerated: 100,
      fusionCount: 3,
    );

    final json = system.toJson();
    final restored = CompanionSystemState.fromJson(json);

    expect(restored.ownedCompanions.length, 1);
    expect(restored.ownedCompanions.first.level, 2);
    expect(restored.activeSlots, 4);
    expect(restored.collectionBonuses.length, 1);
    expect(restored.collectionBonuses.first.fulfilled, isTrue);
    expect(restored.totalTokensGenerated, 100);
    expect(restored.fusionCount, 3);
  });

  test('CompanionSystemState defaults are empty', () {
    const system = CompanionSystemState();
    expect(system.ownedCompanions, isEmpty);
    expect(system.activeSlots, 3);
    expect(system.collectionBonuses, isEmpty);
    expect(system.totalTokensGenerated, 0);
    expect(system.fusionCount, 0);
  });

  test('CompanionType and CompanionRarity have expected values', () {
    expect(CompanionType.values.length, 7);
    expect(CompanionRarity.values.length, 5);
    expect(CompanionType.drone.name, 'drone');
    expect(CompanionRarity.legendary.name, 'legendary');
  });
}
