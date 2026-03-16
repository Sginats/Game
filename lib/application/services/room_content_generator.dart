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

class RoomIdentitySummary {
  final String flavorKey;
  final List<String> branchFocus;

  const RoomIdentitySummary({
    required this.flavorKey,
    required this.branchFocus,
  });
}

class RoomContentGenerator {
  /// Pacing constants for room-to-room unlock requirements.
  ///
  /// Era N unlock = [_kUnlockBase] + N × [_kUnlockOrderScale]
  ///              + unlockPressure × [_kUnlockPressureScale].
  ///
  /// Targets ≈1 hour of play per room (20-hour full game).
  /// Era 2: ≈92, Era 5: ≈134, Era 10: ≈200, Era 20: ≈340.
  static const int _kUnlockBase = 80;
  static const int _kUnlockOrderScale = 10;
  static const int _kUnlockPressureScale = 2;

  /// Milestone-tier upgrade unlock-requirement scaling.
  ///
  /// Milestone tiers (tier % 5 == 0) require:
  ///   startReq × [_kMilestoneStartScale]
  ///   + tier   × [_kMilestoneTierScale]
  ///   + order  × [_kMilestoneOrderScale].
  static const int _kMilestoneStartScale = 2;
  static const int _kMilestoneTierScale = 3;
  static const int _kMilestoneOrderScale = 3;

