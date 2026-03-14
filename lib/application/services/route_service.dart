import 'package:ai_evolution/domain/models/route_faction.dart';

/// Service that loads, manages, and queries route/faction definitions and
/// player route state.
/// Pure Dart — no Flutter imports.
///
/// Route definitions are parsed eagerly from JSON on [loadDefinitions] and
/// cached in an internal map for O(1) lookups by id.
class RouteService {
  /// Parsed [RouteDefinition] cache keyed by route id.
  final Map<String, RouteDefinition> _definitions = {};

  /// Whether [loadDefinitions] has been called.
  bool _initialized = false;

  /// Creates the service.
  ///
  /// Optionally accepts [jsonList] to initialize immediately.
  /// If omitted, call [loadDefinitions] before accessing data.
  RouteService({List<Map<String, dynamic>>? jsonList}) {
    if (jsonList != null) {
      loadDefinitions(jsonList);
    }
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Populate the service with route definition JSON maps parsed from config.
  ///
  /// Each map is expected to contain at least an `id` key.  Entries missing
  /// required keys are silently skipped.
  void loadDefinitions(List<Map<String, dynamic>> jsonList) {
    _definitions.clear();

    for (final json in jsonList) {
      final id = json['id'];
      if (id is! String) continue;

      final definition = RouteDefinition.fromJson(json);
      _definitions[definition.id] = definition;
    }

    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Definition accessors
  // ---------------------------------------------------------------------------

  /// Returns the [RouteDefinition] with the given [id], or `null` if not
  /// found.
  RouteDefinition? getDefinition(String id) {
    if (!_initialized) return null;
    return _definitions[id];
  }

  /// Returns the first [RouteDefinition] whose archetype matches
  /// [archetype], or `null` if none match.
  RouteDefinition? getDefinitionByArchetype(RouteArchetype archetype) {
    if (!_initialized) return null;
    for (final definition in _definitions.values) {
      if (definition.archetype == archetype) return definition;
    }
    return null;
  }

  /// All loaded route definitions.
  List<RouteDefinition> get allDefinitions {
    if (!_initialized) return const [];
    return _definitions.values.toList();
  }

  /// Total number of route definitions registered in the service.
  int get totalDefinitions => _definitions.length;

  // ---------------------------------------------------------------------------
  // State-based queries
  // ---------------------------------------------------------------------------

  /// Returns the [RouteDefinition] for the player's currently active route,
  /// or `null` if no route is active or the id is unknown.
  RouteDefinition? getActiveRoute(RouteState state) {
    if (!_initialized) return null;
    final activeId = state.activeRouteId;
    if (activeId == null) return null;
    return _definitions[activeId];
  }

  /// Returns the [RouteProgress] for the given [routeId] within [state],
  /// or `null` if the player has no progress on that route.
  RouteProgress? getRouteProgress(RouteState state, String routeId) {
    for (final progress in state.routeProgresses) {
      if (progress.routeId == routeId) return progress;
    }
    return null;
  }

  /// Whether the player has at least one respec token available.
  bool canRespec(RouteState state) {
    return state.totalRespecTokens > 0;
  }

  /// Returns the event-pool modifiers from the player's active route
  /// definition, or an empty map if no route is active.
  Map<String, double> getEventPoolModifiers(RouteState state) {
    final route = getActiveRoute(state);
    if (route == null) return const {};
    return route.eventPoolModifiers;
  }

  /// Returns the prestige-reward modifier from the player's active route
  /// definition, or `1.0` (neutral) if no route is active.
  double getPrestigeRewardModifier(RouteState state) {
    final route = getActiveRoute(state);
    if (route == null) return 1.0;
    return route.prestigeRewardModifier;
  }
}
