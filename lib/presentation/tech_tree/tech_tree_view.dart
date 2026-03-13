import 'package:flutter/material.dart';

import 'tech_tree_models.dart';

class TechTreeView extends StatelessWidget {
  final TechTreeGraph graph;
  final String? selectedNodeId;
  final String? hoveredNodeId;
  final TransformationController transformationController;
  final ValueChanged<TechTreeNodeData> onNodeTap;
  final ValueChanged<String?> onHoverChanged;

  const TechTreeView({
    super.key,
    required this.graph,
    required this.selectedNodeId,
    required this.hoveredNodeId,
    required this.transformationController,
    required this.onNodeTap,
    required this.onHoverChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xCC08111D),
          border: Border.all(color: Colors.white.withAlpha(18)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: InteractiveViewer(
          transformationController: transformationController,
          constrained: false,
          minScale: 0.6,
          maxScale: 1.55,
          boundaryMargin: const EdgeInsets.all(420),
          scaleEnabled: true,
          panEnabled: true,
          child: SizedBox(
            width: graph.worldSize.width,
            height: graph.worldSize.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TreeBackdropPainter(),
                  ),
                ),
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
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 1,
            end: isSelected
                ? 1.08
                : hovered
                    ? (isSecret ? 1.07 : 1.04)
                    : 1,
          ),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: radius,
            height: radius,
            decoration: BoxDecoration(
              shape: isSecret ? BoxShape.rectangle : BoxShape.circle,
              borderRadius:
                  isSecret ? BorderRadius.circular(radius * 0.28) : null,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              border: Border.all(
                color: Colors.white.withAlpha(isSelected ? 220 : 64),
                width: isSelected ? 2.6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withAlpha(node.purchased ? 160 : 72),
                  blurRadius: hovered || isSelected ? 26 : 14,
                  spreadRadius: hovered || isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isSecret)
                  TweenAnimationBuilder<double>(
                    key: ValueKey('secret-orbit-${node.id}'),
                    tween: Tween<double>(
                      begin: 0.92,
                      end: hovered || isSelected ? 1.08 : 1.0,
                    ),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: hovered || isSelected ? 0.18 : 0,
                        child: Transform.scale(scale: value, child: child),
                      );
                    },
                    child: Container(
                      width: radius + 12,
                      height: radius + 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius * 0.32),
                        border: Border.all(
                          color: colors.first.withAlpha(node.purchased ? 150 : 96),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                if (node.purchased)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.88, end: 1.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: radius - 10,
                      height: radius - 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(28),
                        ),
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
                        color: colors.first.withAlpha(40),
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
                        color: Colors.white.withAlpha(node.locked ? 90 : 255),
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
                          color: Colors.white.withAlpha(node.locked ? 110 : 245),
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
        return const [Color(0xFF243041), Color(0xFF151C2B)];
      case TechTreeNodeState.unlockable:
        return const [Color(0xFF2C4764), Color(0xFF172436)];
      case TechTreeNodeState.affordable:
        return const [Color(0xFF18A999), Color(0xFF0E615D)];
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

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 5 : 3
        ..color = (connection.active
                ? const Color(0x8863E6FF)
                : const Color(0x3326374A))
            .withAlpha(selected ? 180 : connection.active ? 120 : 48)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.6 : 1.4
        ..color = connection.active
            ? const Color(0xFF63E6FF)
            : const Color(0xFF2D4157);

      canvas.drawPath(path, glowPaint);
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

class _TreeBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x11FFFFFF)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 80) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 80) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final bandPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x220E2339),
          Color(0x000E2339),
          Color(0x180E2339),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, bandPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