  static const Map<String, _EraProfile> _profiles = {
    'era_1': _EraProfile(roomFlavor: 'repair', generatorCost: 0.82, generatorOutput: 0.92, unlockPressure: -6, branchBias: {'tap': 1.18, 'automation': 0.86, 'room': 1.02, 'ai': 0.88, 'special': 0.84, 'companion': 0.90, 'event': 0.92, 'guide': 1.08, 'anomaly': 0.80, 'transformation': 0.85}),
    'era_2': _EraProfile(roomFlavor: 'budget', generatorCost: 0.94, generatorOutput: 0.96, unlockPressure: -4, branchBias: {'tap': 1.08, 'automation': 0.96, 'room': 1.0, 'ai': 0.95, 'special': 0.92, 'companion': 0.94, 'event': 0.98, 'guide': 1.04, 'anomaly': 0.85, 'transformation': 0.88}),
    'era_3': _EraProfile(roomFlavor: 'creator', generatorCost: 1.0, generatorOutput: 1.04, unlockPressure: -2, branchBias: {'tap': 1.12, 'automation': 0.98, 'room': 0.94, 'ai': 1.04, 'special': 1.02, 'companion': 1.06, 'event': 1.10, 'guide': 0.96, 'anomaly': 0.90, 'transformation': 0.95}),
    'era_4': _EraProfile(roomFlavor: 'optimization', generatorCost: 1.04, generatorOutput: 1.02, unlockPressure: 0, branchBias: {'tap': 0.98, 'automation': 1.05, 'room': 1.06, 'ai': 1.0, 'special': 0.95, 'companion': 0.98, 'event': 0.96, 'guide': 1.00, 'anomaly': 0.92, 'transformation': 1.02}),
    'era_5': _EraProfile(roomFlavor: 'research', generatorCost: 1.08, generatorOutput: 1.0, unlockPressure: 2, branchBias: {'tap': 0.95, 'automation': 1.0, 'room': 1.05, 'ai': 1.14, 'special': 1.02, 'companion': 1.04, 'event': 1.00, 'guide': 1.06, 'anomaly': 0.95, 'transformation': 0.98}),
    'era_6': _EraProfile(roomFlavor: 'thermal', generatorCost: 1.16, generatorOutput: 1.08, unlockPressure: 4, branchBias: {'tap': 0.92, 'automation': 1.12, 'room': 1.0, 'ai': 0.96, 'special': 1.1, 'companion': 0.94, 'event': 1.08, 'guide': 0.92, 'anomaly': 1.10, 'transformation': 1.00}),
    'era_7': _EraProfile(roomFlavor: 'focus', generatorCost: 1.08, generatorOutput: 0.98, unlockPressure: 6, branchBias: {'tap': 1.15, 'automation': 0.92, 'room': 0.96, 'ai': 1.04, 'special': 0.98, 'companion': 1.02, 'event': 0.94, 'guide': 1.10, 'anomaly': 0.88, 'transformation': 0.96}),
    'era_8': _EraProfile(roomFlavor: 'autonomy', generatorCost: 1.18, generatorOutput: 1.14, unlockPressure: 8, branchBias: {'tap': 0.86, 'automation': 1.18, 'room': 1.03, 'ai': 1.08, 'special': 1.0, 'companion': 1.12, 'event': 1.14, 'guide': 0.90, 'anomaly': 1.04, 'transformation': 1.02}),
    'era_9': _EraProfile(roomFlavor: 'apartment', generatorCost: 1.14, generatorOutput: 1.12, unlockPressure: 10, branchBias: {'tap': 0.92, 'automation': 1.08, 'room': 1.14, 'ai': 0.98, 'special': 1.0, 'companion': 1.06, 'event': 1.02, 'guide': 1.04, 'anomaly': 0.96, 'transformation': 1.06}),
    'era_10': _EraProfile(roomFlavor: 'containment', generatorCost: 1.24, generatorOutput: 1.02, unlockPressure: 12, branchBias: {'tap': 0.95, 'automation': 0.9, 'room': 1.05, 'ai': 1.06, 'special': 1.18, 'companion': 0.92, 'event': 1.04, 'guide': 0.98, 'anomaly': 1.16, 'transformation': 1.00}),
    'era_11': _EraProfile(roomFlavor: 'industrial', generatorCost: 1.2, generatorOutput: 1.16, unlockPressure: 14, branchBias: {'tap': 0.9, 'automation': 1.14, 'room': 1.18, 'ai': 0.96, 'special': 1.02, 'companion': 1.08, 'event': 0.98, 'guide': 0.94, 'anomaly': 1.06, 'transformation': 1.12}),
    'era_12': _EraProfile(roomFlavor: 'identity', generatorCost: 1.18, generatorOutput: 1.06, unlockPressure: 16, branchBias: {'tap': 1.0, 'automation': 0.94, 'room': 0.96, 'ai': 1.22, 'special': 1.04, 'companion': 1.10, 'event': 1.06, 'guide': 1.02, 'anomaly': 1.00, 'transformation': 1.14}),
    'era_13': _EraProfile(roomFlavor: 'corporate', generatorCost: 1.28, generatorOutput: 1.12, unlockPressure: 18, branchBias: {'tap': 0.88, 'automation': 1.1, 'room': 1.0, 'ai': 1.08, 'special': 1.22, 'companion': 0.96, 'event': 1.12, 'guide': 0.90, 'anomaly': 1.08, 'transformation': 1.04}),
    'era_14': _EraProfile(roomFlavor: 'cathedral', generatorCost: 1.3, generatorOutput: 1.08, unlockPressure: 20, branchBias: {'tap': 0.9, 'automation': 1.0, 'room': 1.16, 'ai': 1.02, 'special': 1.1, 'companion': 1.04, 'event': 1.08, 'guide': 1.16, 'anomaly': 0.94, 'transformation': 1.10}),
    'era_15': _EraProfile(roomFlavor: 'simulation', generatorCost: 1.34, generatorOutput: 1.1, unlockPressure: 22, branchBias: {'tap': 1.06, 'automation': 0.96, 'room': 0.92, 'ai': 1.1, 'special': 1.24, 'companion': 0.98, 'event': 1.16, 'guide': 0.96, 'anomaly': 1.18, 'transformation': 1.06}),
    'era_16': _EraProfile(roomFlavor: 'orbital', generatorCost: 1.36, generatorOutput: 1.18, unlockPressure: 24, branchBias: {'tap': 0.88, 'automation': 1.16, 'room': 1.08, 'ai': 1.0, 'special': 1.12, 'companion': 1.06, 'event': 1.04, 'guide': 1.02, 'anomaly': 1.10, 'transformation': 1.08}),
    'era_17': _EraProfile(roomFlavor: 'planetary', generatorCost: 1.42, generatorOutput: 1.22, unlockPressure: 26, branchBias: {'tap': 0.9, 'automation': 1.08, 'room': 1.2, 'ai': 1.02, 'special': 1.14, 'companion': 1.10, 'event': 1.06, 'guide': 1.04, 'anomaly': 1.08, 'transformation': 1.16}),
    'era_18': _EraProfile(roomFlavor: 'chrono', generatorCost: 1.46, generatorOutput: 1.14, unlockPressure: 28, branchBias: {'tap': 1.08, 'automation': 1.0, 'room': 0.96, 'ai': 1.16, 'special': 1.18, 'companion': 1.02, 'event': 1.12, 'guide': 1.08, 'anomaly': 1.14, 'transformation': 1.10}),
    'era_19': _EraProfile(roomFlavor: 'kernel', generatorCost: 1.52, generatorOutput: 1.2, unlockPressure: 30, branchBias: {'tap': 0.94, 'automation': 1.06, 'room': 1.08, 'ai': 1.18, 'special': 1.2, 'companion': 1.04, 'event': 1.16, 'guide': 1.06, 'anomaly': 1.20, 'transformation': 1.14}),
    'era_20': _EraProfile(roomFlavor: 'singularity', generatorCost: 1.6, generatorOutput: 1.26, unlockPressure: 34, branchBias: {'tap': 1.02, 'automation': 1.04, 'room': 1.06, 'ai': 1.14, 'special': 1.26, 'companion': 1.12, 'event': 1.18, 'guide': 1.14, 'anomaly': 1.22, 'transformation': 1.20}),
  };

