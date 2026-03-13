enum SceneEventCategory {
  instant,
  shortChoice,
  timedChain,
  utility,
  secretTrigger,
  legendaryAnomaly,
  warningRisk,
  miniBoss,
  guideAdvisory,
  hiddenGlitch,
}

enum EventRewardType {
  instantCurrency,
  temporaryBuff,
  comboAmplification,
  cooldownChange,
  rareResource,
  secretClue,
  hiddenBranchProgress,
  routeReward,
  relicFragment,
  guideAffinity,
  codexEntry,
  environmentTrigger,
}

class SceneEventReward {
  final EventRewardType type;
  final double value;
  final String description;
  final String? targetId;

  const SceneEventReward({
    required this.type,
    required this.value,
    required this.description,
    this.targetId,
  });

  SceneEventReward copyWith({
    EventRewardType? type,
    double? value,
    String? description,
    String? targetId,
  }) {
    return SceneEventReward(
      type: type ?? this.type,
      value: value ?? this.value,
      description: description ?? this.description,
      targetId: targetId ?? this.targetId,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'value': value,
        'description': description,
        'targetId': targetId,
      };

  factory SceneEventReward.fromJson(Map<String, dynamic> json) {
    return SceneEventReward(
      type: EventRewardType.values.firstWhere(
        (value) => value.name == json['type'],
      ),
      value: (json['value'] as num).toDouble(),
      description: json['description'] as String,
      targetId: json['targetId'] as String?,
    );
  }
}

class SceneEventChoice {
  final String id;
  final String text;
  final String description;
  final List<SceneEventReward> rewards;
  final double risk;
  final String? requirementDescription;

  const SceneEventChoice({
    required this.id,
    required this.text,
    required this.description,
    this.rewards = const [],
    this.risk = 0,
    this.requirementDescription,
  });

  SceneEventChoice copyWith({
    String? id,
    String? text,
    String? description,
    List<SceneEventReward>? rewards,
    double? risk,
    String? requirementDescription,
  }) {
    return SceneEventChoice(
      id: id ?? this.id,
      text: text ?? this.text,
      description: description ?? this.description,
      rewards: rewards ?? this.rewards,
      risk: risk ?? this.risk,
      requirementDescription:
          requirementDescription ?? this.requirementDescription,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'description': description,
        'rewards': rewards.map((e) => e.toJson()).toList(),
        'risk': risk,
        'requirementDescription': requirementDescription,
      };

  factory SceneEventChoice.fromJson(Map<String, dynamic> json) {
    return SceneEventChoice(
      id: json['id'] as String,
      text: json['text'] as String,
      description: json['description'] as String,
      rewards: (json['rewards'] as List<dynamic>? ?? const [])
          .map((e) => SceneEventReward.fromJson(e as Map<String, dynamic>))
          .toList(),
      risk: (json['risk'] as num?)?.toDouble() ?? 0,
      requirementDescription: json['requirementDescription'] as String?,
    );
  }
}

class SceneEventDefinition {
  final String id;
  final String roomId;
  final String title;
  final String description;
  final String flavorText;
  final SceneEventCategory category;
  final String rarity;
  final double durationSeconds;
  final List<SceneEventChoice> choices;
  final List<SceneEventReward> rewards;
  final double chainBonus;
  final bool requiredTwistActive;
  final int requiredUpgradeCount;
  final int weight;

  const SceneEventDefinition({
    required this.id,
    required this.roomId,
    required this.title,
    required this.description,
    this.flavorText = '',
    required this.category,
    this.rarity = 'common',
    this.durationSeconds = 0,
    this.choices = const [],
    this.rewards = const [],
    this.chainBonus = 0,
    this.requiredTwistActive = false,
    this.requiredUpgradeCount = 0,
    this.weight = 1,
  });

