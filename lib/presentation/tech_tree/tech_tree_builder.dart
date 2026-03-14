import 'dart:math' as math;
import 'dart:ui';

import '../../application/controllers/game_controller.dart';
import '../../application/services/app_strings.dart';
import '../../application/services/config_service.dart';
import '../../core/math/game_number.dart';
import '../../domain/mechanics/cost_calculator.dart';
import '../../domain/models/game_systems.dart';
import '../../domain/models/generator.dart';
import '../../domain/models/progression_content.dart';
import '../../domain/models/upgrade.dart';
import 'tech_tree_models.dart';

class TechTreeBuilder {
  static const double worldWidth = 2500;
  static const double worldHeight = 980;
  static const double generatorX = 190;
  static const double generatorY = 490;
  static const double branchStartX = 470;
  static const double branchStepX = 92;

  static const Map<String, double> _branchRows = {
    'tap': 170,
    'automation': 330,
    'room': 490,
    'ai': 650,
    'special': 810,
  };

  static const Map<String, String> _branchIcons = {
    'tap': '✦',
    'automation': '⚙',
    'room': '⬢',
    'ai': '◌',
    'special': '★',
  };

  const TechTreeBuilder._();

  static TechTreeGraph build({
    required ConfigService config,
    required GameController controller,
    required AppStrings strings,
    required PurchaseMode purchaseMode,
    required String eraId,
    String? selectedNodeId,
  }) {
    final nodes = <TechTreeNodeData>[];
    final connections = <TechTreeConnection>[];
    final generator = _generatorForEra(config, eraId);
    if (generator == null) {
      return const TechTreeGraph(
        nodes: [],
        connections: [],
        worldSize: Size(worldWidth, worldHeight),
      );
    }

    final generatorNode = _buildGeneratorNode(
      generator: generator,
      controller: controller,
      strings: strings,
      selectedNodeId: selectedNodeId,
      purchaseMode: purchaseMode,
    );
    nodes.add(generatorNode);

    final grouped = _groupUpgrades(config, eraId);
    final nodePositions = <String, Offset>{
      generator.id: generatorNode.position,
    };

    for (final entry in grouped.entries) {
      final branchId = entry.key;
      final upgrades = entry.value;
      for (var index = 0; index < upgrades.length; index++) {
        final upgrade = upgrades[index];
        final offset = _upgradeOffset(branchId, index);
        final upgradeNode = _buildUpgradeNode(
          upgrade: upgrade,
          controller: controller,
          generator: generator,
          strings: strings,
          positionX: offset.dx,
          positionY: offset.dy,
          selectedNodeId: selectedNodeId,
          purchaseMode: purchaseMode,
        );
        nodes.add(upgradeNode);
        nodePositions[upgrade.id] = upgradeNode.position;

        final parentId = index == 0 ? generator.id : upgrades[index - 1].id;
        connections.add(
          TechTreeConnection(
            fromId: parentId,
            toId: upgrade.id,
            active: upgradeNode.purchased || !upgradeNode.locked,
            emphasized: selectedNodeId == parentId || selectedNodeId == upgrade.id,
          ),
        );

        if (upgradeNode.scale == TechTreeNodeScale.milestone && index > 0) {
          final branchRootId = upgrades.first.id;
          if (branchRootId != parentId) {
            connections.add(
              TechTreeConnection(
                fromId: branchRootId,
                toId: upgrade.id,
                active: upgradeNode.purchased,
                emphasized: selectedNodeId == branchRootId || selectedNodeId == upgrade.id,
              ),
            );
          }
        }
      }
    }

    final secretContent = _buildSecretNodes(
      eraId: eraId,
      config: config,
      controller: controller,
      strings: strings,
      selectedNodeId: selectedNodeId,
      nodePositions: nodePositions,
    );
    nodes.addAll(secretContent.nodes);
    connections.addAll(secretContent.connections);

    return TechTreeGraph(
      nodes: nodes,
      connections: connections,
      worldSize: const Size(worldWidth, worldHeight),
    );
  }