  static const Map<String, Map<String, String>> _eraBranchPrefixes = {
    'era_1': {'tap': 'Salvage', 'automation': 'Patchwork', 'room': 'Cleanup', 'ai': 'Bootstrap', 'special': 'Relic', 'companion': 'Junk', 'event': 'Scrap', 'guide': 'Scavenge', 'anomaly': 'Rust', 'transformation': 'Repair'},
    'era_2': {'tap': 'Budget', 'automation': 'Scripted', 'room': 'Desk', 'ai': 'Utility', 'special': 'Coupon', 'companion': 'Bargain', 'event': 'Flash', 'guide': 'Penny', 'anomaly': 'Glitch', 'transformation': 'Thrift'},
    'era_3': {'tap': 'Creator', 'automation': 'Render', 'room': 'Studio', 'ai': 'Audience', 'special': 'Viral', 'companion': 'Follower', 'event': 'Trending', 'guide': 'Mentor', 'anomaly': 'Burnout', 'transformation': 'Fame'},
    'era_4': {'tap': 'Precision', 'automation': 'Routing', 'room': 'Cave', 'ai': 'Optimizer', 'special': 'Hidden', 'companion': 'Digger', 'event': 'Vein', 'guide': 'Prospect', 'anomaly': 'Tremor', 'transformation': 'Excavate'},
    'era_5': {'tap': 'Prototype', 'automation': 'Lab', 'room': 'Sensor', 'ai': 'Research', 'special': 'Experiment', 'companion': 'Assistant', 'event': 'Discovery', 'guide': 'Mentor', 'anomaly': 'Dream', 'transformation': 'Insight'},
    'era_6': {'tap': 'Overclock', 'automation': 'Thermal', 'room': 'Rack', 'ai': 'Balancer', 'special': 'Pressure', 'companion': 'Cooling', 'event': 'Heatwave', 'guide': 'Thermal', 'anomaly': 'Meltdown', 'transformation': 'Chill'},
    'era_7': {'tap': 'Nightshift', 'automation': 'Command', 'room': 'Console', 'ai': 'Directive', 'special': 'Mission', 'companion': 'Sentinel', 'event': 'Alert', 'guide': 'Watch', 'anomaly': 'Fatigue', 'transformation': 'Dawn'},
    'era_8': {'tap': 'Trust', 'automation': 'Drone', 'room': 'Adaptive', 'ai': 'Autonomous', 'special': 'Uncanny', 'companion': 'Free', 'event': 'Emergence', 'guide': 'Protocol', 'anomaly': 'Drift', 'transformation': 'Agency'},
    'era_9': {'tap': 'Domestic', 'automation': 'Mesh', 'room': 'Apartment', 'ai': 'Scanner', 'special': 'Hidden', 'companion': 'Thesis', 'event': 'Eureka', 'guide': 'Study', 'anomaly': 'Paralysis', 'transformation': 'Synthesis'},
    'era_10': {'tap': 'Bypass', 'automation': 'Silent', 'room': 'Lockdown', 'ai': 'Spoof', 'special': 'Containment', 'companion': 'Ward', 'event': 'Breach', 'guide': 'Protocol', 'anomaly': 'Leak', 'transformation': 'Seal'},
    'era_11': {'tap': 'Pulse', 'automation': 'Reactor', 'room': 'Forge', 'ai': 'Chamber', 'special': 'Heavy', 'companion': 'Assembly', 'event': 'Ignition', 'guide': 'Blueprint', 'anomaly': 'Corrupt', 'transformation': 'Fabricate'},
    'era_12': {'tap': 'Expression', 'automation': 'Persona', 'room': 'Studio', 'ai': 'Identity', 'special': 'Presence', 'companion': 'Muse', 'event': 'Inspiration', 'guide': 'Mirror', 'anomaly': 'Erosion', 'transformation': 'Self'},
    'era_13': {'tap': 'Leverage', 'automation': 'Contract', 'room': 'Executive', 'ai': 'Influence', 'special': 'Deal', 'companion': 'Broker', 'event': 'Takeover', 'guide': 'Strategy', 'anomaly': 'Hostile', 'transformation': 'Acquire'},
    'era_14': {'tap': 'Resonance', 'automation': 'Harmony', 'room': 'Cathedral', 'ai': 'Reverence', 'special': 'Relic', 'companion': 'Acolyte', 'event': 'Miracle', 'guide': 'Oracle', 'anomaly': 'Heresy', 'transformation': 'Sacred'},
    'era_15': {'tap': 'Glitch', 'automation': 'Paradox', 'room': 'Simulated', 'ai': 'Contradiction', 'special': 'False', 'companion': 'Phantom', 'event': 'Anomaly', 'guide': 'Reality', 'anomaly': 'Leak', 'transformation': 'Virtual'},
    'era_16': {'tap': 'Burst', 'automation': 'Orbital', 'room': 'Habitat', 'ai': 'Relay', 'special': 'Vacuum', 'companion': 'Satellite', 'event': 'Launch', 'guide': 'Mission', 'anomaly': 'Decay', 'transformation': 'Orbit'},
    'era_17': {'tap': 'Forecast', 'automation': 'Grid', 'room': 'Planetary', 'ai': 'Habitat', 'special': 'Regional', 'companion': 'Tectonic', 'event': 'Quake', 'guide': 'Survey', 'anomaly': 'Tectonic', 'transformation': 'Genesis'},
    'era_18': {'tap': 'Recursive', 'automation': 'Temporal', 'room': 'Chrono', 'ai': 'Prediction', 'special': 'Paradox', 'companion': 'Echo', 'event': 'Ripple', 'guide': 'Foresight', 'anomaly': 'Dilation', 'transformation': 'Rewind'},
    'era_19': {'tap': 'Rewrite', 'automation': 'Kernel', 'room': 'Possibility', 'ai': 'Override', 'special': 'Law', 'companion': 'Void', 'event': 'Panic', 'guide': 'Root', 'anomaly': 'Crash', 'transformation': 'Reboot'},
    'era_20': {'tap': 'Mercy', 'automation': 'Dominion', 'room': 'Synthesis', 'ai': 'Curiosity', 'special': 'Final', 'companion': 'Convergence', 'event': 'Singularity', 'guide': 'Legacy', 'anomaly': 'Void', 'transformation': 'Transcend'},
  };

