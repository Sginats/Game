// Room/Scene domain models for the 20-room incremental game.
//
// Each room represents a distinct environment with its own mechanics,
// visual theme, audio layers, secrets, and transformation stages.

/// Mechanic emphasis that defines the primary gameplay style of a room.
enum RoomMechanicEmphasis {
  tap,
  automation,
  hybrid,
  event,
  combo,
  heat,
  maintenance,
  signal,
  temporal,
  synthesis,
}

/// Theme colors for a room expressed as hex strings.
class RoomThemeColor {
  final String primary;
  final String accent;
  final String background;

  const RoomThemeColor({
    required this.primary,
    required this.accent,
    required this.background,
  });

  factory RoomThemeColor.fromJson(Map<String, dynamic> json) {
    return RoomThemeColor(
      primary: json['primary'] as String,
      accent: json['accent'] as String,
      background: json['background'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'primary': primary,
        'accent': accent,
        'background': background,
      };
}

/// A visible environment evolution stage within a room.
class TransformationStage {
  final String id;
  final String name;
  final String description;
  final int requiredUpgrades;
  final List<String> environmentChanges;
  final bool unlocked;

  const TransformationStage({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredUpgrades,
    this.environmentChanges = const [],
    this.unlocked = false,
  });

  TransformationStage copyWith({
    String? id,
    String? name,
    String? description,
    int? requiredUpgrades,
    List<String>? environmentChanges,
    bool? unlocked,
  }) {
    return TransformationStage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      requiredUpgrades: requiredUpgrades ?? this.requiredUpgrades,
      environmentChanges: environmentChanges ?? this.environmentChanges,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'requiredUpgrades': requiredUpgrades,
        'environmentChanges': environmentChanges,
        'unlocked': unlocked,
      };

  factory TransformationStage.fromJson(Map<String, dynamic> json) {
    return TransformationStage(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      requiredUpgrades: json['requiredUpgrades'] as int,
      environmentChanges:
          (json['environmentChanges'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
      unlocked: json['unlocked'] as bool? ?? false,
    );
  }
}

/// An ambient audio layer that plays within a room.
class AmbientAudioLayer {
  final String id;
  final String name;
  final String assetPath;
  final double volume;
  final String triggerCondition;
  final bool looping;

  const AmbientAudioLayer({
    required this.id,
    required this.name,
    required this.assetPath,
    this.volume = 1.0,
    this.triggerCondition = 'always',
    this.looping = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'assetPath': assetPath,
        'volume': volume,
        'triggerCondition': triggerCondition,
        'looping': looping,
      };

  factory AmbientAudioLayer.fromJson(Map<String, dynamic> json) {
    return AmbientAudioLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      assetPath: json['assetPath'] as String,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      triggerCondition: json['triggerCondition'] as String? ?? 'always',
      looping: json['looping'] as bool? ?? true,
    );
  }
}

/// A hidden secret the player can discover within a room.
class RoomSecret {
  final String id;
  final String title;
  final String description;
  final String hint;
  final String clueSource;
  final String rewardType;
  final String rewardValue;
  final bool discovered;

  const RoomSecret({
    required this.id,
    required this.title,
    required this.description,
    required this.hint,
    required this.clueSource,
    required this.rewardType,
    required this.rewardValue,
    this.discovered = false,
  });

  RoomSecret copyWith({
    String? id,
    String? title,
    String? description,
    String? hint,
    String? clueSource,
    String? rewardType,
    String? rewardValue,
    bool? discovered,
  }) {
    return RoomSecret(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hint: hint ?? this.hint,
      clueSource: clueSource ?? this.clueSource,
      rewardType: rewardType ?? this.rewardType,
      rewardValue: rewardValue ?? this.rewardValue,
      discovered: discovered ?? this.discovered,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'hint': hint,
        'clueSource': clueSource,
        'rewardType': rewardType,
        'rewardValue': rewardValue,
        'discovered': discovered,
      };

  factory RoomSecret.fromJson(Map<String, dynamic> json) {
    return RoomSecret(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      hint: json['hint'] as String,
      clueSource: json['clueSource'] as String,
      rewardType: json['rewardType'] as String,
      rewardValue: json['rewardValue'] as String,
      discovered: json['discovered'] as bool? ?? false,
    );
  }
}

/// A mid-scene twist that changes gameplay when triggered.
class MidSceneTwist {
  final String id;
  final String title;
  final String description;
  final String triggerCondition;
  final String effectDescription;
  final bool activated;

  const MidSceneTwist({
    required this.id,
    required this.title,
    required this.description,
    required this.triggerCondition,
    required this.effectDescription,
    this.activated = false,
  });

  MidSceneTwist copyWith({
    String? id,
    String? title,
    String? description,
    String? triggerCondition,
    String? effectDescription,
    bool? activated,
  }) {
    return MidSceneTwist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      triggerCondition: triggerCondition ?? this.triggerCondition,
      effectDescription: effectDescription ?? this.effectDescription,
      activated: activated ?? this.activated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'triggerCondition': triggerCondition,
        'effectDescription': effectDescription,
        'activated': activated,
      };

  factory MidSceneTwist.fromJson(Map<String, dynamic> json) {
    return MidSceneTwist(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      triggerCondition: json['triggerCondition'] as String,
      effectDescription: json['effectDescription'] as String,
      activated: json['activated'] as bool? ?? false,
    );
  }
}

/// Main room/scene definition describing a single game room.
class RoomScene {
  final String id;
  final String name;
  final String subtitle;
  final int order;
  final String introText;
  final String completionText;
  final String guideTone;
  final String guideIntroLine;
  final String currency;
  final RoomMechanicEmphasis mechanicEmphasis;
  final RoomThemeColor themeColors;
  final List<TransformationStage> transformationStages;
  final List<AmbientAudioLayer> ambientAudioLayers;
  final List<RoomSecret> secrets;
  final MidSceneTwist? midSceneTwist;
  final String eventPoolId;
  final List<String> upgradeCategories;
  final List<String> loreEntries;
  final String? unlockRequirement;
  final bool completed;
  final int currentTransformationStage;
  final String? sideActivityId;
  final List<String> companionAffinityIds;
  final String? routeBonus;

  const RoomScene({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.order,
    required this.introText,
    required this.completionText,
    required this.guideTone,
    required this.guideIntroLine,
    required this.currency,
    this.mechanicEmphasis = RoomMechanicEmphasis.tap,
    required this.themeColors,
    this.transformationStages = const [],
    this.ambientAudioLayers = const [],
    this.secrets = const [],
    this.midSceneTwist,
    required this.eventPoolId,
    this.upgradeCategories = const [],
    this.loreEntries = const [],
    this.unlockRequirement,
    this.completed = false,
    this.currentTransformationStage = 0,
    this.sideActivityId,
    this.companionAffinityIds = const [],
    this.routeBonus,
  });

  RoomScene copyWith({
    String? id,
    String? name,
    String? subtitle,
    int? order,
    String? introText,
    String? completionText,
    String? guideTone,
    String? guideIntroLine,
    String? currency,
    RoomMechanicEmphasis? mechanicEmphasis,
    RoomThemeColor? themeColors,
    List<TransformationStage>? transformationStages,
    List<AmbientAudioLayer>? ambientAudioLayers,
    List<RoomSecret>? secrets,
    MidSceneTwist? midSceneTwist,
    String? eventPoolId,
    List<String>? upgradeCategories,
    List<String>? loreEntries,
    String? unlockRequirement,
    bool? completed,
    int? currentTransformationStage,
    String? sideActivityId,
    List<String>? companionAffinityIds,
    String? routeBonus,
  }) {
    return RoomScene(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      order: order ?? this.order,
      introText: introText ?? this.introText,
      completionText: completionText ?? this.completionText,
      guideTone: guideTone ?? this.guideTone,
      guideIntroLine: guideIntroLine ?? this.guideIntroLine,
      currency: currency ?? this.currency,
      mechanicEmphasis: mechanicEmphasis ?? this.mechanicEmphasis,
      themeColors: themeColors ?? this.themeColors,
      transformationStages:
          transformationStages ?? this.transformationStages,
      ambientAudioLayers: ambientAudioLayers ?? this.ambientAudioLayers,
      secrets: secrets ?? this.secrets,
      midSceneTwist: midSceneTwist ?? this.midSceneTwist,
      eventPoolId: eventPoolId ?? this.eventPoolId,
      upgradeCategories: upgradeCategories ?? this.upgradeCategories,
      loreEntries: loreEntries ?? this.loreEntries,
      unlockRequirement: unlockRequirement ?? this.unlockRequirement,
      completed: completed ?? this.completed,
      currentTransformationStage:
          currentTransformationStage ?? this.currentTransformationStage,
      sideActivityId: sideActivityId ?? this.sideActivityId,
      companionAffinityIds: companionAffinityIds ?? this.companionAffinityIds,
      routeBonus: routeBonus ?? this.routeBonus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'order': order,
        'introText': introText,
        'completionText': completionText,
        'guideTone': guideTone,
        'guideIntroLine': guideIntroLine,
        'currency': currency,
        'mechanicEmphasis': mechanicEmphasis.name,
        'themeColors': themeColors.toJson(),
        'transformationStages':
            transformationStages.map((s) => s.toJson()).toList(),
        'ambientAudioLayers':
            ambientAudioLayers.map((a) => a.toJson()).toList(),
        'secrets': secrets.map((s) => s.toJson()).toList(),
        'midSceneTwist': midSceneTwist?.toJson(),
        'eventPoolId': eventPoolId,
        'upgradeCategories': upgradeCategories,
        'loreEntries': loreEntries,
        'unlockRequirement': unlockRequirement,
        'completed': completed,
        'currentTransformationStage': currentTransformationStage,
        'sideActivityId': sideActivityId,
        'companionAffinityIds': companionAffinityIds,
        'routeBonus': routeBonus,
      };

  factory RoomScene.fromJson(Map<String, dynamic> json) {
    return RoomScene(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String,
      order: json['order'] as int,
      introText: json['introText'] as String,
      completionText: json['completionText'] as String,
      guideTone: json['guideTone'] as String,
      guideIntroLine: json['guideIntroLine'] as String,
      currency: json['currency'] as String,
      mechanicEmphasis: json['mechanicEmphasis'] != null
          ? RoomMechanicEmphasis.values.firstWhere(
              (value) => value.name == json['mechanicEmphasis'],
              orElse: () => RoomMechanicEmphasis.tap,
            )
          : RoomMechanicEmphasis.tap,
      themeColors:
          RoomThemeColor.fromJson(json['themeColors'] as Map<String, dynamic>),
      transformationStages:
          (json['transformationStages'] as List<dynamic>? ?? const [])
              .map((e) =>
                  TransformationStage.fromJson(e as Map<String, dynamic>))
              .toList(),
      ambientAudioLayers:
          (json['ambientAudioLayers'] as List<dynamic>? ?? const [])
              .map(
                  (e) => AmbientAudioLayer.fromJson(e as Map<String, dynamic>))
              .toList(),
      secrets: (json['secrets'] as List<dynamic>? ?? const [])
          .map((e) => RoomSecret.fromJson(e as Map<String, dynamic>))
          .toList(),
      midSceneTwist: json['midSceneTwist'] != null
          ? MidSceneTwist.fromJson(
              json['midSceneTwist'] as Map<String, dynamic>)
          : null,
      eventPoolId: json['eventPoolId'] as String,
      upgradeCategories:
          (json['upgradeCategories'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
      loreEntries: (json['loreEntries'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      unlockRequirement: json['unlockRequirement'] as String?,
      completed: json['completed'] as bool? ?? false,
      currentTransformationStage:
          json['currentTransformationStage'] as int? ?? 0,
      sideActivityId: json['sideActivityId'] as String?,
      companionAffinityIds:
          (json['companionAffinityIds'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
      routeBonus: json['routeBonus'] as String?,
    );
  }
}

/// Runtime state tracking progress within a single room.
class RoomSceneState {
  final String roomId;
  final bool completed;
  final int currentTransformationStage;
  final Set<String> secretsDiscovered;
  final bool twistActivated;
  final int upgradesPurchased;
  final int eventsCompleted;
  final int bestChain;
  final int masteryRank;
  final int sideActivityCompletions;
  final int companionTokensEarned;
  final Set<String> questsCompleted;

  const RoomSceneState({
    required this.roomId,
    this.completed = false,
    this.currentTransformationStage = 0,
    this.secretsDiscovered = const {},
    this.twistActivated = false,
    this.upgradesPurchased = 0,
    this.eventsCompleted = 0,
    this.bestChain = 0,
    this.masteryRank = 0,
    this.sideActivityCompletions = 0,
    this.companionTokensEarned = 0,
    this.questsCompleted = const {},
  });

  RoomSceneState copyWith({
    String? roomId,
    bool? completed,
    int? currentTransformationStage,
    Set<String>? secretsDiscovered,
    bool? twistActivated,
    int? upgradesPurchased,
    int? eventsCompleted,
    int? bestChain,
    int? masteryRank,
    int? sideActivityCompletions,
    int? companionTokensEarned,
    Set<String>? questsCompleted,
  }) {
    return RoomSceneState(
      roomId: roomId ?? this.roomId,
      completed: completed ?? this.completed,
      currentTransformationStage:
          currentTransformationStage ?? this.currentTransformationStage,
      secretsDiscovered: secretsDiscovered ?? this.secretsDiscovered,
      twistActivated: twistActivated ?? this.twistActivated,
      upgradesPurchased: upgradesPurchased ?? this.upgradesPurchased,
      eventsCompleted: eventsCompleted ?? this.eventsCompleted,
      bestChain: bestChain ?? this.bestChain,
      masteryRank: masteryRank ?? this.masteryRank,
      sideActivityCompletions:
          sideActivityCompletions ?? this.sideActivityCompletions,
      companionTokensEarned:
          companionTokensEarned ?? this.companionTokensEarned,
      questsCompleted: questsCompleted ?? this.questsCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'completed': completed,
        'currentTransformationStage': currentTransformationStage,
        'secretsDiscovered': secretsDiscovered.toList(),
        'twistActivated': twistActivated,
        'upgradesPurchased': upgradesPurchased,
        'eventsCompleted': eventsCompleted,
        'bestChain': bestChain,
        'masteryRank': masteryRank,
        'sideActivityCompletions': sideActivityCompletions,
        'companionTokensEarned': companionTokensEarned,
        'questsCompleted': questsCompleted.toList(),
      };

  factory RoomSceneState.fromJson(Map<String, dynamic> json) {
    return RoomSceneState(
      roomId: json['roomId'] as String,
      completed: json['completed'] as bool? ?? false,
      currentTransformationStage:
          json['currentTransformationStage'] as int? ?? 0,
      secretsDiscovered:
          (json['secretsDiscovered'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toSet(),
      twistActivated: json['twistActivated'] as bool? ?? false,
      upgradesPurchased: json['upgradesPurchased'] as int? ?? 0,
      eventsCompleted: json['eventsCompleted'] as int? ?? 0,
      bestChain: json['bestChain'] as int? ?? 0,
      masteryRank: json['masteryRank'] as int? ?? 0,
      sideActivityCompletions:
          json['sideActivityCompletions'] as int? ?? 0,
      companionTokensEarned:
          json['companionTokensEarned'] as int? ?? 0,
      questsCompleted:
          (json['questsCompleted'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toSet(),
    );
  }
}
