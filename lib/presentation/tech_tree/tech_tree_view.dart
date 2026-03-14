import 'package:flutter/material.dart';

import 'tech_tree_models.dart';

class TechTreeView extends StatelessWidget {
  final TechTreeGraph graph;
  final String? selectedNodeId;
  final String? hoveredNodeId;
  final TransformationController transformationController;
  final Widget? backgroundLayer;
  final ValueChanged<TechTreeNodeData> onNodeTap;
  final ValueChanged<String?> onHoverChanged;

  const TechTreeView({
    super.key,
    required this.graph,
    required this.selectedNodeId,
    required this.hoveredNodeId,
    required this.transformationController,
    this.backgroundLayer,
    required this.onNodeTap,
    required this.onHoverChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x8A08111D),
          border: Border.all(color: Colors.white.withAlpha(12)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: InteractiveViewer(
          transformationController: transformationController,
          constrained: false,
          minScale: 0.5,
          maxScale: 1.8,
          boundaryMargin: const EdgeInsets.all(480),
          scaleEnabled: true,
          panEnabled: true,
          child: SizedBox(
            width: graph.worldSize.width,
            height: graph.worldSize.height,
            child: Stack(
              children: [
                if (backgroundLayer != null)
                  Positioned.fill(child: backgroundLayer!),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ConnectionPainter(
                      graph: graph,
                      selectedNodeId: selectedNodeId,
                      hoveredNodeId: hoveredNodeId,
                    ),
                  ),
                ),
                ...graph.nodes.map(
                  (node) => Positioned(
                    left: node.position.dx - (_nodeRadius(node) / 2),
                    top: node.position.dy - (_nodeRadius(node) / 2),
                    child: _TreeNode(
                      key: ValueKey('tree-node-${node.id}'),
                      node: node,
                      hovered: hoveredNodeId == node.id,
                      onTap: () => onNodeTap(node),
                      onHoverChanged: (hovering) =>
                          onHoverChanged(hovering ? node.id : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double _nodeRadius(TechTreeNodeData node) {
    switch (node.scale) {
      case TechTreeNodeScale.minor:
        return 76;
      case TechTreeNodeScale.major:
        return 102;
      case TechTreeNodeScale.milestone:
        return 128;
    }
  }
}

class _TreeNode extends StatelessWidget {
  final TechTreeNodeData node;
  final bool hovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHoverChanged;

  const _TreeNode({
    super.key,
    required this.node,
    required this.hovered,
    required this.onTap,
    required this.onHoverChanged,
  });

  @override
  Widget build(BuildContext context) {
    final radius = _radiusFor(node.scale);
    final isSelected = node.visualState == TechTreeNodeState.selected;
    final isSecret = node.isSecret;
    final colors = _paletteFor(node.visualState, isSecret: isSecret);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: radius,
          height: radius,
          decoration: BoxDecoration(
            shape: isSecret ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isSecret ? BorderRadius.circular(radius * 0.28) : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: Border.all(
              color: Colors.white.withAlpha(isSelected ? 180 : hovered ? 96 : 56),
              width: isSelected ? 2.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withAlpha(node.purchased ? 80 : 40),
                blurRadius: hovered || isSelected ? 10 : 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSecret)
                Container(
                  key: ValueKey('secret-orbit-${node.id}'),
                  width: radius + 10,
                  height: radius + 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius * 0.32),
                    border: Border.all(
                      color: colors.first.withAlpha(node.purchased ? 120 : 80),
                      width: 1,
                    ),
                  ),
                ),
              if (isSecret && !node.purchased)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.first.withAlpha(36),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'SECRET',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    node.icon,
                    style: TextStyle(
                      color: Colors.white.withAlpha(node.locked ? 130 : 255),
                      fontSize: radius * 0.24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      node.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(node.locked ? 150 : 245),
                        fontSize: radius < 90 ? 9.5 : 11,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    node.progressLabel,
                    style: TextStyle(
                      color: node.purchased
                          ? const Color(0xFFFFD66B)
                          : node.affordable
                              ? const Color(0xFF7AEACC)
                              : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _radiusFor(TechTreeNodeScale scale) {
    switch (scale) {
      case TechTreeNodeScale.minor:
        return 76;
      case TechTreeNodeScale.major:
        return 102;
      case TechTreeNodeScale.milestone:
        return 128;
    }
  }

  static List<Color> _paletteFor(
    TechTreeNodeState state, {
    required bool isSecret,
  }) {
    if (isSecret) {
      switch (state) {
        case TechTreeNodeState.locked:
          return const [Color(0xFF52305C), Color(0xFF1D1229)];
        case TechTreeNodeState.unlockable:
          return const [Color(0xFF6A4B88), Color(0xFF2A1A3D)];
        case TechTreeNodeState.affordable:
          return const [Color(0xFF3FCFE0), Color(0xFF245D8A)];
        case TechTreeNodeState.purchased:
          return const [Color(0xFFFFC96E), Color(0xFFCC6C2D)];
        case TechTreeNodeState.selected:
          return const [Color(0xFFB38CFF), Color(0xFF3A63C2)];
      }
    }
    switch (state) {
      case TechTreeNodeState.locked:
        return const [Color(0xFF2A3648), Color(0xFF1A2233)];
      case TechTreeNodeState.unlockable:
        return const [Color(0xFF344D6A), Color(0xFF1C2F48)];
      case TechTreeNodeState.affordable:
        return const [Color(0xFF1CC4AD), Color(0xFF0F7A6E)];
      case TechTreeNodeState.purchased:
        return const [Color(0xFFF4B942), Color(0xFFB66A1E)];
      case TechTreeNodeState.selected:
        return const [Color(0xFF5BD2FF), Color(0xFF226B9E)];
    }
  }
}

class _ConnectionPainter extends CustomPainter {
  final TechTreeGraph graph;
  final String? selectedNodeId;
  final String? hoveredNodeId;

  const _ConnectionPainter({
    required this.graph,
    required this.selectedNodeId,
    required this.hoveredNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (final node in graph.nodes) node.id: node};
    for (final connection in graph.connections) {
      final fromNode = nodeMap[connection.fromId];
      final toNode = nodeMap[connection.toId];
      if (fromNode == null || toNode == null) continue;

      final selected = selectedNodeId == connection.fromId ||
          selectedNodeId == connection.toId ||
          hoveredNodeId == connection.fromId ||
          hoveredNodeId == connection.toId ||
          connection.emphasized;

      final path = Path()
        ..moveTo(fromNode.position.dx, fromNode.position.dy)
        ..cubicTo(
          fromNode.position.dx + 80,
          fromNode.position.dy,
          toNode.position.dx - 80,
          toNode.position.dy,
          toNode.position.dx,
          toNode.position.dy,
        );

      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.2 : 1.2
        ..color = connection.active
            ? const Color(0xFF63E6FF)
            : const Color(0xFF2D4157);

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) {
    return graph != oldDelegate.graph ||
        selectedNodeId != oldDelegate.selectedNodeId ||
        hoveredNodeId != oldDelegate.hoveredNodeId;
  }
}
