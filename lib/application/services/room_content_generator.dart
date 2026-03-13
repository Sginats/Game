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
  static const Map<String, _EraProfile> _profiles = {
    'era_1': _EraProfile(roomFlavor: 'repair', generatorCost: 0.82, generatorOutput: 0.92, unlockPressure: -6, branchBias: {'tap': 1.18, 'automation': 0.86, 'room': 1.02, 'ai': 0.88, 'special': 0.84}),
    'era_2': _EraProfile(roomFlavor: 'budget', generatorCost: 0.94, generatorOutput: 0.96, unlockPressure: -4, branchBias: {'tap': 1.08, 'automation': 0.96, 'room': 1.0, 'ai': 0.95, 'special': 0.92}),
    'era_3': _EraProfile(roomFlavor: 'creator', generatorCost: 1.0, generatorOutput: 1.04, unlockPressure: -2, branchBias: {'tap': 1.12, 'automation': 0.98, 'room': 0.94, 'ai': 1.04, 'special': 1.02}),
    'era_4': _EraProfile(roomFlavor: 'optimization', generatorCost: 1.04, generatorOutput: 1.02, unlockPressure: 0, branchBias: {'tap': 0.98, 'automation': 1.05, 'room': 1.06, 'ai': 1.0, 'special': 0.95}),
    'era_5': _EraProfile(roomFlavor: 'research', generatorCost: 1.08, generatorOutput: 1.0, unlockPressure: 2, branchBias: {'tap': 0.95, 'automation': 1.0, 'room': 1.05, 'ai': 1.14, 'special': 1.02}),
    'era_6': _EraProfile(roomFlavor: 'thermal', generatorCost: 1.16, generatorOutput: 1.08, unlockPressure: 4, branchBias: {'tap': 0.92, 'automation': 1.12, 'room': 1.0, 'ai': 0.96, 'special': 1.1}),
    'era_7': _EraProfile(roomFlavor: 'focus', generatorCost: 1.08, generatorOutput: 0.98, unlockPressure: 6, branchBias: {'tap': 1.15, 'automation': 0.92, 'room': 0.96, 'ai': 1.04, 'special': 0.98}),
    'era_8': _EraProfile(roomFlavor: 'autonomy', generatorCost: 1.18, generatorOutput: 1.14, unlockPressure: 8, branchBias: {'tap': 0.86, 'automation': 1.18, 'room': 1.03, 'ai': 1.08, 'special': 1.0}),
    'era_9': _EraProfile(roomFlavor: 'apartment', generatorCost: 1.14, generatorOutput: 1.12, unlockPressure: 10, branchBias: {'tap': 0.92, 'automation': 1.08, 'room': 1.14, 'ai': 0.98, 'special': 1.0}),
    'era_10': _EraProfile(roomFlavor: 'containment', generatorCost: 1.24, generatorOutput: 1.02, unlockPressure: 12, branchBias: {'tap': 0.95, 'automation': 0.9, 'room': 1.05, 'ai': 1.06, 'special': 1.18}),
    'era_11': _EraProfile(roomFlavor: 'industrial', generatorCost: 1.2, generatorOutput: 1.16, unlockPressure: 14, branchBias: {'tap': 0.9, 'automation': 1.14, 'room': 1.18, 'ai': 0.96, 'special': 1.02}),
    'era_12': _EraProfile(roomFlavor: 'identity', generatorCost: 1.18, generatorOutput: 1.06, unlockPressure: 16, branchBias: {'tap': 1.0, 'automation': 0.94, 'room': 0.96, 'ai': 1.22, 'special': 1.04}),
    'era_13': _EraProfile(roomFlavor: 'corporate', generatorCost: 1.28, generatorOutput: 1.12, unlockPressure: 18, branchBias: {'tap': 0.88, 'automation': 1.1, 'room': 1.0, 'ai': 1.08, 'special': 1.22}),
    'era_14': _EraProfile(roomFlavor: 'cathedral', generatorCost: 1.3, generatorOutput: 1.08, unlockPressure: 20, branchBias: {'tap': 0.9, 'automation': 1.0, 'room': 1.16, 'ai': 1.02, 'special': 1.1}),
    'era_15': _EraProfile(roomFlavor: 'simulation', generatorCost: 1.34, generatorOutput: 1.1, unlockPressure: 22, branchBias: {'tap': 1.06, 'automation': 0.96, 'room': 0.92, 'ai': 1.1, 'special': 1.24}),
    'era_16': _EraProfile(roomFlavor: 'orbital', generatorCost: 1.36, generatorOutput: 1.18, unlockPressure: 24, branchBias: {'tap': 0.88, 'automation': 1.16, 'room': 1.08, 'ai': 1.0, 'special': 1.12}),
    'era_17': _EraProfile(roomFlavor: 'planetary', generatorCost: 1.42, generatorOutput: 1.22, unlockPressure: 26, branchBias: {'tap': 0.9, 'automation': 1.08, 'room': 1.2, 'ai': 1.02, 'special': 1.14}),
    'era_18': _EraProfile(roomFlavor: 'chrono', generatorCost: 1.46, generatorOutput: 1.14, unlockPressure: 28, branchBias: {'tap': 1.08, 'automation': 1.0, 'room': 0.96, 'ai': 1.16, 'special': 1.18}),
    'era_19': _EraProfile(roomFlavor: 'kernel', generatorCost: 1.52, generatorOutput: 1.2, unlockPressure: 30, branchBias: {'tap': 0.94, 'automation': 1.06, 'room': 1.08, 'ai': 1.18, 'special': 1.2}),
    'era_20': _EraProfile(roomFlavor: 'singularity', generatorCost: 1.6, generatorOutput: 1.26, unlockPressure: 34, branchBias: {'tap': 1.02, 'automation': 1.04, 'room': 1.06, 'ai': 1.14, 'special': 1.26}),
  };

  static const Map<String, Map<String, String>> _eraBranchPrefixes = {
    'era_1': {'tap': 'Salvage', 'automation': 'Patchwork', 'room': 'Cleanup', 'ai': 'Bootstrap', 'special': 'Relic'},
    'era_2': {'tap': 'Budget', 'automation': 'Scripted', 'room': 'Desk', 'ai': 'Utility', 'special': 'Coupon'},
    'era_3': {'tap': 'Creator', 'automation': 'Render', 'room': 'Studio', 'ai': 'Audience', 'special': 'Viral'},
    'era_4': {'tap': 'Precision', 'automation': 'Routing', 'room': 'Cave', 'ai': 'Optimizer', 'special': 'Hidden'},
    'era_5': {'tap': 'Prototype', 'automation': 'Lab', 'room': 'Sensor', 'ai': 'Research', 'special': 'Experiment'},
    'era_6': {'tap': 'Overclock', 'automation': 'Thermal', 'room': 'Rack', 'ai': 'Balancer', 'special': 'Pressure'},
    'era_7': {'tap': 'Nightshift', 'automation': 'Command', 'room': 'Console', 'ai': 'Directive', 'special': 'Mission'},
    'era_8': {'tap': 'Trust', 'automation': 'Drone', 'room': 'Adaptive', 'ai': 'Autonomous', 'special': 'Uncanny'},
    'era_9': {'tap': 'Domestic', 'automation': 'Mesh', 'room': 'Apartment', 'ai': 'Scanner', 'special': 'Hidden'},
    'era_10': {'tap': 'Bypass', 'automation': 'Silent', 'room': 'Lockdown', 'ai': 'Spoof', 'special': 'Containment'},
    'era_11': {'tap': 'Pulse', 'automation': 'Reactor', 'room': 'Forge', 'ai': 'Chamber', 'special': 'Heavy'},
    'era_12': {'tap': 'Expression', 'automation': 'Persona', 'room': 'Studio', 'ai': 'Identity', 'special': 'Presence'},
    'era_13': {'tap': 'Leverage', 'automation': 'Contract', 'room': 'Executive', 'ai': 'Influence', 'special': 'Deal'},
    'era_14': {'tap': 'Resonance', 'automation': 'Harmony', 'room': 'Cathedral', 'ai': 'Reverence', 'special': 'Relic'},
    'era_15': {'tap': 'Glitch', 'automation': 'Paradox', 'room': 'Simulated', 'ai': 'Contradiction', 'special': 'False'},
    'era_16': {'tap': 'Burst', 'automation': 'Orbital', 'room': 'Habitat', 'ai': 'Relay', 'special': 'Vacuum'},
    'era_17': {'tap': 'Forecast', 'automation': 'Grid', 'room': 'Planetary', 'ai': 'Habitat', 'special': 'Regional'},
    'era_18': {'tap': 'Recursive', 'automation': 'Temporal', 'room': 'Chrono', 'ai': 'Prediction', 'special': 'Paradox'},
    'era_19': {'tap': 'Rewrite', 'automation': 'Kernel', 'room': 'Possibility', 'ai': 'Override', 'special': 'Law'},
    'era_20': {'tap': 'Mercy', 'automation': 'Dominion', 'room': 'Synthesis', 'ai': 'Curiosity', 'special': 'Final'},
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
    final unlockLevel =
        order == 1 ? null : 'gen_era_${order - 1}:${28 + (order * 4) + profile.unlockPressure}';
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
            description:
                '${profile.roomFlavor} ${branch.branchName.toLowerCase()} lattice tier $tier for ${era.name}. ${era.rule} Progress here is meant to be deliberate, not instant.',
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
    if (branch.id == 'special') return base + 0.003;
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
      return '${generator.id}:${branch.startRequirement + (tier * 2) + (era.order * 2)}';
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
      return milestone ? '$prefixSeed Keystone $tier' : '$prefixSeed Module $tier';
    }
    final prefix = milestone ? 'Milestone' : branch.branchName;
    return '$themeToken $prefix Tier $tier';
  }

  _EraProfile _profileFor(String eraId) =>
      _profiles[eraId] ?? const _EraProfile(roomFlavor: 'system');

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
