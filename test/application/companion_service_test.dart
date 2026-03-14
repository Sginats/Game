import 'package:ai_evolution/application/services/companion_service.dart';
import 'package:ai_evolution/domain/models/companion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CompanionService service;

  setUp(() {
    service = CompanionService(jsonList: [
      {
        'id': 'comp_1',
        'name': 'Scout Drone',
        'description': 'A basic drone.',
        'type': 'drone',
        'rarity': 'common',
        'sceneAffinity': 'room_01',
        'traits': [],
        'abilities': [],
        'evolutionStage': 1,
        'maxEvolutionStage': 5,
        'collectionGroup': 'junk_set',
        'automationRate': 0.5,
        'resourceBonusPercent': 5.0,
        'fusionMaterial': false,
        'unlockMethod': 'discovered',
      },
      {
        'id': 'comp_2',
        'name': 'Helper Bot',
        'description': 'A helpful bot.',
        'type': 'helperBot',
        'rarity': 'rare',
        'sceneAffinity': 'room_01',
        'traits': [],
        'abilities': [],
        'evolutionStage': 1,
        'maxEvolutionStage': 3,
        'collectionGroup': 'junk_set',
        'automationRate': 1.0,
        'resourceBonusPercent': 10.0,
        'fusionMaterial': false,
        'unlockMethod': 'crafted',
      },
      {
        'id': 'comp_3',
        'name': 'Lab Daemon',
        'description': 'A daemon for the lab.',
        'type': 'daemon',
        'rarity': 'epic',
        'sceneAffinity': 'room_05',
        'traits': [],
        'abilities': [],
        'evolutionStage': 1,
        'maxEvolutionStage': 5,
        'collectionGroup': 'lab_set',
        'automationRate': 1.5,
        'resourceBonusPercent': 15.0,
        'fusionMaterial': false,
        'unlockMethod': 'built',
      },
    ]);
  });

  test('loads definitions from JSON', () {
    expect(service.totalDefinitions, 3);
  });

  test('getDefinition returns correct companion', () {
    final def = service.getDefinition('comp_1');
    expect(def, isNotNull);
    expect(def!.name, 'Scout Drone');
    expect(def.type, CompanionType.drone);
    expect(def.rarity, CompanionRarity.common);
  });

  test('getDefinition returns null for unknown id', () {
    expect(service.getDefinition('unknown'), isNull);
  });

  test('getDefinitionsForRoom filters correctly', () {
    final room01 = service.getDefinitionsForRoom('room_01');
    expect(room01.length, 2);

    final room05 = service.getDefinitionsForRoom('room_05');
    expect(room05.length, 1);
    expect(room05.first.id, 'comp_3');
  });

  test('getDefinitionsByRarity filters correctly', () {
    final rare = service.getDefinitionsByRarity(CompanionRarity.rare);
    expect(rare.length, 1);
    expect(rare.first.id, 'comp_2');
  });

  test('getDefinitionsByType filters correctly', () {
    final drones = service.getDefinitionsByType(CompanionType.drone);
    expect(drones.length, 1);
    expect(drones.first.id, 'comp_1');
  });

  test('getCollectionGroup filters correctly', () {
    final junkSet = service.getCollectionGroup('junk_set');
    expect(junkSet.length, 2);
  });

  test('checkCollectionBonus works', () {
    const bonus = CompanionCollectionBonus(
      id: 'col_1',
      name: 'Junk Set',
      description: 'Own all junk companions.',
      requiredCompanionIds: ['comp_1', 'comp_2'],
      bonusType: 'production',
      bonusMagnitude: 1.5,
    );

    final owned = [
      const CompanionState(definitionId: 'comp_1', acquired: true),
      const CompanionState(definitionId: 'comp_2', acquired: true),
    ];

    expect(service.checkCollectionBonus(bonus, owned), isTrue);

    final partial = [
      const CompanionState(definitionId: 'comp_1', acquired: true),
    ];
    expect(service.checkCollectionBonus(bonus, partial), isFalse);
  });

  test('canEvolve checks evolution stage', () {
    const state = CompanionState(
      definitionId: 'comp_2',
      evolutionStage: 2,
    );
    expect(service.canEvolve(state), isTrue);

    const maxed = CompanionState(
      definitionId: 'comp_2',
      evolutionStage: 3,
    );
    expect(service.canEvolve(maxed), isFalse);
  });

  test('getEquippedCompanions returns equipped only', () {
    const system = CompanionSystemState(
      ownedCompanions: [
        CompanionState(definitionId: 'comp_1', equipped: true),
        CompanionState(definitionId: 'comp_2', equipped: false),
        CompanionState(definitionId: 'comp_3', equipped: true),
      ],
    );

    final equipped = service.getEquippedCompanions(system);
    expect(equipped.length, 2);
  });

  test('totalAutomationRate sums equipped automation rates', () {
    const system = CompanionSystemState(
      ownedCompanions: [
        CompanionState(definitionId: 'comp_1', equipped: true),
        CompanionState(definitionId: 'comp_3', equipped: true),
        CompanionState(definitionId: 'comp_2', equipped: false),
      ],
    );

    final rate = service.totalAutomationRate(system);
    expect(rate, closeTo(2.0, 0.01)); // 0.5 + 1.5
  });
}
