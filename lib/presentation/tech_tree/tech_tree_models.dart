import 'dart:ui';

import '../../core/math/game_number.dart';

enum TechTreeNodeKind { generator, upgrade, secret }

enum TechTreeNodeScale { minor, major, milestone }

enum TechTreeNodeState {
  locked,
  unlockable,
  affordable,
  purchased,
  selected,
}

class TechTreeNodeData {
  final String id;
  final TechTreeNodeKind kind;
  final TechTreeNodeScale scale;
  final Offset position;
  final String title;
  final String subtitle;
  final String description;
  final String eraId;
  final String icon;
  final GameNumber cost;
  final String costLabel;
  final String effectLabel;
  final String requirementLabel;
  final String dependencyLabel;
  final String progressLabel;
  final bool locked;
  final bool affordable;
  final bool purchased;
  final bool highlighted;

  const TechTreeNodeData({
    required this.id,
    required this.kind,
    required this.scale,
    required this.position,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.eraId,
    required this.icon,
    required this.cost,
    required this.costLabel,
    required this.effectLabel,
    required this.requirementLabel,
    required this.dependencyLabel,
    required this.progressLabel,
    required this.locked,
    required this.affordable,
    required this.purchased,
    required this.highlighted,
  });

  TechTreeNodeState get visualState {
    if (highlighted) return TechTreeNodeState.selected;
    if (purchased) return TechTreeNodeState.purchased;
    if (locked) return TechTreeNodeState.locked;
    if (affordable) return TechTreeNodeState.affordable;
    return TechTreeNodeState.unlockable;
  }

  bool get isSecret => kind == TechTreeNodeKind.secret;
}

class TechTreeConnection {
  final String fromId;
  final String toId;
  final bool active;
  final bool emphasized;

  const TechTreeConnection({
    required this.fromId,
    required this.toId,
    required this.active,
    this.emphasized = false,
  });
}

class TechTreeGraph {
  final List<TechTreeNodeData> nodes;
  final List<TechTreeConnection> connections;
  final Size worldSize;

  const TechTreeGraph({
    required this.nodes,
    required this.connections,
    required this.worldSize,
  });

  TechTreeNodeData? nodeById(String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }
}
