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
  static const double eraSpacing = 320;
  static const double baseX = 220;
  static const double generatorY = 540;
  // Expanded layout positions for up to 100 upgrades per era
  // Upgrades are placed in a grid pattern around the generator
  static const List<double> _upgradeY = [240, 390, 690, 840];
  static const List<double> _upgradeX = [120, 200, 200, 120];
  static const int _rowsPerColumn = 5;
  static const double _columnSpacing = 30;
  static const double _verticalStagger = 8;

  const TechTreeBuilder._();

  static TechTreeGraph build({
    required ConfigService config,
    required GameController controller,
    required AppStrings strings,
    required PurchaseMode purchaseMode,
    String? selectedNodeId,
  }) {
    final eras = config.eras.toList()..sort((a, b) => a.order.compareTo(b.order));
    final nodes = <TechTreeNodeData>[];
    final connections = <TechTreeConnection>[];

    GeneratorDefinition? previousGenerator;

    // Only build nodes for eras that have content loaded.
    // This avoids processing all 20 eras when only a few are unlocked.
    final unlockedEras = controller.state.unlockedEras;

    for (final era in eras) {
      // Skip eras whose content hasn't been loaded yet,
      // unless the era has a generator in config (always show base content)
      final hasGenerator = config.generators.values.any(
        (item) => item.eraId == era.id,
      );
      if (!hasGenerator) {
        // If this era has no generator loaded, skip it entirely
        continue;
      }

      final eraX = baseX + ((era.order - 1) * eraSpacing);
      final generator = config.generators.values.firstWhere(
        (item) => item.eraId == era.id,
      );
      final generatorNode = _buildGeneratorNode(
        generator: generator,
        controller: controller,
        strings: strings,
        eraX: eraX,
        selectedNodeId: selectedNodeId,
        purchaseMode: purchaseMode,
      );
      nodes.add(generatorNode);

      if (previousGenerator != null) {
        connections.add(
          TechTreeConnection(
            fromId: previousGenerator.id,
            toId: generator.id,
            active: !generatorNode.locked,
            emphasized: selectedNodeId == previousGenerator.id ||
                selectedNodeId == generator.id,
          ),
        );
      }

      final upgrades = config.upgrades.values
          .where((item) => item.eraId == era.id)
          .toList()
        ..sort((a, b) => a.baseCost.toDouble().compareTo(b.baseCost.toDouble()));

      for (var index = 0; index < upgrades.length; index++) {
        final upgrade = upgrades[index];
        // Compute grid position for large numbers of upgrades
        final col = index ~/ _rowsPerColumn;
        final row = index % _rowsPerColumn;
        final offsetX = _upgradeX[row.clamp(0, _upgradeX.length - 1).toInt()] +
            (col * _columnSpacing);
        final offsetY = _upgradeY[row.clamp(0, _upgradeY.length - 1).toInt()] +
            (col * _verticalStagger);
        final upgradeNode = _buildUpgradeNode(
          upgrade: upgrade,
          controller: controller,
          generator: generator,
          strings: strings,
          positionX: eraX + offsetX,
          positionY: offsetY,
          selectedNodeId: selectedNodeId,
          purchaseMode: purchaseMode,
        );
        nodes.add(upgradeNode);
        connections.add(
          TechTreeConnection(
            fromId: generator.id,
            toId: upgrade.id,
            active: upgradeNode.purchased || !upgradeNode.locked,
            emphasized: selectedNodeId == generator.id ||
                selectedNodeId == upgrade.id,
          ),
        );
      }

      final secretNodes = _buildSecretNodes(
        eraId: era.id,
        eraX: eraX,
        generator: generator,
        config: config,
        controller: controller,
        strings: strings,
        selectedNodeId: selectedNodeId,
      );
      nodes.addAll(secretNodes.nodes);
      connections.addAll(secretNodes.connections);

      previousGenerator = generator;
    }

    return TechTreeGraph(
      nodes: nodes,
      connections: connections,
      worldSize: const Size(baseX + (20 * eraSpacing) + 420, 1080),
    );
  }

  static TechTreeNodeData _buildGeneratorNode({
    required GeneratorDefinition generator,
    required GameController controller,
    required AppStrings strings,
    required double eraX,
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
      position: Offset(eraX, generatorY),
      title: generator.name,
      subtitle: strings.nodeCore,
      description: generator.description,
      eraId: generator.eraId,
      icon: '◉',
      cost: cost,
      costLabel: cost.toStringFormatted(),
      effectLabel:
          '+${(generator.baseProduction * GameNumber.fromDouble(quantity.toDouble())).toStringFormatted()}/sec',
      requirementLabel: unlocked
          ? strings.discovered
          : _generatorRequirement(generator, strings),
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
    final unlocked = (controller.state.generators[generator.id]?.level ?? 0) > 0;
    final affordable = unlocked && !atMax && controller.state.coins >= cost;

    return TechTreeNodeData(
      id: upgrade.id,
      kind: TechTreeNodeKind.upgrade,
      scale: upgrade.category == UpgradeCategory.room
          ? TechTreeNodeScale.major
          : TechTreeNodeScale.minor,
      position: Offset(positionX, positionY),
      title: upgrade.name,
      subtitle: strings.categoryLabel(upgrade.category),
      description: upgrade.description,
      eraId: upgrade.eraId,
      icon: _upgradeSymbol(upgrade),
      cost: cost,
      costLabel: atMax ? strings.maxed : cost.toStringFormatted(),
      effectLabel: _upgradeEffectLabel(upgrade, strings),
      requirementLabel: atMax
          ? strings.fullyUpgraded
          : strings.requiresGeneratorLevel(generator.name, 1),
      dependencyLabel: generator.name,
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
    required double eraX,
    required GeneratorDefinition generator,
    required ConfigService config,
    required GameController controller,
    required AppStrings strings,
    required String? selectedNodeId,
  }) {
    final nodes = <TechTreeNodeData>[];
    final connections = <TechTreeConnection>[];
    final byId = <String, Offset>{
      generator.id: Offset(eraX, generatorY),
    };
    final upgrades = config.upgrades.values.where((item) => item.eraId == eraId);
    for (var index = 0; index < upgrades.length; index++) {
      final upgrade = upgrades.elementAt(index);
      byId[upgrade.id] = Offset(
        eraX + _upgradeX[index.clamp(0, _upgradeX.length - 1).toInt()],
        _upgradeY[index.clamp(0, _upgradeY.length - 1).toInt()],
      );
    }

    for (final secret in config.progression.secrets.where((item) => item.eraId == eraId)) {
      final parent = byId[secret.parentId];
      if (parent == null) continue;
      final hinted = _isSecretHinted(secret, controller);
      final discovered = controller.state.discoveredSecrets.contains(secret.id);
      if (!hinted && !discovered) continue;

      nodes.add(
        TechTreeNodeData(
          id: secret.id,
          kind: TechTreeNodeKind.secret,
          scale: TechTreeNodeScale.minor,
          position: Offset(parent.dx + secret.offsetX, parent.dy + secret.offsetY),
          title: discovered ? secret.title : strings.hiddenSignal,
          subtitle: discovered ? strings.nodeSecret : strings.nodeUnknownBranch,
          description: discovered
              ? secret.description
              : strings.concealedRouteHint,
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
    switch (purchaseMode) {
      case PurchaseMode.x1:
        return 1;
      case PurchaseMode.x10:
        return 10;
      case PurchaseMode.x100:
        return 100;
      case PurchaseMode.max:
        return CostCalculator.maxAffordable(
          generator.baseCost,
          generator.costGrowthRate,
          currentLevel,
          controller.state.coins,
        ).clamp(1, 9999);
    }
  }

  static int _upgradeQuantity(
    UpgradeDefinition upgrade,
    GameController controller,
    PurchaseMode purchaseMode,
  ) {
    final currentLevel = controller.state.upgrades[upgrade.id]?.level ?? 0;
    final remainingLevels = (upgrade.maxLevel - currentLevel).clamp(0, upgrade.maxLevel);
    if (remainingLevels <= 0) return 1;
    switch (purchaseMode) {
      case PurchaseMode.x1:
        return math.min(1, remainingLevels);
      case PurchaseMode.x10:
        return math.min(10, remainingLevels);
      case PurchaseMode.x100:
        return math.min(100, remainingLevels);
      case PurchaseMode.max:
        return CostCalculator.maxAffordable(
          upgrade.baseCost,
          upgrade.costGrowthRate,
          currentLevel,
          controller.state.coins,
        ).clamp(1, remainingLevels);
    }
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

  static String _upgradeSymbol(UpgradeDefinition upgrade) {
    switch (upgrade.category) {
      case UpgradeCategory.tap:
        return '✦';
      case UpgradeCategory.automation:
        return '⚙';
      case UpgradeCategory.room:
        return '⬢';
      case UpgradeCategory.ai:
        return '◌';
      case UpgradeCategory.special:
        return '★';
    }
  }

  static String _upgradeEffectLabel(
    UpgradeDefinition upgrade,
    AppStrings strings,
  ) {
    switch (upgrade.type) {
      case UpgradeType.tapMultiplier:
        return strings.effectTap(upgrade.effectPerLevel.toStringFormatted());
      case UpgradeType.productionMultiplier:
        return strings.effectProduction(
          upgrade.effectPerLevel.toStringFormatted(),
        );
      case UpgradeType.generatorMultiplier:
        return strings.effectCore(upgrade.effectPerLevel.toStringFormatted());
    }
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
}