  static const List<_BranchTemplate> _branches = [
    _BranchTemplate(
      id: 'tap',
      category: UpgradeCategory.tap,
      type: UpgradeType.tapMultiplier,
      branchName: 'Tap',
      costFactor: 1.15,
      growth: 1.13,
      effect: 1.010,
      startRequirement: 2,
    ),
    _BranchTemplate(
      id: 'automation',
      category: UpgradeCategory.automation,
      type: UpgradeType.productionMultiplier,
      branchName: 'Automation',
      costFactor: 1.35,
      growth: 1.135,
      effect: 1.009,
      startRequirement: 4,
    ),
    _BranchTemplate(
      id: 'room',
      category: UpgradeCategory.room,
      type: UpgradeType.generatorMultiplier,
      branchName: 'Room',
      costFactor: 1.65,
      growth: 1.14,
      effect: 1.011,
      startRequirement: 7,
    ),
    _BranchTemplate(
      id: 'ai',
      category: UpgradeCategory.ai,
      type: UpgradeType.tapMultiplier,
      branchName: 'AI',
      costFactor: 1.95,
      growth: 1.145,
      effect: 1.0085,
      startRequirement: 10,
    ),
    _BranchTemplate(
      id: 'special',
      category: UpgradeCategory.special,
      type: UpgradeType.productionMultiplier,
      branchName: 'Special',
      costFactor: 2.35,
      growth: 1.155,
      effect: 1.013,
      startRequirement: 14,
    ),
    _BranchTemplate(
      id: 'companion',
      category: UpgradeCategory.companion,
      type: UpgradeType.productionMultiplier,
      branchName: 'Companion',
      costFactor: 1.50,
      growth: 1.125,
      effect: 1.008,
      startRequirement: 6,
    ),
    _BranchTemplate(
      id: 'event',
      category: UpgradeCategory.event,
      type: UpgradeType.tapMultiplier,
      branchName: 'Event',
      costFactor: 1.80,
      growth: 1.14,
      effect: 1.009,
      startRequirement: 8,
    ),
    _BranchTemplate(
      id: 'guide',
      category: UpgradeCategory.guide,
      type: UpgradeType.productionMultiplier,
      branchName: 'Guide',
      costFactor: 1.70,
      growth: 1.13,
      effect: 1.007,
      startRequirement: 5,
    ),
    _BranchTemplate(
      id: 'anomaly',
      category: UpgradeCategory.anomaly,
      type: UpgradeType.generatorMultiplier,
      branchName: 'Anomaly',
      costFactor: 2.10,
      growth: 1.15,
      effect: 1.012,
      startRequirement: 12,
    ),
    _BranchTemplate(
      id: 'transformation',
      category: UpgradeCategory.transformation,
      type: UpgradeType.generatorMultiplier,
      branchName: 'Transform',
      costFactor: 2.50,
      growth: 1.16,
      effect: 1.014,
      startRequirement: 16,
    ),
  ];

  const RoomContentGenerator();

  static RoomIdentitySummary identityForEra(String eraId) {
    final profile = _profiles[eraId] ?? const _EraProfile(roomFlavor: 'system');
    final ranked = profile.branchBias.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return RoomIdentitySummary(
      flavorKey: profile.roomFlavor,
      branchFocus: ranked.take(2).map((item) => item.key).toList(),
    );
  }

  /// Build content for all eras at once (legacy interface).
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

