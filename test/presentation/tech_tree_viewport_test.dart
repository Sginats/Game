/// Tests for TechTreeView viewport culling logic and PerformanceBudget
/// validation helpers.
import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/domain/models/performance_budget.dart';
import 'package:ai_evolution/presentation/tech_tree/tech_tree_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Minimal helpers to build TechTreeNodeData objects for testing.
// ---------------------------------------------------------------------------

TechTreeNodeData _node(String id, Offset position,
    {TechTreeNodeScale scale = TechTreeNodeScale.minor}) {
  return TechTreeNodeData(
    id: id,
    kind: TechTreeNodeKind.upgrade,
    scale: scale,
    position: position,
    title: id,
    subtitle: '',
    description: '',
    eraId: 'era_1',
    icon: '✦',
    cost: const GameNumber.zero(),
    costLabel: '0',
    effectLabel: '',
    requirementLabel: '',
    dependencyLabel: '',
    progressLabel: '0/5',
    locked: false,
    affordable: true,
    purchased: false,
    highlighted: false,
  );
}

// Re-implement the viewport culling logic here so it can be unit-tested
// without spinning up a Flutter widget tree.  The real implementation is
// in _TechTreeViewState; keeping the logic in a separate free function
// makes it easy to verify independently.
Rect _computeVisibleWorldRect(Matrix4 m, Size viewport,
    {double margin = 280.0}) {
  final scaleX = m.storage[0];
  if (scaleX <= 0) return Rect.largest;
  final tx = m.storage[12];
  final ty = m.storage[13];
  return Rect.fromLTRB(
    -tx / scaleX - margin,
    -ty / scaleX - margin,
    (viewport.width - tx) / scaleX + margin,
    (viewport.height - ty) / scaleX + margin,
  );
}

