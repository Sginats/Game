import 'package:ai_evolution/domain/models/route_faction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RouteArchetype has expected values', () {
    expect(RouteArchetype.values.length, 7);
    expect(RouteArchetype.operator.name, 'operator');
    expect(RouteArchetype.transcendence.name, 'transcendence');
  });

  test('RouteDefinition serializes and deserializes', () {
    const def = RouteDefinition(
      id: 'route_operator',
      name: 'Operator Path',
      description: 'An active, hands-on approach.',
      archetype: RouteArchetype.operator,
      bonusType: 'tapMultiplier',
      bonusMagnitude: 1.5,
      specialUpgradeIds: ['upg_op_1', 'upg_op_2'],
      eventPoolModifiers: {'rare': 1.2, 'legendary': 0.8},
      dialogueVariant: 'direct',
      prestigeRewardModifier: 1.1,
      exclusiveSecretIds: ['secret_op_1'],
    );

    final json = def.toJson();
    final restored = RouteDefinition.fromJson(json);

    expect(restored.id, 'route_operator');
    expect(restored.archetype, RouteArchetype.operator);
    expect(restored.bonusType, 'tapMultiplier');
    expect(restored.bonusMagnitude, 1.5);
    expect(restored.specialUpgradeIds.length, 2);
    expect(restored.eventPoolModifiers['rare'], 1.2);
    expect(restored.dialogueVariant, 'direct');
    expect(restored.prestigeRewardModifier, 1.1);
    expect(restored.exclusiveSecretIds, contains('secret_op_1'));
  });

  test('RouteDefinition defaults work', () {
    const def = RouteDefinition(
      id: 'route_minimal',
      name: 'Minimal',
      description: 'Test.',
      archetype: RouteArchetype.research,
      bonusType: 'production',
      bonusMagnitude: 1.0,
      dialogueVariant: 'neutral',
    );

    expect(def.specialUpgradeIds, isEmpty);
    expect(def.eventPoolModifiers, isEmpty);
    expect(def.prestigeRewardModifier, 1.0);
    expect(def.exclusiveSecretIds, isEmpty);
  });

  test('RouteProgress serializes and deserializes', () {
    final embarked = DateTime(2026, 3, 1);
    final progress = RouteProgress(
      routeId: 'route_operator',
      affinityScore: 75.0,
      tier: 3,
      roomsCompletedOnRoute: ['room_01', 'room_02', 'room_03'],
      respecsUsed: 1,
      active: true,
      embarkedAt: embarked,
    );

    final json = progress.toJson();
    final restored = RouteProgress.fromJson(json);

    expect(restored.routeId, 'route_operator');
    expect(restored.affinityScore, 75.0);
    expect(restored.tier, 3);
    expect(restored.roomsCompletedOnRoute.length, 3);
    expect(restored.respecsUsed, 1);
    expect(restored.active, isTrue);
    expect(restored.embarkedAt, isNotNull);
  });

  test('RouteProgress defaults are initial values', () {
    const progress = RouteProgress(routeId: 'route_test');
    expect(progress.affinityScore, 0);
    expect(progress.tier, 0);
    expect(progress.roomsCompletedOnRoute, isEmpty);
    expect(progress.respecsUsed, 0);
    expect(progress.active, isFalse);
    expect(progress.embarkedAt, isNull);
  });

  test('RouteProgress copyWith preserves unmodified fields', () {
    const progress = RouteProgress(
      routeId: 'route_op',
      affinityScore: 50.0,
      tier: 2,
      active: true,
    );
    final updated = progress.copyWith(tier: 3);
    expect(updated.tier, 3);
    expect(updated.affinityScore, 50.0);
    expect(updated.active, isTrue);
    expect(progress.tier, 2);
  });

  test('RouteState serializes and deserializes', () {
    const state = RouteState(
      activeRouteId: 'route_operator',
      routeProgresses: [
        RouteProgress(
          routeId: 'route_operator',
          affinityScore: 50.0,
          tier: 2,
          active: true,
        ),
      ],
      totalRespecTokens: 2,
      routeHistory: ['route_anomaly', 'route_operator'],
    );

    final json = state.toJson();
    final restored = RouteState.fromJson(json);

    expect(restored.activeRouteId, 'route_operator');
    expect(restored.routeProgresses.length, 1);
    expect(restored.routeProgresses.first.affinityScore, 50.0);
    expect(restored.totalRespecTokens, 2);
    expect(restored.routeHistory.length, 2);
  });

  test('RouteState defaults are empty', () {
    const state = RouteState();
    expect(state.activeRouteId, isNull);
    expect(state.routeProgresses, isEmpty);
    expect(state.totalRespecTokens, 3);
    expect(state.routeHistory, isEmpty);
  });

  test('RouteState copyWith works', () {
    const state = RouteState(totalRespecTokens: 3);
    final updated = state.copyWith(activeRouteId: 'route_swarm');
    expect(updated.activeRouteId, 'route_swarm');
    expect(updated.totalRespecTokens, 3);
  });
}
