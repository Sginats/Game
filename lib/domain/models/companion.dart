// Domain models for the companion/helper unit system.
//
// Companions are AI-themed helper units (drones, bots, daemons, etc.)
// that assist the player with automation, token generation, and bonuses.
// They can be evolved, fused, and collected in sets for extra rewards.

// ─── Enums ──────────────────────────────────────────────────────────

enum CompanionType {
  drone,
  helperBot,
  daemon,
  swarmModule,
  subAI,
  signalConstruct,
  roboticAssistant,
}

enum CompanionRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

// ─── Value Classes ──────────────────────────────────────────────────

class CompanionTrait {
  final String id;
  final String name;
  final String description;
  final String effectType;
  final double magnitude;

  const CompanionTrait({
    required this.id,
    required this.name,
    required this.description,
    required this.effectType,
    required this.magnitude,
  });

  CompanionTrait copyWith({
    String? id,
    String? name,
    String? description,
    String? effectType,
    double? magnitude,
  }) {
    return CompanionTrait(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      effectType: effectType ?? this.effectType,
      magnitude: magnitude ?? this.magnitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'effectType': effectType,
        'magnitude': magnitude,
      };

  factory CompanionTrait.fromJson(Map<String, dynamic> json) {
    return CompanionTrait(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      effectType: json['effectType'] as String,
      magnitude: (json['magnitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CompanionAbility {
  final String id;
  final String name;
  final String description;
  final double cooldownSeconds;
  final String tokenGenerationType;
  final double tokenAmount;

  const CompanionAbility({
    required this.id,
    required this.name,
    required this.description,
    required this.cooldownSeconds,
    required this.tokenGenerationType,
    required this.tokenAmount,
  });

  CompanionAbility copyWith({
    String? id,
    String? name,
    String? description,
    double? cooldownSeconds,
    String? tokenGenerationType,
    double? tokenAmount,
  }) {
    return CompanionAbility(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      tokenGenerationType: tokenGenerationType ?? this.tokenGenerationType,
      tokenAmount: tokenAmount ?? this.tokenAmount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'cooldownSeconds': cooldownSeconds,
        'tokenGenerationType': tokenGenerationType,
        'tokenAmount': tokenAmount,
      };

  factory CompanionAbility.fromJson(Map<String, dynamic> json) {
    return CompanionAbility(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      cooldownSeconds: (json['cooldownSeconds'] as num?)?.toDouble() ?? 0.0,
      tokenGenerationType: json['tokenGenerationType'] as String,
      tokenAmount: (json['tokenAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─── Definition Classes ─────────────────────────────────────────────

class CompanionDefinition {
  final String id;
  final String name;
  final String description;
  final CompanionType type;
  final CompanionRarity rarity;
  final String sceneAffinity;
  final List<CompanionTrait> traits;
  final List<CompanionAbility> abilities;
  final int evolutionStage;
  final int maxEvolutionStage;
  final String collectionGroup;
  final double automationRate;
  final double resourceBonusPercent;
  final bool fusionMaterial;
  final String unlockMethod;

  const CompanionDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.sceneAffinity,
    this.traits = const [],
    this.abilities = const [],
    this.evolutionStage = 1,
    this.maxEvolutionStage = 5,
    required this.collectionGroup,
    required this.automationRate,
    required this.resourceBonusPercent,
    this.fusionMaterial = false,
    required this.unlockMethod,
  });

  CompanionDefinition copyWith({
    String? id,
    String? name,
    String? description,
    CompanionType? type,
    CompanionRarity? rarity,
    String? sceneAffinity,
    List<CompanionTrait>? traits,
    List<CompanionAbility>? abilities,
    int? evolutionStage,
    int? maxEvolutionStage,
    String? collectionGroup,
    double? automationRate,
    double? resourceBonusPercent,
    bool? fusionMaterial,
    String? unlockMethod,
  }) {
    return CompanionDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      sceneAffinity: sceneAffinity ?? this.sceneAffinity,
      traits: traits ?? this.traits,
      abilities: abilities ?? this.abilities,
      evolutionStage: evolutionStage ?? this.evolutionStage,
      maxEvolutionStage: maxEvolutionStage ?? this.maxEvolutionStage,
      collectionGroup: collectionGroup ?? this.collectionGroup,
      automationRate: automationRate ?? this.automationRate,
      resourceBonusPercent: resourceBonusPercent ?? this.resourceBonusPercent,
      fusionMaterial: fusionMaterial ?? this.fusionMaterial,
      unlockMethod: unlockMethod ?? this.unlockMethod,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'rarity': rarity.name,
        'sceneAffinity': sceneAffinity,
        'traits': traits.map((e) => e.toJson()).toList(),
        'abilities': abilities.map((e) => e.toJson()).toList(),
        'evolutionStage': evolutionStage,
        'maxEvolutionStage': maxEvolutionStage,
        'collectionGroup': collectionGroup,
        'automationRate': automationRate,
        'resourceBonusPercent': resourceBonusPercent,
        'fusionMaterial': fusionMaterial,
        'unlockMethod': unlockMethod,
      };

  factory CompanionDefinition.fromJson(Map<String, dynamic> json) {
    return CompanionDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: CompanionType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => CompanionType.drone,
      ),
      rarity: CompanionRarity.values.firstWhere(
        (value) => value.name == json['rarity'],
        orElse: () => CompanionRarity.common,
      ),
      sceneAffinity: json['sceneAffinity'] as String,
      traits: (json['traits'] as List<dynamic>? ?? const [])
          .map((e) => CompanionTrait.fromJson(e as Map<String, dynamic>))
          .toList(),
      abilities: (json['abilities'] as List<dynamic>? ?? const [])
          .map((e) => CompanionAbility.fromJson(e as Map<String, dynamic>))
          .toList(),
      evolutionStage: json['evolutionStage'] as int? ?? 1,
      maxEvolutionStage: json['maxEvolutionStage'] as int? ?? 5,
      collectionGroup: json['collectionGroup'] as String,
      automationRate: (json['automationRate'] as num?)?.toDouble() ?? 0.0,
      resourceBonusPercent:
          (json['resourceBonusPercent'] as num?)?.toDouble() ?? 0.0,
      fusionMaterial: json['fusionMaterial'] as bool? ?? false,
      unlockMethod: json['unlockMethod'] as String,
    );
  }
}

// ─── Runtime State ──────────────────────────────────────────────────

class CompanionState {
  final String definitionId;
  final int level;
  final double experience;
  final int evolutionStage;
  final bool equipped;
  final Map<String, double> abilityCooldowns;
  final int tokensGenerated;
  final bool acquired;

  const CompanionState({
    required this.definitionId,
    this.level = 1,
    this.experience = 0.0,
    this.evolutionStage = 1,
    this.equipped = false,
    this.abilityCooldowns = const {},
    this.tokensGenerated = 0,
    this.acquired = false,
  });

  CompanionState copyWith({
    String? definitionId,
    int? level,
    double? experience,
    int? evolutionStage,
    bool? equipped,
    Map<String, double>? abilityCooldowns,
    int? tokensGenerated,
    bool? acquired,
  }) {
    return CompanionState(
      definitionId: definitionId ?? this.definitionId,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      evolutionStage: evolutionStage ?? this.evolutionStage,
      equipped: equipped ?? this.equipped,
      abilityCooldowns: abilityCooldowns ?? this.abilityCooldowns,
      tokensGenerated: tokensGenerated ?? this.tokensGenerated,
      acquired: acquired ?? this.acquired,
    );
  }

  Map<String, dynamic> toJson() => {
        'definitionId': definitionId,
        'level': level,
        'experience': experience,
        'evolutionStage': evolutionStage,
        'equipped': equipped,
        'abilityCooldowns': abilityCooldowns,
        'tokensGenerated': tokensGenerated,
        'acquired': acquired,
      };

  factory CompanionState.fromJson(Map<String, dynamic> json) {
    return CompanionState(
      definitionId: json['definitionId'] as String,
      level: json['level'] as int? ?? 1,
      experience: (json['experience'] as num?)?.toDouble() ?? 0.0,
      evolutionStage: json['evolutionStage'] as int? ?? 1,
      equipped: json['equipped'] as bool? ?? false,
      abilityCooldowns:
          (json['abilityCooldowns'] as Map<String, dynamic>? ?? const {})
              .map((key, value) => MapEntry(key, (value as num).toDouble())),
      tokensGenerated: json['tokensGenerated'] as int? ?? 0,
      acquired: json['acquired'] as bool? ?? false,
    );
  }
}

// ─── Collection Bonuses ─────────────────────────────────────────────

class CompanionCollectionBonus {
  final String id;
  final String name;
  final String description;
  final List<String> requiredCompanionIds;
  final String bonusType;
  final double bonusMagnitude;
  final bool fulfilled;

  const CompanionCollectionBonus({
    required this.id,
    required this.name,
    required this.description,
    this.requiredCompanionIds = const [],
    required this.bonusType,
    required this.bonusMagnitude,
    this.fulfilled = false,
  });

  CompanionCollectionBonus copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? requiredCompanionIds,
    String? bonusType,
    double? bonusMagnitude,
    bool? fulfilled,
  }) {
    return CompanionCollectionBonus(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      requiredCompanionIds: requiredCompanionIds ?? this.requiredCompanionIds,
      bonusType: bonusType ?? this.bonusType,
      bonusMagnitude: bonusMagnitude ?? this.bonusMagnitude,
      fulfilled: fulfilled ?? this.fulfilled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'requiredCompanionIds': requiredCompanionIds,
        'bonusType': bonusType,
        'bonusMagnitude': bonusMagnitude,
        'fulfilled': fulfilled,
      };

  factory CompanionCollectionBonus.fromJson(Map<String, dynamic> json) {
    return CompanionCollectionBonus(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      requiredCompanionIds:
          (json['requiredCompanionIds'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
      bonusType: json['bonusType'] as String,
      bonusMagnitude: (json['bonusMagnitude'] as num?)?.toDouble() ?? 0.0,
      fulfilled: json['fulfilled'] as bool? ?? false,
    );
  }
}

// ─── Aggregate State ────────────────────────────────────────────────

class CompanionSystemState {
  final List<CompanionState> ownedCompanions;
  final int activeSlots;
  final List<CompanionCollectionBonus> collectionBonuses;
  final int totalTokensGenerated;
  final int fusionCount;

  const CompanionSystemState({
    this.ownedCompanions = const [],
    this.activeSlots = 3,
    this.collectionBonuses = const [],
    this.totalTokensGenerated = 0,
    this.fusionCount = 0,
  });

  CompanionSystemState copyWith({
    List<CompanionState>? ownedCompanions,
    int? activeSlots,
    List<CompanionCollectionBonus>? collectionBonuses,
    int? totalTokensGenerated,
    int? fusionCount,
  }) {
    return CompanionSystemState(
      ownedCompanions: ownedCompanions ?? this.ownedCompanions,
      activeSlots: activeSlots ?? this.activeSlots,
      collectionBonuses: collectionBonuses ?? this.collectionBonuses,
      totalTokensGenerated: totalTokensGenerated ?? this.totalTokensGenerated,
      fusionCount: fusionCount ?? this.fusionCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'ownedCompanions':
            ownedCompanions.map((e) => e.toJson()).toList(),
        'activeSlots': activeSlots,
        'collectionBonuses':
            collectionBonuses.map((e) => e.toJson()).toList(),
        'totalTokensGenerated': totalTokensGenerated,
        'fusionCount': fusionCount,
      };

  factory CompanionSystemState.fromJson(Map<String, dynamic> json) {
    return CompanionSystemState(
      ownedCompanions:
          (json['ownedCompanions'] as List<dynamic>? ?? const [])
              .map((e) =>
                  CompanionState.fromJson(e as Map<String, dynamic>))
              .toList(),
      activeSlots: json['activeSlots'] as int? ?? 3,
      collectionBonuses:
          (json['collectionBonuses'] as List<dynamic>? ?? const [])
              .map((e) => CompanionCollectionBonus.fromJson(
                  e as Map<String, dynamic>))
              .toList(),
      totalTokensGenerated: json['totalTokensGenerated'] as int? ?? 0,
      fusionCount: json['fusionCount'] as int? ?? 0,
    );
  }
}