bool _isNodeVisible(TechTreeNodeData node, Rect visibleWorldRect) {
  if (visibleWorldRect == Rect.largest) return true;
  final r = switch (node.scale) {
    TechTreeNodeScale.minor => 76.0,
    TechTreeNodeScale.major => 102.0,
    TechTreeNodeScale.milestone => 128.0,
  };
  final nodeBounds = Rect.fromCenter(
    center: node.position,
    width: r,
    height: r,
  );
  return visibleWorldRect.overlaps(nodeBounds);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const viewport = Size(1200, 700);

  group('_computeVisibleWorldRect', () {
    test('identity matrix gives viewport-sized rect (+ margin)', () {
      final m = Matrix4.identity();
      final rect = _computeVisibleWorldRect(m, viewport, margin: 0);
      expect(rect.left, closeTo(0, 0.01));
      expect(rect.top, closeTo(0, 0.01));
      expect(rect.right, closeTo(viewport.width, 0.01));
      expect(rect.bottom, closeTo(viewport.height, 0.01));
    });

    test('margin is added correctly', () {
      const margin = 200.0;
      final m = Matrix4.identity();
      final rect = _computeVisibleWorldRect(m, viewport, margin: margin);
      expect(rect.left, closeTo(-margin, 0.01));
      expect(rect.top, closeTo(-margin, 0.01));
      expect(rect.right, closeTo(viewport.width + margin, 0.01));
      expect(rect.bottom, closeTo(viewport.height + margin, 0.01));
    });

    test('pure translation moves visible rect', () {
      // Panning right by 400px means world origin is now off-screen to the left
      final m = Matrix4.identity()..setTranslationRaw(400, 0, 0);
      final rect = _computeVisibleWorldRect(m, viewport, margin: 0);
      // worldLeft = -400/1.0 = -400
      expect(rect.left, closeTo(-400, 0.01));
      // worldRight = (1200 - 400)/1.0 = 800
      expect(rect.right, closeTo(800, 0.01));
    });

    test('zoom-in (scale > 1) shrinks visible world rect', () {
      const zoom = 2.0;
      final m = Matrix4.identity()..scale(zoom, zoom, 1.0);
      final rect = _computeVisibleWorldRect(m, viewport, margin: 0);
      // At scale 2 and no translation: worldRight = 1200/2 = 600
      expect(rect.right, closeTo(viewport.width / zoom, 0.01));
      expect(rect.bottom, closeTo(viewport.height / zoom, 0.01));
    });

    test('zoom-out (scale < 1) enlarges visible world rect', () {
      const zoom = 0.5;
      final m = Matrix4.identity()..scale(zoom, zoom, 1.0);
      final rect = _computeVisibleWorldRect(m, viewport, margin: 0);
      // worldRight = 1200/0.5 = 2400
      expect(rect.right, closeTo(viewport.width / zoom, 0.01));
    });

    test('returns Rect.largest when scale is zero', () {
      final m = Matrix4.zero();
      final rect = _computeVisibleWorldRect(m, viewport);
      expect(rect, equals(Rect.largest));
    });
  });

  group('Node visibility culling', () {
    test('node inside visible rect is visible', () {
      final node = _node('n1', const Offset(300, 350));
      final visibleRect =
          const Rect.fromLTRB(-100, -100, 1400, 900);
      expect(_isNodeVisible(node, visibleRect), isTrue);
    });

    test('node far outside visible rect is not visible', () {
      final node = _node('n1', const Offset(2000, 350));
      final visibleRect =
          const Rect.fromLTRB(-100, -100, 1000, 900);
      expect(_isNodeVisible(node, visibleRect), isFalse);
    });

    test('node at visible rect edge (radius overlap) is visible', () {
      // Minor node: radius=76, so it extends 38px from center.
      // Place center 30px outside rect edge → bounding box just overlaps.
      final visibleRect = const Rect.fromLTRB(0, 0, 1200, 700);
      final node = _node('n1', Offset(1200 + 30, 350));
      // nodeBounds extends from 1200+30-38 = 1192 to 1200+30+38 = 1268
      // visibleRect.right = 1200, so nodeBounds.left=1192 < 1200 → overlaps
      expect(_isNodeVisible(node, visibleRect), isTrue);
    });

    test('node completely outside visible rect by more than its radius is not visible', () {
      final visibleRect = const Rect.fromLTRB(0, 0, 1200, 700);
      // Place center > 38px (minor radius/2) beyond right edge
      final node = _node('n1', Offset(1200 + 50, 350));
      // nodeBounds: [1212, 312, 1300, 388] — left=1212 > 1200 → no overlap
      expect(_isNodeVisible(node, visibleRect), isFalse);
    });

    test('Rect.largest makes all nodes visible (initial state)', () {
      final node = _node('n1', const Offset(99999, 99999));
      expect(_isNodeVisible(node, Rect.largest), isTrue);
    });

    test('milestone node has larger bbox than minor node', () {
      final minor = _node('m', const Offset(0, 0));
      final milestone = _node('ms', const Offset(0, 0),
          scale: TechTreeNodeScale.milestone);
      // Milestone bbox (128x128) is bigger than minor (76x76),
      // so it's visible from a smaller distance from the rect edge.
      final rect = const Rect.fromLTRB(0, 0, 100, 100);
      // minor center at (0,0): bbox [-38..38, -38..38] → overlaps [0..100]
      expect(_isNodeVisible(minor, rect), isTrue);
      // milestone center at (0,0): bbox [-64..64, -64..64] → overlaps [0..100]
      expect(_isNodeVisible(milestone, rect), isTrue);
    });

    test('only visible nodes in a large graph are culled correctly', () {
      // Simulate a 200-node graph and check that most are culled at default
      // viewport/zoom (showing roughly the first 1000px of world width).
      final nodes = List.generate(200, (i) {
        final x = 470.0 + (i % 20) * 92.0; // spread over 0..1840px x range
        const y = 490.0;
        return _node('n$i', Offset(x, y));
      });
      final visibleRect = const Rect.fromLTRB(-280, -280, 1480, 980);
      final visible = nodes.where((n) => _isNodeVisible(n, visibleRect)).length;
      // Only nodes with x between -280+38 and 1480-38, i.e. roughly x < 1442
      // With x = 470 + i*92: i*92 < 972 → i < ~10.6 → first ~11 per branch row
      // We have 5 branch rows but they all sit at the same x for this test,
      // so this is actually 200 nodes at 200 x positions, only some visible.
      expect(visible, lessThan(nodes.length));
      expect(visible, greaterThan(0));
    });
  });

  group('PerformanceBudget validation', () {
    test('upgradeNodeCountOk passes for 200 nodes (standard)', () {
      expect(PerformanceBudget.upgradeNodeCountOk(200), isTrue);
    });

    test('upgradeNodeCountOk fails when over limit', () {
      expect(
          PerformanceBudget.upgradeNodeCountOk(
              PerformanceBudget.maxUpgradeNodesPerEra + 1),
          isFalse);
    });

    test('eventPoolSizeOk passes for 11 events (standard)', () {
      expect(PerformanceBudget.eventPoolSizeOk(11), isTrue);
    });

    test('eventPoolSizeOk fails when over limit', () {
      expect(
          PerformanceBudget.eventPoolSizeOk(
              PerformanceBudget.maxEventsPerEra + 1),
          isFalse);
    });

    test('connectionCountOk passes for 210 connections', () {
      expect(PerformanceBudget.connectionCountOk(210), isTrue);
    });

    test('ambientAudioLayerCountOk passes for 3 layers', () {
      expect(PerformanceBudget.ambientAudioLayerCountOk(3), isTrue);
    });

    test('ambientAudioLayerCountOk fails for 4 layers', () {
      expect(PerformanceBudget.ambientAudioLayerCountOk(4), isFalse);
    });

    test('overlayCountOk passes for 4 overlays', () {
      expect(PerformanceBudget.overlayCountOk(4), isTrue);
    });

    test('overlayCountOk fails for 5 overlays', () {
      expect(PerformanceBudget.overlayCountOk(5), isFalse);
    });
  });
}
