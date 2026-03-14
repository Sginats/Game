import 'package:ai_evolution/application/services/route_service.dart';
import 'package:ai_evolution/domain/models/route_faction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RouteService service;

  setUp(() {
    service = RouteService(jsonList: [
      {
        'id': 'route_operator',
        'name': 'Operator Path',
        'description': 'Active hands-on approach.',
        'archetype': 'operator',
        'bonusType': 'tapMultiplier',
        'bonusMagnitude': 1.5,
        'specialUpgradeIds': ['upg_op_1'],
        'eventPoolModifiers': {'rare': 1.2},
        'dialogueVariant': 'direct',
        'prestigeRewardModifier': 1.1,
        'exclusiveSecretIds': ['secret_op_1'],
      },
      {
        'id': 'route_anomaly',
        'name': 'Anomaly Path',
        'description': 'Embrace chaos.',
        'archetype': 'anomaly',
        'bonusType': 'eventRewardMultiplier',
        'bonusMagnitude': 1.6,
        'specialUpgradeIds': [],
        'eventPoolModifiers': {'legendary': 1.5},
        'dialogueVariant': 'chaotic',
        'prestigeRewardModifier': 1.2,
        'exclusiveSecretIds': [],
      },
    ]);
  });

  test('loads definitions from JSON', () {
    expect(service.totalDefinitions, 2);
  });

  test('getDefinition returns correct route', () {
    final def = service.getDefinition('route_operator');
    expect(def, isNotNull);
    expect(def!.name, 'Operator Path');
    expect(def.archetype, RouteArchetype.operator);
    expect(def.bonusMagnitude, 1.5);
  });

  test('getDefinition returns null for unknown id', () {
    expect(service.getDefinition('unknown'), isNull);
  });

  test('getDefinitionByArchetype works', () {
    final def = service.getDefinitionByArchetype(RouteArchetype.anomaly);
    expect(def, isNotNull);
    expect(def!.id, 'route_anomaly');
  });

  test('getDefinitionByArchetype returns null if not found', () {
    expect(service.getDefinitionByArchetype(RouteArchetype.stealth), isNull);
  });

  test('allDefinitions returns all loaded routes', () {
    expect(service.allDefinitions.length, 2);
  });

  test('getActiveRoute returns route from state', () {
    const state = RouteState(activeRouteId: 'route_operator');
    final active = service.getActiveRoute(state);
    expect(active, isNotNull);
    expect(active!.name, 'Operator Path');
  });

  test('getActiveRoute returns null when no active route', () {
    const state = RouteState();
    expect(service.getActiveRoute(state), isNull);
  });

  test('getRouteProgress returns correct progress', () {
    const state = RouteState(
      routeProgresses: [
        RouteProgress(routeId: 'route_operator', affinityScore: 50.0),
        RouteProgress(routeId: 'route_anomaly', affinityScore: 30.0),
      ],
    );

    final progress = service.getRouteProgress(state, 'route_operator');
    expect(progress, isNotNull);
    expect(progress!.affinityScore, 50.0);
  });

  test('canRespec checks tokens', () {
    const hasTokens = RouteState(totalRespecTokens: 2);
    expect(service.canRespec(hasTokens), isTrue);

    const noTokens = RouteState(totalRespecTokens: 0);
    expect(service.canRespec(noTokens), isFalse);
  });

  test('getEventPoolModifiers returns modifiers from active route', () {
    const state = RouteState(activeRouteId: 'route_operator');
    final modifiers = service.getEventPoolModifiers(state);
    expect(modifiers['rare'], 1.2);
  });

  test('getEventPoolModifiers returns empty when no active route', () {
    const state = RouteState();
    expect(service.getEventPoolModifiers(state), isEmpty);
  });

  test('getPrestigeRewardModifier returns modifier from active route', () {
    const state = RouteState(activeRouteId: 'route_anomaly');
    expect(service.getPrestigeRewardModifier(state), 1.2);
  });

  test('getPrestigeRewardModifier returns 1.0 when no active route', () {
    const state = RouteState();
    expect(service.getPrestigeRewardModifier(state), 1.0);
  });
}
