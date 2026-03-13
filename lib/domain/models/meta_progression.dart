/// Domain models for the meta-progression system.
///
/// These models represent persistent cross-run unlockables, collectibles,
/// and progression tracking that survive prestige resets.

// ─── Enums ──────────────────────────────────────────────────────────

enum RelicRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

// ─── Value Classes ──────────────────────────────────────────────────

class RelicEffect {
  final String effectType;
  final String targetSystem;
  final double magnitude;
  final String description;

  const RelicEffect({
    required this.effectType,
    required this.targetSystem,
    required this.magnitude,
    required this.description,
  });

  factory RelicEffect.fromJson(Map<String, dynamic> json) {
    return RelicEffect(
      effectType: json['effectType'] as String,
      targetSystem: json['targetSystem'] as String,
      magnitude: (json['magnitude'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'effectType': effectType,
        'targetSystem': targetSystem,
        'magnitude': magnitude,
        'description': description,
      };
}

class Relic {
  final String id;
  final String name;
  final String description;
  final RelicRarity rarity;
  final List<RelicEffect> effects;
  final bool acquired;
  final String sourceDescription;

  const Relic({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.effects,
    this.acquired = false,
    required this.sourceDescription,
  });

  factory Relic.fromJson(Map<String, dynamic> json) {
    return Relic(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      rarity: RelicRarity.values.firstWhere(
        (value) => value.name == json['rarity'],
        orElse: () => RelicRarity.common,
      ),
      effects: (json['effects'] as List<dynamic>? ?? const [])
          .map((e) => RelicEffect.fromJson(e as Map<String, dynamic>))
          .toList(),
      acquired: json['acquired'] as bool? ?? false,
      sourceDescription: json['sourceDescription'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'rarity': rarity.name,
        'effects': effects.map((e) => e.toJson()).toList(),
        'acquired': acquired,
        'sourceDescription': sourceDescription,
      };
}

class MemoryFragment {
  final String id;
  final String title;
  final String content;
  final String sourceRoomId;
  final String sourceType;
  final DateTime? acquiredAt;
  final bool acquired;

  const MemoryFragment({
    required this.id,
    required this.title,
    required this.content,
    required this.sourceRoomId,
    required this.sourceType,
    this.acquiredAt,
    this.acquired = false,
  });

  factory MemoryFragment.fromJson(Map<String, dynamic> json) {
    return MemoryFragment(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      sourceRoomId: json['sourceRoomId'] as String,
      sourceType: json['sourceType'] as String,
      acquiredAt: json['acquiredAt'] != null
          ? DateTime.parse(json['acquiredAt'] as String)
          : null,
      acquired: json['acquired'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'sourceRoomId': sourceRoomId,
        'sourceType': sourceType,
        'acquiredAt': acquiredAt?.toIso8601String(),
        'acquired': acquired,
      };
}

class BlueprintShard {
  final String id;
  final String name;
  final String description;
  final String roomId;
  final String category;
  final int shardsRequired;
  final int shardsCollected;
  final bool completed;

  const BlueprintShard({
    required this.id,
    required this.name,
    required this.description,
    required this.roomId,
    required this.category,
    required this.shardsRequired,
    this.shardsCollected = 0,
    this.completed = false,
  });

  factory BlueprintShard.fromJson(Map<String, dynamic> json) {
    return BlueprintShard(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      roomId: json['roomId'] as String,
      category: json['category'] as String,
      shardsRequired: json['shardsRequired'] as int,
      shardsCollected: json['shardsCollected'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'roomId': roomId,
        'category': category,
        'shardsRequired': shardsRequired,
        'shardsCollected': shardsCollected,
        'completed': completed,
      };
}

class KernelShard {
  final String id;
  final String name;
  final String description;
  final double power;
  final String sourceDescription;

  const KernelShard({
    required this.id,
    required this.name,
    required this.description,
    required this.power,
    required this.sourceDescription,
  });

  factory KernelShard.fromJson(Map<String, dynamic> json) {
    return KernelShard(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      power: (json['power'] as num?)?.toDouble() ?? 0.0,
      sourceDescription: json['sourceDescription'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'power': power,
        'sourceDescription': sourceDescription,
      };
}

class RouteEmblem {
  final String id;
  final String routeId;
  final String name;
  final String description;
  final int tier;
  final bool earned;

  const RouteEmblem({
    required this.id,
    required this.routeId,
    required this.name,
    required this.description,
    required this.tier,
    this.earned = false,
  });

  factory RouteEmblem.fromJson(Map<String, dynamic> json) {
    return RouteEmblem(
      id: json['id'] as String,
      routeId: json['routeId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      tier: json['tier'] as int,
      earned: json['earned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeId': routeId,
        'name': name,
        'description': description,
        'tier': tier,
        'earned': earned,
      };
}

class SceneHeirloom {
  final String id;
  final String roomId;
  final String name;
  final String description;
  final String effectDescription;
  final bool unlocked;

  const SceneHeirloom({
    required this.id,
    required this.roomId,
    required this.name,
    required this.description,
    required this.effectDescription,
    this.unlocked = false,
  });

  factory SceneHeirloom.fromJson(Map<String, dynamic> json) {
    return SceneHeirloom(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      effectDescription: json['effectDescription'] as String,
      unlocked: json['unlocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'name': name,
        'description': description,
        'effectDescription': effectDescription,
        'unlocked': unlocked,
      };
}

// ─── Aggregate State ────────────────────────────────────────────────

class MetaProgressionState {
  final List<Relic> relics;
  final List<MemoryFragment> memoryFragments;
  final List<BlueprintShard> blueprintShards;
  final List<KernelShard> kernelShards;
  final List<RouteEmblem> routeEmblems;
  final List<SceneHeirloom> sceneHeirlooms;
  final int totalPrestigeTokens;
  final int lifetimePrestigeTokens;
  final Set<String> roomsCompleted;
  final Set<String> secretsArchived;
  final int challengesCleared;
  final Set<String> guideMilestones;

  const MetaProgressionState({
    this.relics = const [],
    this.memoryFragments = const [],
    this.blueprintShards = const [],
    this.kernelShards = const [],
    this.routeEmblems = const [],
    this.sceneHeirlooms = const [],
    this.totalPrestigeTokens = 0,
    this.lifetimePrestigeTokens = 0,
    this.roomsCompleted = const {},
    this.secretsArchived = const {},
    this.challengesCleared = 0,
    this.guideMilestones = const {},
  });

  MetaProgressionState copyWith({
    List<Relic>? relics,
    List<MemoryFragment>? memoryFragments,
    List<BlueprintShard>? blueprintShards,
    List<KernelShard>? kernelShards,
    List<RouteEmblem>? routeEmblems,
    List<SceneHeirloom>? sceneHeirlooms,
    int? totalPrestigeTokens,
    int? lifetimePrestigeTokens,
    Set<String>? roomsCompleted,
    Set<String>? secretsArchived,
    int? challengesCleared,
    Set<String>? guideMilestones,
  }) {
    return MetaProgressionState(
      relics: relics ?? this.relics,
      memoryFragments: memoryFragments ?? this.memoryFragments,
      blueprintShards: blueprintShards ?? this.blueprintShards,
      kernelShards: kernelShards ?? this.kernelShards,
      routeEmblems: routeEmblems ?? this.routeEmblems,
      sceneHeirlooms: sceneHeirlooms ?? this.sceneHeirlooms,
      totalPrestigeTokens: totalPrestigeTokens ?? this.totalPrestigeTokens,
      lifetimePrestigeTokens:
          lifetimePrestigeTokens ?? this.lifetimePrestigeTokens,
      roomsCompleted: roomsCompleted ?? this.roomsCompleted,
      secretsArchived: secretsArchived ?? this.secretsArchived,
      challengesCleared: challengesCleared ?? this.challengesCleared,
      guideMilestones: guideMilestones ?? this.guideMilestones,
    );
  }

  factory MetaProgressionState.fromJson(Map<String, dynamic> json) {
    return MetaProgressionState(
      relics: (json['relics'] as List<dynamic>? ?? const [])
          .map((e) => Relic.fromJson(e as Map<String, dynamic>))
          .toList(),
      memoryFragments:
          (json['memoryFragments'] as List<dynamic>? ?? const [])
              .map((e) =>
                  MemoryFragment.fromJson(e as Map<String, dynamic>))
              .toList(),
      blueprintShards:
          (json['blueprintShards'] as List<dynamic>? ?? const [])
              .map((e) =>
                  BlueprintShard.fromJson(e as Map<String, dynamic>))
              .toList(),
      kernelShards: (json['kernelShards'] as List<dynamic>? ?? const [])
          .map((e) => KernelShard.fromJson(e as Map<String, dynamic>))
          .toList(),
      routeEmblems: (json['routeEmblems'] as List<dynamic>? ?? const [])
          .map((e) => RouteEmblem.fromJson(e as Map<String, dynamic>))
          .toList(),
      sceneHeirlooms:
          (json['sceneHeirlooms'] as List<dynamic>? ?? const [])
              .map((e) =>
                  SceneHeirloom.fromJson(e as Map<String, dynamic>))
              .toList(),
      totalPrestigeTokens: json['totalPrestigeTokens'] as int? ?? 0,
      lifetimePrestigeTokens: json['lifetimePrestigeTokens'] as int? ?? 0,
      roomsCompleted:
          (json['roomsCompleted'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toSet(),
      secretsArchived:
          (json['secretsArchived'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toSet(),
      challengesCleared: json['challengesCleared'] as int? ?? 0,
      guideMilestones:
          (json['guideMilestones'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toSet(),
    );
  }

  Map<String, dynamic> toJson() => {
        'relics': relics.map((e) => e.toJson()).toList(),
        'memoryFragments': memoryFragments.map((e) => e.toJson()).toList(),
        'blueprintShards': blueprintShards.map((e) => e.toJson()).toList(),
        'kernelShards': kernelShards.map((e) => e.toJson()).toList(),
        'routeEmblems': routeEmblems.map((e) => e.toJson()).toList(),
        'sceneHeirlooms': sceneHeirlooms.map((e) => e.toJson()).toList(),
        'totalPrestigeTokens': totalPrestigeTokens,
        'lifetimePrestigeTokens': lifetimePrestigeTokens,
        'roomsCompleted': roomsCompleted.toList(),
        'secretsArchived': secretsArchived.toList(),
        'challengesCleared': challengesCleared,
        'guideMilestones': guideMilestones.toList(),
      };
}
