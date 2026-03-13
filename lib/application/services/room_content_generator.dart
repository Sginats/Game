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
    // Use era-themed names for more variety
    final names = _eraUpgradeNames[themeToken];
    if (names != null) {
      final branchNames = names[branch.id];
      if (branchNames != null && tier <= branchNames.length) {
        return branchNames[tier - 1];
      }
    }
    final prefix = milestone ? 'Milestone' : branch.branchName;
    return '$themeToken $prefix Tier $tier';
  }

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