  static GeneratorDefinition? _generatorForEra(ConfigService config, String eraId) {
    for (final generator in config.generators.values) {
      if (generator.eraId == eraId) return generator;
    }
    return null;
  }

  static Map<String, List<UpgradeDefinition>> _groupUpgrades(
    ConfigService config,
    String eraId,
  ) {
    final grouped = <String, List<UpgradeDefinition>>{};
    final upgrades = config.upgrades.values.where((item) => item.eraId == eraId).toList();
    for (final upgrade in upgrades) {
      final branchId = _branchIdForUpgrade(upgrade);
      grouped.putIfAbsent(branchId, () => []).add(upgrade);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aIndex = _branchRows.keys.toList().indexOf(a);
        final bIndex = _branchRows.keys.toList().indexOf(b);
        return aIndex.compareTo(bIndex);
      });
    return {
      for (final key in sortedKeys)
        key: grouped[key]!
          ..sort((a, b) => _tierForUpgrade(a).compareTo(_tierForUpgrade(b))),
    };
  }

  static Offset _upgradeOffset(String branchId, int index) {
    final y = _branchRows[branchId] ?? generatorY;
    final tier = index + 1;
    final column = (tier - 1) ~/ 10;
    final row = (tier - 1) % 10;
    final baseX = branchStartX + (column * 920);
    final x = baseX + (row * branchStepX);
    final wave = (column.isEven ? 1 : -1) * (row.isEven ? 10 : -10);
    return Offset(x, y + wave);
  }

  static TechTreeNodeData _buildGeneratorNode({
    required GeneratorDefinition generator,
    required GameController controller,
    required AppStrings strings,
    required String? selectedNodeId,
    required PurchaseMode purchaseMode,
  }) {
    final state = controller.state.generators[generator.id];
    final currentLevel = state?.level ?? 0;
    final quantity = _generatorQuantity(generator, controller, purchaseMode);
    final cost = CostCalculator.calculateTotalCost(
      generator.baseCost,
      generator.costGrowthRate,
      currentLevel,
      quantity,
    );
    final unlocked = _generatorUnlocked(generator, controller);
    final affordable = unlocked && controller.state.coins >= cost;
    final milestone = generator.eraId.endsWith('5') ||
        generator.eraId.endsWith('10') ||
        generator.eraId.endsWith('15') ||
        generator.eraId.endsWith('20');

    return TechTreeNodeData(
      id: generator.id,
      kind: TechTreeNodeKind.generator,
      scale: milestone ? TechTreeNodeScale.milestone : TechTreeNodeScale.major,
      position: const Offset(generatorX, generatorY),
      title: strings.localizedGeneratorName(generator),
      subtitle: strings.nodeCore,
      description: strings.localizedGeneratorDescription(generator),
      eraId: generator.eraId,
      icon: '◉',
      cost: cost,
      costLabel: cost.toStringFormatted(),
      effectLabel:
          '+${(generator.baseProduction * GameNumber.fromDouble(quantity.toDouble())).toStringFormatted()}/sec',
      requirementLabel:
          unlocked ? strings.discovered : _generatorRequirement(generator, strings),
      dependencyLabel: _generatorRequirement(generator, strings),
      progressLabel: strings.generatorLevelLabel(currentLevel),
      locked: !unlocked,
      affordable: affordable,
      purchased: currentLevel > 0,
      highlighted: selectedNodeId == generator.id,
    );
  }

  static TechTreeNodeData _buildUpgradeNode({
    required UpgradeDefinition upgrade,
    required GameController controller,
    required GeneratorDefinition generator,
    required AppStrings strings,
    required double positionX,
    required double positionY,
    required String? selectedNodeId,
    required PurchaseMode purchaseMode,
  }) {
    final state = controller.state.upgrades[upgrade.id];
    final level = state?.level ?? 0;
    final atMax = level >= upgrade.maxLevel;
    final quantity = _upgradeQuantity(upgrade, controller, purchaseMode);
    final cost = atMax
        ? const GameNumber.zero()
        : CostCalculator.calculateTotalCost(
            upgrade.baseCost,
            upgrade.costGrowthRate,
            level,
            quantity,
          );
    final unlocked = _upgradeUnlocked(upgrade, controller, generator.id);
    final affordable = unlocked && !atMax && controller.state.coins >= cost;
    final tier = _tierForUpgrade(upgrade);
    final branchId = _branchIdForUpgrade(upgrade);
    final milestone = tier % 5 == 0;

    return TechTreeNodeData(
      id: upgrade.id,
      kind: TechTreeNodeKind.upgrade,
      scale: milestone
          ? TechTreeNodeScale.major
          : upgrade.category == UpgradeCategory.room
              ? TechTreeNodeScale.major
              : TechTreeNodeScale.minor,
      position: Offset(positionX, positionY),
      title: strings.localizedUpgradeName(upgrade),
      subtitle: strings.categoryLabel(upgrade.category),
      description: strings.localizedUpgradeDescription(upgrade),
      eraId: upgrade.eraId,
      icon: _branchIcons[branchId] ?? _upgradeSymbol(upgrade),
      cost: cost,
      costLabel: atMax ? strings.maxed : cost.toStringFormatted(),
      effectLabel: _upgradeEffectLabel(upgrade, strings),
      requirementLabel: atMax
          ? strings.fullyUpgraded
          : _upgradeRequirement(upgrade, controller, generator.id, strings),
      dependencyLabel: _dependencyLabel(upgrade, generator, strings),
      progressLabel:
          '$level/${upgrade.maxLevel}${quantity > 1 && !atMax ? ' • ${purchaseMode.label}' : ''}',
      locked: !unlocked,
      affordable: affordable,
      purchased: level > 0,
      highlighted: selectedNodeId == upgrade.id,
    );
  }

  static ({List<TechTreeNodeData> nodes, List<TechTreeConnection> connections})
      _buildSecretNodes({
    required String eraId,
    required ConfigService config,
    required GameController controller,
    required AppStrings strings,
    required String? selectedNodeId,
    required Map<String, Offset> nodePositions,
  }) {
    final nodes = <TechTreeNodeData>[];
    final connections = <TechTreeConnection>[];

    for (final secret in config.progression.secrets.where((item) => item.eraId == eraId)) {
      final parent = nodePositions[secret.parentId];
      if (parent == null) continue;
      final hinted = _isSecretHinted(secret, controller);
      final discovered = controller.state.discoveredSecrets.contains(secret.id);
      if (!hinted && !discovered) continue;

      nodes.add(
        TechTreeNodeData(
          id: secret.id,
          kind: TechTreeNodeKind.secret,
          scale: discovered ? TechTreeNodeScale.major : TechTreeNodeScale.minor,
          position: Offset(parent.dx + secret.offsetX, parent.dy + secret.offsetY),
          title: discovered ? strings.translateContent(secret.title) : strings.hiddenSignal,
          subtitle: discovered ? strings.nodeSecret : strings.nodeUnknownBranch,
          description:
              discovered ? strings.translateContent(secret.description) : strings.concealedRouteHint,
          eraId: secret.eraId,
          icon: discovered ? secret.icon : '?',
          cost: const GameNumber.zero(),
          costLabel: discovered ? strings.discovered : strings.undiscovered,
          effectLabel:
              discovered ? secret.effectLabel : strings.hiddenRouteHint,
          requirementLabel: _secretRequirement(secret, controller, strings),
          dependencyLabel: secret.parentId,
          progressLabel: discovered ? strings.secretFound : strings.hidden,
          locked: !discovered,
          affordable: false,
          purchased: discovered,
          highlighted: selectedNodeId == secret.id,
        ),
      );
      connections.add(
        TechTreeConnection(
          fromId: secret.parentId,
          toId: secret.id,
          active: discovered,
          emphasized: selectedNodeId == secret.id || selectedNodeId == secret.parentId,
        ),
      );
    }

    return (nodes: nodes, connections: connections);
  }

  static int _generatorQuantity(
    GeneratorDefinition generator,
    GameController controller,
    PurchaseMode purchaseMode,
  ) {
    final currentLevel = controller.state.generators[generator.id]?.level ?? 0;
    return switch (purchaseMode) {
      PurchaseMode.x1 => 1,
      PurchaseMode.x10 => 10,
      PurchaseMode.x100 => 100,
      PurchaseMode.max => CostCalculator.maxAffordable(
        generator.baseCost,
        generator.costGrowthRate,
        currentLevel,
        controller.state.coins,
      ).clamp(1, 9999),
    };
  }

  static int _upgradeQuantity(
    UpgradeDefinition upgrade,
    GameController controller,
    PurchaseMode purchaseMode,
  ) {
    final currentLevel = controller.state.upgrades[upgrade.id]?.level ?? 0;
    final remainingLevels =
        (upgrade.maxLevel - currentLevel).clamp(0, upgrade.maxLevel);
    if (remainingLevels <= 0) return 1;
    return switch (purchaseMode) {
      PurchaseMode.x1 => math.min(1, remainingLevels),
      PurchaseMode.x10 => math.min(10, remainingLevels),
      PurchaseMode.x100 => math.min(100, remainingLevels),
      PurchaseMode.max => CostCalculator.maxAffordable(
        upgrade.baseCost,
        upgrade.costGrowthRate,
        currentLevel,
        controller.state.coins,
      ).clamp(1, remainingLevels),
    };
  }

  static bool _generatorUnlocked(
    GeneratorDefinition generator,
    GameController controller,
  ) {
    final requirement = generator.unlockRequirement;
    if (requirement == null || requirement.isEmpty) return true;
    final parts = requirement.split(':');
    if (parts.length != 2) return true;
    final dependencyId = parts.first;
    final level = int.tryParse(parts.last) ?? 0;
    final dependencyState = controller.state.generators[dependencyId];
    return (dependencyState?.level ?? 0) >= level;
  }

  static bool _upgradeUnlocked(
    UpgradeDefinition upgrade,
    GameController controller,
    String defaultGeneratorId,
  ) {
    final requirement = upgrade.unlockRequirement;
    if (requirement == null || requirement.isEmpty) {
      return (controller.state.generators[defaultGeneratorId]?.level ?? 0) > 0;
    }
    final parts = requirement.split(':');
    if (parts.length != 2) return true;
    final dependencyId = parts.first;
    final level = int.tryParse(parts.last) ?? 0;
    if (dependencyId.startsWith('upg_')) {
      return (controller.state.upgrades[dependencyId]?.level ?? 0) >= level;
    }
    return (controller.state.generators[dependencyId]?.level ?? 0) >= level;
  }

  static String _generatorRequirement(
    GeneratorDefinition generator,
    AppStrings strings,
  ) {
    final requirement = generator.unlockRequirement;
    if (requirement == null || requirement.isEmpty) return strings.startingBranch;
    final parts = requirement.split(':');
    if (parts.length != 2) return requirement;
    return strings.requiresGeneratorLevel(
      parts.first.replaceAll('_', ' '),
      int.tryParse(parts.last) ?? 1,
    );
  }

  static String _upgradeRequirement(
    UpgradeDefinition upgrade,
    GameController controller,
    String defaultGeneratorId,
    AppStrings strings,
  ) {
    final requirement = upgrade.unlockRequirement;
    if (requirement == null || requirement.isEmpty) {
      return strings.requiresGeneratorLevel(defaultGeneratorId, 1);
    }
    final parts = requirement.split(':');
    if (parts.length != 2) return requirement;
    final dependencyId = parts.first;
    final level = int.tryParse(parts.last) ?? 1;
    if (dependencyId.startsWith('upg_')) {
      return strings.requiresUpgradeLevel(_humanizeDependency(dependencyId), level);
    }
    if ((controller.state.generators[dependencyId]?.level ?? 0) >= level) {
      return strings.discovered;
    }
    return strings.requiresGeneratorLevel(_humanizeDependency(dependencyId), level);
  }

  static String _dependencyLabel(
    UpgradeDefinition upgrade,
    GeneratorDefinition generator,
    AppStrings strings,
  ) {
    final requirement = upgrade.unlockRequirement;
    if (requirement == null || requirement.isEmpty) return generator.name;
    final parts = requirement.split(':');
    if (parts.isEmpty) return generator.name;
    return _humanizeDependency(parts.first);
  }

  static String _upgradeSymbol(UpgradeDefinition upgrade) {
    return switch (upgrade.category) {
      UpgradeCategory.tap => '✦',
      UpgradeCategory.automation => '⚙',
      UpgradeCategory.room => '⬢',
      UpgradeCategory.ai => '◌',
      UpgradeCategory.special => '★',
      UpgradeCategory.companion => '🤖',
      UpgradeCategory.event => '⚡',
      UpgradeCategory.sideActivity => '🎯',
      UpgradeCategory.route => '🧭',
      UpgradeCategory.guide => '💡',
      UpgradeCategory.anomaly => '⊘',
      UpgradeCategory.quality => '✧',
      UpgradeCategory.transformation => '◈',
      UpgradeCategory.secret => '🔮',
      UpgradeCategory.relic => '🏺',
    };
  }

  static String _upgradeEffectLabel(
    UpgradeDefinition upgrade,
    AppStrings strings,
  ) {
    return switch (upgrade.type) {
      UpgradeType.tapMultiplier =>
        strings.effectTap(upgrade.effectPerLevel.toStringFormatted()),
      UpgradeType.productionMultiplier =>
        strings.effectProduction(upgrade.effectPerLevel.toStringFormatted()),
      UpgradeType.generatorMultiplier =>
        strings.effectCore(upgrade.effectPerLevel.toStringFormatted()),
    };
  }

  static bool _isSecretHinted(
    SecretDefinition secret,
    GameController controller,
  ) {
    final branchOk = secret.requiredBranchId == null ||
        controller.state.chosenBranches.contains(secret.requiredBranchId);
    final milestoneOk = secret.requiredMilestoneId == null ||
        controller.state.unlockedMilestones.contains(secret.requiredMilestoneId);
    return branchOk || milestoneOk;
  }

  static String _secretRequirement(
    SecretDefinition secret,
    GameController controller,
    AppStrings strings,
  ) {
    if (controller.state.discoveredSecrets.contains(secret.id)) {
      return strings.secretRouteDiscovered;
    }
    if (secret.requiredBranchId != null &&
        !controller.state.chosenBranches.contains(secret.requiredBranchId)) {
      return strings.requiresRoute(secret.requiredBranchId!);
    }
    if (secret.requiredMilestoneId != null &&
        !controller.state.unlockedMilestones.contains(secret.requiredMilestoneId)) {
      return strings.requiresMilestone(secret.requiredMilestoneId!);
    }
    return strings.playstyleConditionNotMet;
  }

  static String _branchIdForUpgrade(UpgradeDefinition upgrade) {
    final parts = upgrade.id.split('_');
    if (parts.length >= 4) {
      return parts[3];
    }
    return switch (upgrade.category) {
      UpgradeCategory.tap => 'tap',
      UpgradeCategory.automation => 'automation',
      UpgradeCategory.room => 'room',
      UpgradeCategory.ai => 'ai',
      UpgradeCategory.special => 'special',
      _ => upgrade.category.name,
    };
  }

  static int _tierForUpgrade(UpgradeDefinition upgrade) {
    final parts = upgrade.id.split('_');
    return int.tryParse(parts.isNotEmpty ? parts.last : '') ?? 1;
  }

  static String _humanizeDependency(String raw) {
    return raw.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
