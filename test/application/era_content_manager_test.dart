import 'package:ai_evolution/application/services/era_content_manager.dart';
import 'package:ai_evolution/application/services/room_content_generator.dart';
import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/domain/models/era.dart';
import 'package:ai_evolution/domain/models/generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Era> eras;
  late List<GeneratorDefinition> baseGenerators;

  setUp(() {
    eras = [
      const Era(
        id: 'era_1',
        name: 'Junk Corner',
        description: 'First era',
        order: 1,
        currency: 'Scrap',
        rule: 'Taps stronger',
      ),
      const Era(
        id: 'era_2',
        name: 'Budget Setup',
        description: 'Second era',
        order: 2,
        unlockRequirement: 'gen_era_1:10',
        currency: 'Cash',
        rule: 'Combos',
      ),
      const Era(
        id: 'era_3',
        name: 'Creator Room',
        description: 'Third era',
        order: 3,
        unlockRequirement: 'gen_era_2:10',
        currency: 'Hype',
        rule: 'Viral',
      ),
    ];

    baseGenerators = [
      GeneratorDefinition(
        id: 'gen_era_1',
        name: 'Junk Core',
        description: 'Era 1 gen',
        eraId: 'era_1',
        baseCost: GameNumber.fromDouble(10),
        costGrowthRate: 1.15,
        baseProduction: GameNumber.fromDouble(1),
      ),
    ];
  });

  test('lazy loading loads only requested eras', () {
    final manager = EraContentManager(
      generator: const RoomContentGenerator(),
      eras: eras,
      baseGenerators: baseGenerators,
      baseUpgrades: const [],
    );

    expect(manager.isEraLoaded('era_1'), isFalse);
    expect(manager.isEraLoaded('era_2'), isFalse);

    manager.ensureEraLoaded('era_1');
    expect(manager.isEraLoaded('era_1'), isTrue);
    expect(manager.isEraLoaded('era_2'), isFalse);

    // Era 1 should have generated content
    final era1Upgrades = manager.upgrades.values
        .where((u) => u.eraId == 'era_1')
        .toList();
    expect(era1Upgrades.length, greaterThanOrEqualTo(100));
  });

  test('ensureErasAroundLoaded loads current and adjacent eras', () {
    final manager = EraContentManager(
      generator: const RoomContentGenerator(),
      eras: eras,
      baseGenerators: baseGenerators,
      baseUpgrades: const [],
    );

    manager.ensureErasAroundLoaded({'era_1'});
    expect(manager.isEraLoaded('era_1'), isTrue);
    expect(manager.isEraLoaded('era_2'), isTrue); // Next era preloaded
    expect(manager.isEraLoaded('era_3'), isFalse);
  });

  test('loading same era twice does not duplicate content', () {
    final manager = EraContentManager(
      generator: const RoomContentGenerator(),
      eras: eras,
      baseGenerators: baseGenerators,
      baseUpgrades: const [],
    );

    manager.ensureEraLoaded('era_1');
    final countBefore = manager.upgrades.length;

    manager.ensureEraLoaded('era_1');
    final countAfter = manager.upgrades.length;

    expect(countAfter, equals(countBefore));
  });

  test('loadAllEras loads all eras', () {
    final manager = EraContentManager(
      generator: const RoomContentGenerator(),
      eras: eras,
      baseGenerators: baseGenerators,
      baseUpgrades: const [],
    );

    manager.loadAllEras();
    expect(manager.isEraLoaded('era_1'), isTrue);
    expect(manager.isEraLoaded('era_2'), isTrue);
    expect(manager.isEraLoaded('era_3'), isTrue);
  });

  test('base generators are always available', () {
    final manager = EraContentManager(
      generator: const RoomContentGenerator(),
      eras: eras,
      baseGenerators: baseGenerators,
      baseUpgrades: const [],
    );

    // Before loading any era, base generators should be present
    expect(manager.generators.containsKey('gen_era_1'), isTrue);
  });

  test('RoomContentGenerator buildForEra produces 200 upgrades', () {
    const gen = RoomContentGenerator();
    final content = gen.buildForEra(
      era: eras.first,
      baseGenerators: baseGenerators,
    );
    expect(content.upgrades.length, 200);
    expect(content.generators.length, 1);
  });
}
