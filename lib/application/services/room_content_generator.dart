import 'dart:math' as math;

import '../../core/math/game_number.dart';
import '../../domain/models/era.dart';
import '../../domain/models/generator.dart';
import '../../domain/models/upgrade.dart';

class GeneratedRoomContent {
  final List<GeneratorDefinition> generators;
  final List<UpgradeDefinition> upgrades;

  const GeneratedRoomContent({
    required this.generators,
    required this.upgrades,
  });
}

class RoomContentGenerator {
  static const List<_BranchTemplate> _branches = [
    _BranchTemplate(
      id: 'tap',
      category: UpgradeCategory.tap,
      type: UpgradeType.tapMultiplier,
      branchName: 'Tap',
      costFactor: 0.86,
      growth: 1.085,
      effect: 1.055,
      startRequirement: 1,
    ),
    _BranchTemplate(
      id: 'automation',
      category: UpgradeCategory.automation,
      type: UpgradeType.productionMultiplier,
      branchName: 'Automation',
      costFactor: 0.96,
      growth: 1.09,
      effect: 1.05,
      startRequirement: 2,
    ),
    _BranchTemplate(
      id: 'room',
      category: UpgradeCategory.room,
      type: UpgradeType.generatorMultiplier,
      branchName: 'Room',
      costFactor: 1.08,
      growth: 1.092,
      effect: 1.06,
      startRequirement: 4,
    ),
    _BranchTemplate(
      id: 'ai',
      category: UpgradeCategory.ai,
      type: UpgradeType.tapMultiplier,
      branchName: 'AI',
      costFactor: 1.18,
      growth: 1.094,
      effect: 1.048,
      startRequirement: 6,
    ),
    _BranchTemplate(
      id: 'special',
      category: UpgradeCategory.special,
      type: UpgradeType.productionMultiplier,
      branchName: 'Special',
      costFactor: 1.36,
      growth: 1.1,
      effect: 1.08,
      startRequirement: 8,
    ),
  ];

  const RoomContentGenerator();

  GeneratedRoomContent build({
    required List<Era> eras,
    required List<GeneratorDefinition> baseGenerators,
  }) {
    final generators = <GeneratorDefinition>[];
    final upgrades = <UpgradeDefinition>[];
    final baseByEra = {for (final item in baseGenerators) item.eraId: item};

    for (final era in eras) {
      final seed = baseByEra[era.id];
      final generator = _buildGenerator(era, seed);
      generators.add(generator);
      upgrades.addAll(_buildRoomUpgrades(era, generator));
    }

    return GeneratedRoomContent(generators: generators, upgrades: upgrades);
  }

  GeneratorDefinition _buildGenerator(Era era, GeneratorDefinition? seed) {
    final order = era.order;
    final baseCostSeed = seed?.baseCost.toDouble() ?? math.pow(12, order).toDouble();
    final productionSeed =
        seed?.baseProduction.toDouble() ?? math.pow(5, order - 1).toDouble();
    final unlockLevel = order == 1 ? null : 'gen_era_${order - 1}:${16 + order}';
    return GeneratorDefinition(
      id: 'gen_${era.id}',
      name: '${era.name} Core',
      description:
          'Primary room engine for ${era.name}. ${era.rule} This room is designed as a long-form progression space.',
      eraId: era.id,
      baseCost: GameNumber.fromDouble(baseCostSeed * (3.8 + (order * 0.15))),
      costGrowthRate: 1.16 + (order * 0.0025),
      baseProduction: GameNumber.fromDouble(
        productionSeed * (1.4 + (order * 0.08)),
      ),
      unlockRequirement: unlockLevel,
    );
  }

  List<UpgradeDefinition> _buildRoomUpgrades(
    Era era,
    GeneratorDefinition generator,
  ) {
    final order = era.order;
    final themeToken = _themeToken(era.name);
    final upgrades = <UpgradeDefinition>[];

    for (final branch in _branches) {
      for (var tier = 1; tier <= 20; tier++) {
        final milestone = tier % 5 == 0;
        final maxLevel = branch.id == 'special'
            ? (milestone ? 1 : 3)
            : (milestone ? 2 : 5);
        final costScale = generator.baseCost.toDouble() *
            branch.costFactor *
            math.pow(1.32 + (order * 0.004), tier - 1).toDouble();
        final type = _upgradeTypeFor(branch, tier);
        final category = _categoryFor(branch, tier);
        final effect = _effectFor(branch, tier, order, milestone);
        upgrades.add(
          UpgradeDefinition(
            id: 'upg_${era.id}_${branch.id}_$tier',
            name: _upgradeName(themeToken, branch, tier, milestone),
            description:
                '${branch.branchName} lattice tier $tier for ${era.name}. ${era.rule}.',
            type: type,
            category: category,
            eraId: era.id,
            baseCost: GameNumber.fromDouble(costScale),
            costGrowthRate: branch.growth + (tier * 0.0035),
            maxLevel: maxLevel,
            effectPerLevel: GameNumber.fromDouble(effect),
            targetGeneratorId:
                type == UpgradeType.generatorMultiplier ? generator.id : null,
            unlockRequirement:
                _unlockRequirement(era: era, generator: generator, branch: branch, tier: tier),
          ),
        );
      }
    }

    return upgrades;
  }

  UpgradeType _upgradeTypeFor(_BranchTemplate branch, int tier) {
    if (branch.id != 'special') return branch.type;
    switch (tier % 3) {
      case 1:
        return UpgradeType.tapMultiplier;
      case 2:
        return UpgradeType.productionMultiplier;
      default:
        return UpgradeType.generatorMultiplier;
    }
  }

  UpgradeCategory _categoryFor(_BranchTemplate branch, int tier) {
    if (branch.id != 'special') return branch.category;
    return switch (tier % 4) {
      0 => UpgradeCategory.room,
      1 => UpgradeCategory.special,
      2 => UpgradeCategory.ai,
      _ => UpgradeCategory.automation,
    };
  }

  double _effectFor(
    _BranchTemplate branch,
    int tier,
    int order,
    bool milestone,
  ) {
    final base = branch.effect + (order * 0.0008) + (tier * 0.0004);
    if (milestone) return base + 0.025;
    if (branch.id == 'special') return base + 0.018;
    return base;
  }

  String _unlockRequirement({
    required Era era,
    required GeneratorDefinition generator,
    required _BranchTemplate branch,
    required int tier,
  }) {
    if (tier == 1) {
      return '${generator.id}:${branch.startRequirement}';
    }
    final previous = 'upg_${era.id}_${branch.id}_${tier - 1}:1';
    if (tier % 4 == 0) {
      return '${generator.id}:${math.min(24, branch.startRequirement + tier)}';
    }
    return previous;
  }

  String _themeToken(String name) {
    final normalized = name
        .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '')
        .trim()
        .split(RegExp(r'\s+'));
    if (normalized.isEmpty) return 'Room';
    return normalized.first;
  }

  String _upgradeName(
    String themeToken,
    _BranchTemplate branch,
    int tier,
    bool milestone,
  ) {
    final prefix = milestone ? 'Milestone' : branch.branchName;
    return '$themeToken $prefix Tier $tier';
  }
}

class _BranchTemplate {
  final String id;
  final UpgradeCategory category;
  final UpgradeType type;
  final String branchName;
  final double costFactor;
  final double growth;
  final double effect;
  final int startRequirement;

  const _BranchTemplate({
    required this.id,
    required this.category,
    required this.type,
    required this.branchName,
    required this.costFactor,
    required this.growth,
    required this.effect,
    required this.startRequirement,
  });
}
