// Domain models for the route/faction identity system.
//
// Routes represent distinct AI evolution philosophies that the player
// can pursue. Each route provides unique bonuses, unlocks exclusive
// upgrades and secrets, and shapes the guide dialogue style.

// ─── Enums ──────────────────────────────────────────────────────────

/// Archetype defining the core philosophy of a route.
enum RouteArchetype {
  operator,
  automation,
  anomaly,
  swarm,
  research,
  stealth,
  transcendence,
  containment,
  salvage,
  stability,
}

// ─── Value Classes ──────────────────────────────────────────────────

/// Static definition of a route describing its identity and effects.
class RouteDefinition {
  final String id;
  final String name;
  final String description;
  final RouteArchetype archetype;
  final String bonusType;
  final double bonusMagnitude;
  final List<String> specialUpgradeIds;
  final Map<String, double> eventPoolModifiers;
  final String dialogueVariant;
  final double prestigeRewardModifier;
  final List<String> exclusiveSecretIds;

  const RouteDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.archetype,
    required this.bonusType,
    required this.bonusMagnitude,
    this.specialUpgradeIds = const [],
    this.eventPoolModifiers = const {},
    required this.dialogueVariant,
    this.prestigeRewardModifier = 1.0,
    this.exclusiveSecretIds = const [],
  });

  RouteDefinition copyWith({
    String? id,
    String? name,
    String? description,
    RouteArchetype? archetype,
    String? bonusType,
    double? bonusMagnitude,
    List<String>? specialUpgradeIds,
    Map<String, double>? eventPoolModifiers,
    String? dialogueVariant,
    double? prestigeRewardModifier,
    List<String>? exclusiveSecretIds,
  }) {
    return RouteDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      archetype: archetype ?? this.archetype,
      bonusType: bonusType ?? this.bonusType,
      bonusMagnitude: bonusMagnitude ?? this.bonusMagnitude,
      specialUpgradeIds: specialUpgradeIds ?? this.specialUpgradeIds,
      eventPoolModifiers: eventPoolModifiers ?? this.eventPoolModifiers,
      dialogueVariant: dialogueVariant ?? this.dialogueVariant,
      prestigeRewardModifier:
          prestigeRewardModifier ?? this.prestigeRewardModifier,
      exclusiveSecretIds: exclusiveSecretIds ?? this.exclusiveSecretIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'archetype': archetype.name,
        'bonusType': bonusType,
        'bonusMagnitude': bonusMagnitude,
        'specialUpgradeIds': specialUpgradeIds,
        'eventPoolModifiers': eventPoolModifiers,
        'dialogueVariant': dialogueVariant,
        'prestigeRewardModifier': prestigeRewardModifier,
        'exclusiveSecretIds': exclusiveSecretIds,
      };

  factory RouteDefinition.fromJson(Map<String, dynamic> json) {
    return RouteDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      archetype: json['archetype'] != null
          ? RouteArchetype.values.firstWhere(
              (value) => value.name == json['archetype'],
              orElse: () => RouteArchetype.operator,
            )
          : RouteArchetype.operator,
      bonusType: json['bonusType'] as String,
      bonusMagnitude: (json['bonusMagnitude'] as num?)?.toDouble() ?? 0.0,
      specialUpgradeIds:
          (json['specialUpgradeIds'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
      eventPoolModifiers:
          (json['eventPoolModifiers'] as Map<String, dynamic>? ?? const {})
              .map((key, value) =>
                  MapEntry(key, (value as num).toDouble())),
      dialogueVariant: json['dialogueVariant'] as String,
      prestigeRewardModifier:
          (json['prestigeRewardModifier'] as num?)?.toDouble() ?? 1.0,
      exclusiveSecretIds:
          (json['exclusiveSecretIds'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
    );
  }
}

/// Player's progress on a specific route.
class RouteProgress {
  final String routeId;
  final double affinityScore;
  final int tier;
  final List<String> roomsCompletedOnRoute;
  final int respecsUsed;
  final bool active;
  final DateTime? embarkedAt;

  const RouteProgress({
    required this.routeId,
    this.affinityScore = 0,
    this.tier = 0,
    this.roomsCompletedOnRoute = const [],
    this.respecsUsed = 0,
    this.active = false,
    this.embarkedAt,
  });

  RouteProgress copyWith({
    String? routeId,
    double? affinityScore,
    int? tier,
    List<String>? roomsCompletedOnRoute,
    int? respecsUsed,
    bool? active,
    DateTime? embarkedAt,
  }) {
    return RouteProgress(
      routeId: routeId ?? this.routeId,
      affinityScore: affinityScore ?? this.affinityScore,
      tier: tier ?? this.tier,
      roomsCompletedOnRoute:
          roomsCompletedOnRoute ?? this.roomsCompletedOnRoute,
      respecsUsed: respecsUsed ?? this.respecsUsed,
      active: active ?? this.active,
      embarkedAt: embarkedAt ?? this.embarkedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'routeId': routeId,
        'affinityScore': affinityScore,
        'tier': tier,
        'roomsCompletedOnRoute': roomsCompletedOnRoute,
        'respecsUsed': respecsUsed,
        'active': active,
        'embarkedAt': embarkedAt?.toIso8601String(),
      };

  factory RouteProgress.fromJson(Map<String, dynamic> json) {
    return RouteProgress(
      routeId: json['routeId'] as String,
      affinityScore: (json['affinityScore'] as num?)?.toDouble() ?? 0,
      tier: json['tier'] as int? ?? 0,
      roomsCompletedOnRoute:
          (json['roomsCompletedOnRoute'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
      respecsUsed: json['respecsUsed'] as int? ?? 0,
      active: json['active'] as bool? ?? false,
      embarkedAt: json['embarkedAt'] != null
          ? DateTime.parse(json['embarkedAt'] as String)
          : null,
    );
  }
}

// ─── Aggregate State ────────────────────────────────────────────────

/// Aggregate state tracking all route-related progression.
class RouteState {
  final String? activeRouteId;
  final List<RouteProgress> routeProgresses;
  final int totalRespecTokens;
  final List<String> routeHistory;

  const RouteState({
    this.activeRouteId,
    this.routeProgresses = const [],
    this.totalRespecTokens = 3,
    this.routeHistory = const [],
  });

  RouteState copyWith({
    String? activeRouteId,
    List<RouteProgress>? routeProgresses,
    int? totalRespecTokens,
    List<String>? routeHistory,
  }) {
    return RouteState(
      activeRouteId: activeRouteId ?? this.activeRouteId,
      routeProgresses: routeProgresses ?? this.routeProgresses,
      totalRespecTokens: totalRespecTokens ?? this.totalRespecTokens,
      routeHistory: routeHistory ?? this.routeHistory,
    );
  }

  factory RouteState.fromJson(Map<String, dynamic> json) {
    return RouteState(
      activeRouteId: json['activeRouteId'] as String?,
      routeProgresses:
          (json['routeProgresses'] as List<dynamic>? ?? const [])
              .map((e) =>
                  RouteProgress.fromJson(e as Map<String, dynamic>))
              .toList(),
      totalRespecTokens: json['totalRespecTokens'] as int? ?? 3,
      routeHistory: (json['routeHistory'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'activeRouteId': activeRouteId,
        'routeProgresses':
            routeProgresses.map((e) => e.toJson()).toList(),
        'totalRespecTokens': totalRespecTokens,
        'routeHistory': routeHistory,
      };
}