  SceneEventDefinition copyWith({
    String? id,
    String? roomId,
    String? title,
    String? description,
    String? flavorText,
    SceneEventCategory? category,
    String? rarity,
    double? durationSeconds,
    List<SceneEventChoice>? choices,
    List<SceneEventReward>? rewards,
    double? chainBonus,
    bool? requiredTwistActive,
    int? requiredUpgradeCount,
    int? weight,
  }) {
    return SceneEventDefinition(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      description: description ?? this.description,
      flavorText: flavorText ?? this.flavorText,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      choices: choices ?? this.choices,
      rewards: rewards ?? this.rewards,
      chainBonus: chainBonus ?? this.chainBonus,
      requiredTwistActive: requiredTwistActive ?? this.requiredTwistActive,
      requiredUpgradeCount: requiredUpgradeCount ?? this.requiredUpgradeCount,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'title': title,
        'description': description,
        'flavorText': flavorText,
        'category': category.name,
        'rarity': rarity,
        'durationSeconds': durationSeconds,
        'choices': choices.map((e) => e.toJson()).toList(),
        'rewards': rewards.map((e) => e.toJson()).toList(),
        'chainBonus': chainBonus,
        'requiredTwistActive': requiredTwistActive,
        'requiredUpgradeCount': requiredUpgradeCount,
        'weight': weight,
      };

  factory SceneEventDefinition.fromJson(Map<String, dynamic> json) {
    return SceneEventDefinition(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      flavorText: json['flavorText'] as String? ?? '',
      category: SceneEventCategory.values.firstWhere(
        (value) => value.name == json['category'],
      ),
      rarity: json['rarity'] as String? ?? 'common',
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0,
      choices: (json['choices'] as List<dynamic>? ?? const [])
          .map((e) => SceneEventChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      rewards: (json['rewards'] as List<dynamic>? ?? const [])
          .map((e) => SceneEventReward.fromJson(e as Map<String, dynamic>))
          .toList(),
      chainBonus: (json['chainBonus'] as num?)?.toDouble() ?? 0,
      requiredTwistActive: json['requiredTwistActive'] as bool? ?? false,
      requiredUpgradeCount: json['requiredUpgradeCount'] as int? ?? 0,
      weight: json['weight'] as int? ?? 1,
    );
  }
}

class SceneEventPool {
  final String roomId;
  final List<SceneEventDefinition> events;
  final double chainBonusMultiplier;
  final int pityThreshold;
  final double spawnRateMultiplier;
  final List<SceneEventDefinition> midTwistEvents;

  const SceneEventPool({
    required this.roomId,
    this.events = const [],
    this.chainBonusMultiplier = 1.0,
    this.pityThreshold = 0,
    this.spawnRateMultiplier = 1.0,
    this.midTwistEvents = const [],
  });

  SceneEventPool copyWith({
    String? roomId,
    List<SceneEventDefinition>? events,
    double? chainBonusMultiplier,
    int? pityThreshold,
    double? spawnRateMultiplier,
    List<SceneEventDefinition>? midTwistEvents,
  }) {
    return SceneEventPool(
      roomId: roomId ?? this.roomId,
      events: events ?? this.events,
      chainBonusMultiplier: chainBonusMultiplier ?? this.chainBonusMultiplier,
      pityThreshold: pityThreshold ?? this.pityThreshold,
      spawnRateMultiplier: spawnRateMultiplier ?? this.spawnRateMultiplier,
      midTwistEvents: midTwistEvents ?? this.midTwistEvents,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'events': events.map((e) => e.toJson()).toList(),
        'chainBonusMultiplier': chainBonusMultiplier,
        'pityThreshold': pityThreshold,
        'spawnRateMultiplier': spawnRateMultiplier,
        'midTwistEvents': midTwistEvents.map((e) => e.toJson()).toList(),
      };

  factory SceneEventPool.fromJson(Map<String, dynamic> json) {
    return SceneEventPool(
      roomId: json['roomId'] as String,
      events: (json['events'] as List<dynamic>? ?? const [])
          .map((e) =>
              SceneEventDefinition.fromJson(e as Map<String, dynamic>))
          .toList(),
      chainBonusMultiplier:
          (json['chainBonusMultiplier'] as num?)?.toDouble() ?? 1.0,
      pityThreshold: json['pityThreshold'] as int? ?? 0,
      spawnRateMultiplier:
          (json['spawnRateMultiplier'] as num?)?.toDouble() ?? 1.0,
      midTwistEvents: (json['midTwistEvents'] as List<dynamic>? ?? const [])
          .map((e) =>
              SceneEventDefinition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EventChainState {
  final int currentChain;
  final int bestChain;
  final double chainMultiplier;
  final DateTime? lastEventTime;

  const EventChainState({
    this.currentChain = 0,
    this.bestChain = 0,
    this.chainMultiplier = 1.0,
    this.lastEventTime,
  });

  EventChainState copyWith({
    int? currentChain,
    int? bestChain,
    double? chainMultiplier,
    DateTime? lastEventTime,
  }) {
    return EventChainState(
      currentChain: currentChain ?? this.currentChain,
      bestChain: bestChain ?? this.bestChain,
      chainMultiplier: chainMultiplier ?? this.chainMultiplier,
      lastEventTime: lastEventTime ?? this.lastEventTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentChain': currentChain,
        'bestChain': bestChain,
        'chainMultiplier': chainMultiplier,
        'lastEventTime': lastEventTime?.toIso8601String(),
      };

  factory EventChainState.fromJson(Map<String, dynamic> json) {
    return EventChainState(
      currentChain: json['currentChain'] as int? ?? 0,
      bestChain: json['bestChain'] as int? ?? 0,
      chainMultiplier: (json['chainMultiplier'] as num?)?.toDouble() ?? 1.0,
      lastEventTime: json['lastEventTime'] != null
          ? DateTime.parse(json['lastEventTime'] as String)
          : null,
    );
  }
}