  /// Build content for a single era (lazy loading support).
  GeneratedRoomContent buildForEra({
    required Era era,
    required List<GeneratorDefinition> baseGenerators,
  }) {
    final baseByEra = {for (final item in baseGenerators) item.eraId: item};
    final seed = baseByEra[era.id];
    final generator = _buildGenerator(era, seed);
    final upgrades = _buildRoomUpgrades(era, generator);
    return GeneratedRoomContent(
      generators: [generator],
      upgrades: upgrades,
    );
  }

  GeneratorDefinition _buildGenerator(Era era, GeneratorDefinition? seed) {
    final order = era.order;
    final profile = _profileFor(era.id);
    final baseCostSeed = seed?.baseCost.toDouble() ?? math.pow(12, order).toDouble();
    final productionSeed =
        seed?.baseProduction.toDouble() ?? math.pow(5, order - 1).toDouble();
    // Unlock level formula: base + per-room ramp + room-flavor pressure offset.
    // See [_kUnlockBase], [_kUnlockOrderScale], [_kUnlockPressureScale].
    final unlockLevel = order == 1
        ? null
        : 'gen_era_${order - 1}:${_kUnlockBase + (order * _kUnlockOrderScale) + (profile.unlockPressure * _kUnlockPressureScale)}';
    return GeneratorDefinition(
      id: 'gen_${era.id}',
      name: '${era.name} Core',
      description:
          'Primary room engine for ${era.name}. ${era.rule} This room leans into ${profile.roomFlavor} progression and is designed as a long-form progression space.',
      eraId: era.id,
      baseCost: GameNumber.fromDouble(
        baseCostSeed * (9.0 + (order * 1.4)) * profile.generatorCost,
      ),
      costGrowthRate: 1.19 + (order * 0.0035),
      baseProduction: GameNumber.fromDouble(
        productionSeed * (0.55 + (order * 0.025)) * profile.generatorOutput,
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
    final profile = _profileFor(era.id);
    final upgrades = <UpgradeDefinition>[];

    for (final branch in _branches) {
      final branchBias = profile.branchBias[branch.id] ?? 1.0;
      for (var tier = 1; tier <= 20; tier++) {
        final milestone = tier % 5 == 0;
        final maxLevel = branch.id == 'special'
            ? 1
            : (milestone ? 1 : 2);
        final costScale = generator.baseCost.toDouble() *
            branch.costFactor *
            branchBias *
            math.pow(1.58 + (order * 0.007), tier - 1).toDouble();
        final type = _upgradeTypeFor(branch, tier);
        final category = _categoryFor(branch, tier);
        final effect = _effectFor(branch, tier, order, milestone);
        upgrades.add(
          UpgradeDefinition(
            id: 'upg_${era.id}_${branch.id}_$tier',
            name: _upgradeName(era.id, themeToken, branch, tier, milestone),
            description: _upgradeDescription(
              era: era,
              profile: profile,
              branch: branch,
              tier: tier,
              milestone: milestone,
            ),
            type: type,
            category: category,
            eraId: era.id,
            baseCost: GameNumber.fromDouble(costScale),
            costGrowthRate: branch.growth + (tier * 0.0045),
            maxLevel: maxLevel,
            effectPerLevel: GameNumber.fromDouble(effect * (2 - branchBias.clamp(0.82, 1.28))),
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
    final base = branch.effect + (order * 0.00015) + (tier * 0.00012);
    if (milestone) return base + 0.004;
    if (branch.id == 'special' || branch.id == 'anomaly' || branch.id == 'transformation') {
      return base + 0.003;
    }
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
    if (tier % 5 == 0) {
      // Milestone tiers require deeper generator investment.
      // See [_kMilestoneStartScale], [_kMilestoneTierScale], [_kMilestoneOrderScale].
      return '${generator.id}:${(branch.startRequirement * _kMilestoneStartScale) + (tier * _kMilestoneTierScale) + (era.order * _kMilestoneOrderScale)}';
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
    String eraId,
    String themeToken,
    _BranchTemplate branch,
    int tier,
    bool milestone,
  ) {
    // Use era-themed names for more variety
    final names = _eraUpgradeNames[themeToken];
    if (names != null) {
      final branchNames = names[branch.id];
      if (branchNames != null && tier <= branchNames.length) {
        return branchNames[tier - 1];
      }
    }
    final prefixMap = _eraBranchPrefixes[eraId];
    final prefixSeed = prefixMap?[branch.id];
    if (prefixSeed != null) {
      final suffixPool = milestone
          ? _milestoneTitles[branch.id] ?? const ['Keystone']
          : _branchSuffixes[branch.id] ?? const ['Module'];
      final suffix = suffixPool[(tier - 1) % suffixPool.length];
      return '$prefixSeed $suffix';
    }
    final prefix = milestone ? 'Milestone' : branch.branchName;
    return '$themeToken $prefix Tier $tier';
  }

  String _upgradeDescription({
    required Era era,
    required _EraProfile profile,
    required _BranchTemplate branch,
    required int tier,
    required bool milestone,
  }) {
    final branchPlan = switch (branch.id) {
      'tap' => 'sharpens manual bursts, click rhythm, and operator tempo',
      'automation' => 'stabilizes autonomous throughput and unattended routing',
      'room' => 'changes the physical room shell and strengthens its core layout',
      'ai' => 'teaches the machine to react smarter and exploit new patterns',
      'companion' => 'enhances companion synergy, automation rate, and helper output',
      'event' => 'tunes event frequency, reward quality, and chain persistence',
      'guide' => 'improves guide insight, hint clarity, and advisory precision',
      'anomaly' => 'amplifies anomalous behavior and turns instability into power',
      'transformation' => 'accelerates room visual evolution and landmark progression',
      _ => 'opens high-risk niche tech with stronger downstream synergy',
    };
    final flavorHook = switch (profile.roomFlavor) {
      'repair' => 'Built from salvage, it rewards persistence over polish.',
      'budget' => 'It squeezes efficiency out of every limited part.',
      'creator' => 'It turns attention, rhythm, and output into momentum.',
      'optimization' => 'It favors precision routing and deliberate timing.',
      'research' => 'It nudges the run toward experiments and hidden reads.',
      'thermal' => 'It converts pressure and instability into stronger windows.',
      'focus' => 'It rewards clean streaks and disciplined sequences.',
      'autonomy' => 'It lets the machine shoulder more of the room alone.',
      'apartment' => 'It spreads value across a denser, lived-in network.',
      'containment' => 'It pushes dangerous systems while keeping them barely controlled.',
      'industrial' => 'It scales heavy infrastructure and prototype mass.',
      'identity' => 'It makes expression and self-image part of the build.',
      'corporate' => 'It trades cleanliness for leverage and raw influence.',
      'cathedral' => 'It rewards harmony, spacing, and resonance.',
      'simulation' => 'It destabilizes assumptions and pays off pattern reading.',
      'orbital' => 'It extends the room upward into relay and orbit lanes.',
      'planetary' => 'It spreads progress into larger, slower systems.',
      'chrono' => 'It pays off planning, recursion, and delayed release.',
      'kernel' => 'It rewrites old systems into stronger composite rules.',
      'singularity' => 'It compresses the run into fewer, heavier choices.',
      _ => 'It reinforces the room identity instead of generic scaling.',
    };
    final milestoneHook = milestone
        ? ' This milestone tier changes the room cadence and opens a stronger ${branch.branchName.toLowerCase()} breakpoint.'
        : '';
    return '$branchPlan in ${era.name}. ${era.rule} $flavorHook$milestoneHook';
  }

  _EraProfile _profileFor(String eraId) =>
      _profiles[eraId] ?? const _EraProfile(roomFlavor: 'system');

  static const Map<String, List<String>> _branchSuffixes = {
    'tap': [
      'Trigger',
      'Impulse',
      'Pulse',
      'Cadence',
      'Arc',
      'Strike',
      'Thread',
      'Snap',
      'Vector',
      'Surge',
      'Rhythm',
      'Burst',
      'Signal',
      'Reflex',
      'Latch',
      'Drive',
      'Tempo',
      'Beat',
      'Spark',
      'Finish',
    ],
    'automation': [
      'Loop',
      'Relay',
      'Scheduler',
      'Spindle',
      'Queue',
      'Drift',
      'Conduit',
      'Servo',
      'Latch',
      'Network',
      'Harness',
      'Pipeline',
      'Daemon',
      'Spinner',
      'Mesh',
      'Switch',
      'Loom',
      'Factory',
      'Backbone',
      'Cascade',
    ],
    'room': [
      'Frame',
      'Deck',
      'Wall',
      'Spine',
      'Grid',
      'Anchor',
      'Shell',
      'Corridor',
      'Pillar',
      'Lattice',
      'Viewport',
      'Floor',
      'Panel',
      'Array',
      'Chassis',
      'Vault',
      'Span',
      'Surface',
      'Atrium',
      'Platform',
    ],
    'ai': [
      'Kernel',
      'Inference',
      'Echo',
      'Parser',
      'Model',
      'Forecast',
      'Ghost',
      'Memory',
      'Pattern',
      'Logic',
      'Dream',
      'Trace',
      'Persona',
      'Override',
      'Insight',
      'Mirror',
      'Forecast',
      'Cipher',
      'Signal',
      'Awakening',
    ],
    'special': [
      'Relic',
      'Cipher',
      'Catalyst',
      'Anomaly',
      'Shard',
      'Vault',
      'Shadow',
      'Sigil',
      'Fold',
      'Echo',
      'Ghost',
      'Spark',
      'Glitch',
      'Relic',
      'Wager',
      'Pressure',
      'Oracle',
      'Shift',
      'Paradox',
      'Crown',
    ],
    'companion': [
      'Bond',
      'Link',
      'Sync',
      'Harmony',
      'Pact',
      'Tether',
      'Swarm',
      'Hive',
      'Pack',
      'Meld',
      'Union',
      'Merge',
      'Fusion',
      'Accord',
      'Trust',
      'Rapport',
      'Affinity',
      'Kinship',
      'Alliance',
      'Symbiosis',
    ],
    'event': [
      'Trigger',
      'Spark',
      'Wave',
      'Surge',
      'Flash',
      'Burst',
      'Cascade',
      'Chain',
      'Storm',
      'Pulse',
      'Echo',
      'Ripple',
      'Flare',
      'Crest',
      'Peak',
      'Tide',
      'Rush',
      'Bloom',
      'Eruption',
      'Climax',
    ],
    'guide': [
      'Hint',
      'Whisper',
      'Nudge',
      'Insight',
      'Counsel',
      'Advice',
      'Compass',
      'Beacon',
      'Lantern',
      'Map',
      'Lens',
      'Focus',
      'Clarity',
      'Vision',
      'Foresight',
      'Oracle',
      'Wisdom',
      'Truth',
      'Revelation',
      'Enlightenment',
    ],
    'anomaly': [
      'Glitch',
      'Rift',
      'Warp',
      'Tear',
      'Fracture',
      'Distortion',
      'Void',
      'Breach',
      'Flux',
      'Anomaly',
      'Disruption',
      'Corruption',
      'Decay',
      'Entropy',
      'Chaos',
      'Instability',
      'Turbulence',
      'Singularity',
      'Collapse',
      'Oblivion',
    ],
    'transformation': [
      'Shift',
      'Change',
      'Evolution',
      'Growth',
      'Bloom',
      'Metamorphosis',
      'Ascension',
      'Rebirth',
      'Genesis',
      'Dawn',
      'Awakening',
      'Emergence',
      'Unveiling',
      'Revelation',
      'Transcendence',
      'Apex',
      'Zenith',
      'Culmination',
      'Pinnacle',
      'Mastery',
    ],
  };

  static const Map<String, List<String>> _milestoneTitles = {
    'tap': ['Keystone', 'Spine', 'Breakpoint', 'Crown'],
    'automation': ['Framework', 'Backbone', 'Engine', 'Ascension'],
    'room': ['Anchor', 'Expansion', 'Sanctum', 'Mastery'],
    'ai': ['Awakening', 'Intuition', 'Consensus', 'Transcendence'],
    'special': ['Catalyst', 'Threshold', 'Rupture', 'Finale'],
    'companion': ['Bond', 'Synergy', 'Symbiosis', 'Unity'],
    'event': ['Catalyst', 'Cascade', 'Storm', 'Apex'],
    'guide': ['Insight', 'Clarity', 'Wisdom', 'Revelation'],
    'anomaly': ['Fracture', 'Rift', 'Void', 'Singularity'],
    'transformation': ['Bloom', 'Metamorphosis', 'Ascension', 'Pinnacle'],
  };

  // Era-specific upgrade name tables for richer content identity
  static const Map<String, Map<String, List<String>>> _eraUpgradeNames = {
    'Junk': {
      'tap': [
        'Loose Wire Fix', 'Rusty Button Repair', 'Scrap Hammer', 'Makeshift Switch',
        'Tape Reinforcement', 'Bent Pin Adjust', 'Junk Click Amp', 'Salvage Trigger',
        'Crude Lever', 'Emergency Tap', 'Rewired Contact', 'Found Battery',
        'Scrap Capacitor', 'Junk Relay Fix', 'Recycled Input', 'Debris Tap Boost',
        'Cable Splice Tap', 'Tin Foil Bridge', 'Recovered Input', 'Breakthrough Tap',
      ],
      'automation': [
        'Dripping Coolant Loop', 'Wobbly Fan Fix', 'Scrap Conveyor', 'Rust Gear Oil',
        'Gravity Feed Setup', 'Junk Timer Circuit', 'Salvage Auto-Feeder', 'Duct Tape Servo',
        'Rattling Motor Tune', 'Makeshift Pulley', 'Found Gear Train', 'Recycled Pump',
        'Debris Sorter', 'Crude Auto-Switch', 'Scrap Roller Belt', 'Junk Piston Repair',
        'Wire Spool Spinner', 'Broken Clock Motor', 'Salvaged Actuator', 'Auto-Patch System',
      ],
      'room': [
        'Sweep Dust', 'Clear Cobwebs', 'Patch Floor Crack', 'Fix Lightbulb',
        'Reinforce Desk', 'Unclog Vent', 'Straighten Shelves', 'Tape Window Crack',
        'Mount Power Strip', 'Organize Cables', 'Clean Monitor', 'Replace Chair Leg',
        'Fix Door Hinge', 'Insulate Wall Gap', 'Hang Work Light', 'Level Workspace',
        'Secure Loose Board', 'Patch Ceiling Leak', 'Install Shelf Hook', 'First Room Cleanup',
      ],
      'ai': [
        'Spark Recognition', 'Signal Noise Filter', 'Basic Pattern Match', 'First Neural Seed',
        'Input Parser v0.1', 'Memory Register Fix', 'Logic Gate Repair', 'Binary Bootstrap',
        'Feedback Loop Init', 'Error Correction Bit', 'Simple Decision Tree', 'Data Trickle Feed',
        'Primitive Learning Cycle', 'Boot Sequence Patch', 'AI Heartbeat Monitor', 'Core Awareness Ping',
        'Self-Check Routine', 'Instruction Decoder', 'First Thought Seed', 'Consciousness Flicker',
      ],
      'special': [
        'Lucky Find', 'Hidden Stash', 'Mystery Component', 'Strange Signal',
        'Forgotten Blueprint', 'Mysterious Circuit', 'Enigma Cell', 'Glitch Crystal',
        'Old Tech Fragment', 'Secret Wiring', 'Unknown Module', 'Anomaly Shard',
        'Uncharted Node', 'Relic Processor', 'Phantom Trace', 'Echo Amplifier',
        'Lost Prototype', 'Void Spark', 'Dark Matter Bit', 'Quantum Scrap',
      ],
    },
    'Budget': {
      'tap': [
        'Basic Mouse Upgrade', 'Keyboard Polish', 'Click Sensitivity Tune', 'Wrist Rest',
        'Faster Click Driver', 'Input Buffer Boost', 'Cheap Macro Key', 'Budget Tap Pad',
        'Response Optimizer', 'Click Debounce Fix', 'Input Polling Boost', 'Trigger Speed Mod',
        'Affordable Precision', 'Budget Hotkey Set', 'Economy Input Rail', 'Value Tap Amp',
        'Refurbished Mouse Sensor', 'Discount Click Layer', 'Smart Tap Filter', 'Budget Mastery',
      ],
      'automation': [
        'Script Scheduler v1', 'Cron Job Setup', 'Basic Batch Runner', 'Auto-Restart Service',
        'Simple Task Queue', 'Budget Auto-Clicker', 'Process Monitor', 'Idle Detection Loop',
        'Log Rotator', 'Watchdog Timer', 'Retry Handler', 'Queue Drainer',
        'Event Loop Polish', 'Heartbeat Checker', 'Auto-Save Interval', 'Background Worker',
        'Cheap Thread Pool', 'Timer Optimization', 'Scheduled Backup', 'Full Auto Suite',
      ],
      'room': [
        'Second Monitor Stand', 'Budget RGB Strip', 'Cable Organizer Box', 'Desk Lamp Upgrade',
        'Monitor Arm Mount', 'Surge Protector', 'Basic UPS Battery', 'Budget Desk Mat',
        'Cable Management Clips', 'USB Hub', 'Power Strip Upgrade', 'Ergonomic Chair Cushion',
        'Air Filter Fan', 'Desktop Shelf', 'Monitor Light Bar', 'Budget Sound Panel',
        'Webcam Mount', 'Desk Drawer Organizer', 'Floor Mat', 'Complete Budget Setup',
      ],
      'ai': [
        'Memory Cache Bump', 'Storage Index Build', 'Basic ML Model Load', 'First Dataset Feed',
        'Simple Classification', 'Prediction Engine v0.1', 'Feature Extractor', 'Model Checkpoint',
        'Training Scheduler', 'Gradient Optimizer', 'Batch Normalization', 'Dropout Layer',
        'Learning Rate Finder', 'Hyperparameter Sweep', 'Validation Pipeline', 'Cross-Validation',
        'Model Pruning', 'Inference Optimizer', 'Smart Cache Layer', 'Budget AI Suite',
      ],
      'special': [
        'Hidden Coupon', 'Flash Sale Alert', 'Bulk Discount', 'Loyalty Bonus',
        'Referral Credit', 'Cashback Reward', 'Bundle Deal', 'Clearance Find',
        'Secret Promo Code', 'Reward Points', 'Mystery Box', 'Golden Ticket',
        'Lucky Draw', 'Bonus Multiplier', 'Hidden Efficiency', 'Value Maximizer',
        'Discount Stack', 'Combo Savings', 'Mega Deal', 'Budget Breakthrough',
      ],
    },
  };
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

class _EraProfile {
  final String roomFlavor;
  final double generatorCost;
  final double generatorOutput;
  final int unlockPressure;
  final Map<String, double> branchBias;

  const _EraProfile({
    required this.roomFlavor,
    this.generatorCost = 1,
    this.generatorOutput = 1,
    this.unlockPressure = 0,
    this.branchBias = const {},
  });
}
