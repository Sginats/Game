// Post-core retention systems — domain models.
//
// These models power the retention, mastery, atmosphere, and long-term
// engagement systems layered on top of the core room progression.

// ─── 1. Room Mastery ────────────────────────────────────────────────

enum MasteryGoalType {
  fastestClear,
  highComboClear,
  secretClear,
  archiveComplete,
  noFailureClear,
  routeSpecific,
  challengeClear,
}

class RoomMasteryGoal {
  final String id;
  final String roomId;
  final MasteryGoalType type;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final bool completed;
  final String rewardType;
  final String rewardId;

  const RoomMasteryGoal({
    required this.id,
    required this.roomId,
    required this.type,
    required this.title,
    required this.description,
    required this.targetValue,
    this.currentValue = 0,
    this.completed = false,
    required this.rewardType,
    required this.rewardId,
  });

  RoomMasteryGoal copyWith({
    String? id,
    String? roomId,
    MasteryGoalType? type,
    String? title,
    String? description,
    int? targetValue,
    int? currentValue,
    bool? completed,
    String? rewardType,
    String? rewardId,
  }) {
    return RoomMasteryGoal(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      completed: completed ?? this.completed,
      rewardType: rewardType ?? this.rewardType,
      rewardId: rewardId ?? this.rewardId,
    );
  }

  factory RoomMasteryGoal.fromJson(Map<String, dynamic> json) {
    return RoomMasteryGoal(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      type: MasteryGoalType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MasteryGoalType.fastestClear,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      targetValue: json['targetValue'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      rewardType: json['rewardType'] as String,
      rewardId: json['rewardId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'type': type.name,
        'title': title,
        'description': description,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'completed': completed,
        'rewardType': rewardType,
        'rewardId': rewardId,
      };
}

class RoomMasteryProfile {
  final String roomId;
  final int starsEarned;
  final String rank;
  final List<RoomMasteryGoal> goals;
  final int bestClearTimeSeconds;
  final int bestCombo;
  final bool allSecretsFound;
  final bool archiveComplete;

  const RoomMasteryProfile({
    required this.roomId,
    this.starsEarned = 0,
    this.rank = 'bronze',
    this.goals = const [],
    this.bestClearTimeSeconds = 0,
    this.bestCombo = 0,
    this.allSecretsFound = false,
    this.archiveComplete = false,
  });

  RoomMasteryProfile copyWith({
    String? roomId,
    int? starsEarned,
    String? rank,
    List<RoomMasteryGoal>? goals,
    int? bestClearTimeSeconds,
    int? bestCombo,
    bool? allSecretsFound,
    bool? archiveComplete,
  }) {
    return RoomMasteryProfile(
      roomId: roomId ?? this.roomId,
      starsEarned: starsEarned ?? this.starsEarned,
      rank: rank ?? this.rank,
      goals: goals ?? this.goals,
      bestClearTimeSeconds:
          bestClearTimeSeconds ?? this.bestClearTimeSeconds,
      bestCombo: bestCombo ?? this.bestCombo,
      allSecretsFound: allSecretsFound ?? this.allSecretsFound,
      archiveComplete: archiveComplete ?? this.archiveComplete,
    );
  }

  factory RoomMasteryProfile.fromJson(Map<String, dynamic> json) {
    return RoomMasteryProfile(
      roomId: json['roomId'] as String,
      starsEarned: json['starsEarned'] as int? ?? 0,
      rank: json['rank'] as String? ?? 'bronze',
      goals: (json['goals'] as List<dynamic>? ?? const [])
          .map((e) => RoomMasteryGoal.fromJson(e as Map<String, dynamic>))
          .toList(),
      bestClearTimeSeconds: json['bestClearTimeSeconds'] as int? ?? 0,
      bestCombo: json['bestCombo'] as int? ?? 0,
      allSecretsFound: json['allSecretsFound'] as bool? ?? false,
      archiveComplete: json['archiveComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'starsEarned': starsEarned,
        'rank': rank,
        'goals': goals.map((e) => e.toJson()).toList(),
        'bestClearTimeSeconds': bestClearTimeSeconds,
        'bestCombo': bestCombo,
        'allSecretsFound': allSecretsFound,
        'archiveComplete': archiveComplete,
      };
}

// ─── 2. Guide Moods + Trust Branches ────────────────────────────────

enum GuideMood {
  calm,
  fascinated,
  worried,
  proud,
  suspicious,
  disappointed,
  hopeful,
}

enum GuideTrustPath {
  highTrust,
  lowTrust,
  conflicted,
  hidden,
}

class GuideSideObjective {
  final String id;
  final String title;
  final String description;
  final String condition;
  final bool completed;
  final String rewardDescription;

  const GuideSideObjective({
    required this.id,
    required this.title,
    required this.description,
    required this.condition,
    this.completed = false,
    required this.rewardDescription,
  });

  GuideSideObjective copyWith({
    String? id,
    String? title,
    String? description,
    String? condition,
    bool? completed,
    String? rewardDescription,
  }) {
    return GuideSideObjective(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      completed: completed ?? this.completed,
      rewardDescription: rewardDescription ?? this.rewardDescription,
    );
  }

  factory GuideSideObjective.fromJson(Map<String, dynamic> json) {
    return GuideSideObjective(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      condition: json['condition'] as String,
      completed: json['completed'] as bool? ?? false,
      rewardDescription: json['rewardDescription'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'condition': condition,
        'completed': completed,
        'rewardDescription': rewardDescription,
      };
}

class GuideState {
  final GuideMood currentMood;
  final GuideTrustPath trustPath;
  final int trustLevel;
  final double affinityScore;
  final List<GuideSideObjective> sideObjectives;
  final Set<String> completedObjectiveIds;
  final Map<String, int> behaviorCounters;
  final Set<String> unlockedDialogueBranches;

  const GuideState({
    this.currentMood = GuideMood.calm,
    this.trustPath = GuideTrustPath.highTrust,
    this.trustLevel = 1,
    this.affinityScore = 0.0,
    this.sideObjectives = const [],
    this.completedObjectiveIds = const {},
    this.behaviorCounters = const {},
    this.unlockedDialogueBranches = const {},
  });

  GuideState copyWith({
    GuideMood? currentMood,
    GuideTrustPath? trustPath,
    int? trustLevel,
    double? affinityScore,
    List<GuideSideObjective>? sideObjectives,
    Set<String>? completedObjectiveIds,
    Map<String, int>? behaviorCounters,
    Set<String>? unlockedDialogueBranches,
  }) {
    return GuideState(
      currentMood: currentMood ?? this.currentMood,
      trustPath: trustPath ?? this.trustPath,
      trustLevel: trustLevel ?? this.trustLevel,
      affinityScore: affinityScore ?? this.affinityScore,
      sideObjectives: sideObjectives ?? this.sideObjectives,
      completedObjectiveIds:
          completedObjectiveIds ?? this.completedObjectiveIds,
      behaviorCounters: behaviorCounters ?? this.behaviorCounters,
      unlockedDialogueBranches:
          unlockedDialogueBranches ?? this.unlockedDialogueBranches,
    );
  }

  factory GuideState.fromJson(Map<String, dynamic> json) {
    return GuideState(
      currentMood: GuideMood.values.firstWhere(
        (e) => e.name == json['currentMood'],
        orElse: () => GuideMood.calm,
      ),
      trustPath: GuideTrustPath.values.firstWhere(
        (e) => e.name == json['trustPath'],
        orElse: () => GuideTrustPath.highTrust,
      ),
      trustLevel: json['trustLevel'] as int? ?? 1,
      affinityScore:
          (json['affinityScore'] as num?)?.toDouble() ?? 0.0,
      sideObjectives:
          (json['sideObjectives'] as List<dynamic>? ?? const [])
              .map((e) =>
                  GuideSideObjective.fromJson(e as Map<String, dynamic>))
              .toList(),
      completedObjectiveIds:
          (json['completedObjectiveIds'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toSet(),
      behaviorCounters:
          (json['behaviorCounters'] as Map<String, dynamic>? ?? const {})
              .map((k, v) => MapEntry(k, v as int)),
      unlockedDialogueBranches:
          (json['unlockedDialogueBranches'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toSet(),
    );
  }

  Map<String, dynamic> toJson() => {
        'currentMood': currentMood.name,
        'trustPath': trustPath.name,
        'trustLevel': trustLevel,
        'affinityScore': affinityScore,
        'sideObjectives':
            sideObjectives.map((e) => e.toJson()).toList(),
        'completedObjectiveIds': completedObjectiveIds.toList(),
        'behaviorCounters': behaviorCounters,
        'unlockedDialogueBranches': unlockedDialogueBranches.toList(),
      };
}

// ─── 3. Cross-Room Relic Sets ───────────────────────────────────────

class RelicSetDefinition {
  final String id;
  final String name;
  final String description;
  final String theme;
  final List<String> requiredRelicIds;
  final String setBonusDescription;
  final String setBonusType;
  final double setBonusMagnitude;

  const RelicSetDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    this.requiredRelicIds = const [],
    required this.setBonusDescription,
    required this.setBonusType,
    this.setBonusMagnitude = 0.0,
  });

  RelicSetDefinition copyWith({
    String? id,
    String? name,
    String? description,
    String? theme,
    List<String>? requiredRelicIds,
    String? setBonusDescription,
    String? setBonusType,
    double? setBonusMagnitude,
  }) {
    return RelicSetDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      theme: theme ?? this.theme,
      requiredRelicIds: requiredRelicIds ?? this.requiredRelicIds,
      setBonusDescription:
          setBonusDescription ?? this.setBonusDescription,
      setBonusType: setBonusType ?? this.setBonusType,
      setBonusMagnitude: setBonusMagnitude ?? this.setBonusMagnitude,
    );
  }

  factory RelicSetDefinition.fromJson(Map<String, dynamic> json) {
    return RelicSetDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      theme: json['theme'] as String,
      requiredRelicIds:
          (json['requiredRelicIds'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
      setBonusDescription: json['setBonusDescription'] as String,
      setBonusType: json['setBonusType'] as String,
      setBonusMagnitude:
          (json['setBonusMagnitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'theme': theme,
        'requiredRelicIds': requiredRelicIds,
        'setBonusDescription': setBonusDescription,
        'setBonusType': setBonusType,
        'setBonusMagnitude': setBonusMagnitude,
      };
}

class RelicSetProgress {
  final String setId;
  final Set<String> collectedRelicIds;
  final bool completed;
  final bool bonusActive;

  const RelicSetProgress({
    required this.setId,
    this.collectedRelicIds = const {},
    this.completed = false,
    this.bonusActive = false,
  });

  RelicSetProgress copyWith({
    String? setId,
    Set<String>? collectedRelicIds,
    bool? completed,
    bool? bonusActive,
  }) {
    return RelicSetProgress(
      setId: setId ?? this.setId,
      collectedRelicIds: collectedRelicIds ?? this.collectedRelicIds,
      completed: completed ?? this.completed,
      bonusActive: bonusActive ?? this.bonusActive,
    );
  }

  factory RelicSetProgress.fromJson(Map<String, dynamic> json) {
    return RelicSetProgress(
      setId: json['setId'] as String,
      collectedRelicIds:
          (json['collectedRelicIds'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toSet(),
      completed: json['completed'] as bool? ?? false,
      bonusActive: json['bonusActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'setId': setId,
        'collectedRelicIds': collectedRelicIds.toList(),
        'completed': completed,
        'bonusActive': bonusActive,
      };
}

// ─── 4. Delayed-Consequence Events ─────────────────────────────────

enum ConsequenceTiming {
  laterInRoom,
  futureRoom,
  nextSession,
  afterRoomCompletion,
  duringArchiveReview,
}

class DelayedConsequence {
  final String id;
  final String sourceEventId;
  final String sourceRoomId;
  final String description;
  final ConsequenceTiming timing;
  final String? targetRoomId;
  final String outcomeType;
  final String outcomeDescription;
  final Map<String, dynamic> outcomeData;
  final bool resolved;
  final DateTime? createdAt;

  const DelayedConsequence({
    required this.id,
    required this.sourceEventId,
    required this.sourceRoomId,
    required this.description,
    required this.timing,
    this.targetRoomId,
    required this.outcomeType,
    required this.outcomeDescription,
    this.outcomeData = const {},
    this.resolved = false,
    this.createdAt,
  });

  DelayedConsequence copyWith({
    String? id,
    String? sourceEventId,
    String? sourceRoomId,
    String? description,
    ConsequenceTiming? timing,
    String? targetRoomId,
    String? outcomeType,
    String? outcomeDescription,
    Map<String, dynamic>? outcomeData,
    bool? resolved,
    DateTime? createdAt,
  }) {
    return DelayedConsequence(
      id: id ?? this.id,
      sourceEventId: sourceEventId ?? this.sourceEventId,
      sourceRoomId: sourceRoomId ?? this.sourceRoomId,
      description: description ?? this.description,
      timing: timing ?? this.timing,
      targetRoomId: targetRoomId ?? this.targetRoomId,
      outcomeType: outcomeType ?? this.outcomeType,
      outcomeDescription:
          outcomeDescription ?? this.outcomeDescription,
      outcomeData: outcomeData ?? this.outcomeData,
      resolved: resolved ?? this.resolved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DelayedConsequence.fromJson(Map<String, dynamic> json) {
    return DelayedConsequence(
      id: json['id'] as String,
      sourceEventId: json['sourceEventId'] as String,
      sourceRoomId: json['sourceRoomId'] as String,
      description: json['description'] as String,
      timing: ConsequenceTiming.values.firstWhere(
        (e) => e.name == json['timing'],
        orElse: () => ConsequenceTiming.futureRoom,
      ),
      targetRoomId: json['targetRoomId'] as String?,
      outcomeType: json['outcomeType'] as String,
      outcomeDescription: json['outcomeDescription'] as String,
      outcomeData:
          (json['outcomeData'] as Map<String, dynamic>?) ?? const {},
      resolved: json['resolved'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceEventId': sourceEventId,
        'sourceRoomId': sourceRoomId,
        'description': description,
        'timing': timing.name,
        'targetRoomId': targetRoomId,
        'outcomeType': outcomeType,
        'outcomeDescription': outcomeDescription,
        'outcomeData': outcomeData,
        'resolved': resolved,
        'createdAt': createdAt?.toIso8601String(),
      };
}

// ─── 5. Room Revisits / Late Unlocks ────────────────────────────────

class RevisitUnlock {
  final String id;
  final String roomId;
  final String title;
  final String description;
  final String triggerCondition;
  final String unlockType;
  final bool unlocked;
  final bool discovered;

  const RevisitUnlock({
    required this.id,
    required this.roomId,
    required this.title,
    required this.description,
    required this.triggerCondition,
    required this.unlockType,
    this.unlocked = false,
    this.discovered = false,
  });

  RevisitUnlock copyWith({
    String? id,
    String? roomId,
    String? title,
    String? description,
    String? triggerCondition,
    String? unlockType,
    bool? unlocked,
    bool? discovered,
  }) {
    return RevisitUnlock(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      description: description ?? this.description,
      triggerCondition: triggerCondition ?? this.triggerCondition,
      unlockType: unlockType ?? this.unlockType,
      unlocked: unlocked ?? this.unlocked,
      discovered: discovered ?? this.discovered,
    );
  }

  factory RevisitUnlock.fromJson(Map<String, dynamic> json) {
    return RevisitUnlock(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      triggerCondition: json['triggerCondition'] as String,
      unlockType: json['unlockType'] as String,
      unlocked: json['unlocked'] as bool? ?? false,
      discovered: json['discovered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'title': title,
        'description': description,
        'triggerCondition': triggerCondition,
        'unlockType': unlockType,
        'unlocked': unlocked,
        'discovered': discovered,
      };
}

// ─── 6. Archive/Codex Completion Rewards ────────────────────────────

class ArchiveCompletionReward {
  final String id;
  final String archiveSection;
  final int requiredEntries;
  final String rewardType;
  final String rewardDescription;
  final double rewardValue;
  final bool claimed;

  const ArchiveCompletionReward({
    required this.id,
    required this.archiveSection,
    required this.requiredEntries,
    required this.rewardType,
    required this.rewardDescription,
    this.rewardValue = 0.0,
    this.claimed = false,
  });

  ArchiveCompletionReward copyWith({
    String? id,
    String? archiveSection,
    int? requiredEntries,
    String? rewardType,
    String? rewardDescription,
    double? rewardValue,
    bool? claimed,
  }) {
    return ArchiveCompletionReward(
      id: id ?? this.id,
      archiveSection: archiveSection ?? this.archiveSection,
      requiredEntries: requiredEntries ?? this.requiredEntries,
      rewardType: rewardType ?? this.rewardType,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      rewardValue: rewardValue ?? this.rewardValue,
      claimed: claimed ?? this.claimed,
    );
  }

  factory ArchiveCompletionReward.fromJson(Map<String, dynamic> json) {
    return ArchiveCompletionReward(
      id: json['id'] as String,
      archiveSection: json['archiveSection'] as String,
      requiredEntries: json['requiredEntries'] as int,
      rewardType: json['rewardType'] as String,
      rewardDescription: json['rewardDescription'] as String,
      rewardValue:
          (json['rewardValue'] as num?)?.toDouble() ?? 0.0,
      claimed: json['claimed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'archiveSection': archiveSection,
        'requiredEntries': requiredEntries,
        'rewardType': rewardType,
        'rewardDescription': rewardDescription,
        'rewardValue': rewardValue,
        'claimed': claimed,
      };
}

// ─── 7. Micro-Life / Atmosphere ─────────────────────────────────────

class MicroLifeElement {
  final String id;
  final String roomId;
  final String elementType;
  final String description;
  final String triggerCondition;
  final double intensity;
  final bool reactive;

  const MicroLifeElement({
    required this.id,
    required this.roomId,
    required this.elementType,
    required this.description,
    this.triggerCondition = 'always',
    this.intensity = 1.0,
    this.reactive = false,
  });

  factory MicroLifeElement.fromJson(Map<String, dynamic> json) {
    return MicroLifeElement(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      elementType: json['elementType'] as String,
      description: json['description'] as String,
      triggerCondition:
          json['triggerCondition'] as String? ?? 'always',
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
      reactive: json['reactive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'elementType': elementType,
        'description': description,
        'triggerCondition': triggerCondition,
        'intensity': intensity,
        'reactive': reactive,
      };
}

class RoomAtmosphereConfig {
  final String roomId;
  final List<MicroLifeElement> elements;
  final String lightingPreset;
  final String landmarkReactivity;
  final List<String> scarsHistory;

  const RoomAtmosphereConfig({
    required this.roomId,
    this.elements = const [],
    this.lightingPreset = 'warm',
    this.landmarkReactivity = 'dormant',
    this.scarsHistory = const [],
  });

  factory RoomAtmosphereConfig.fromJson(Map<String, dynamic> json) {
    return RoomAtmosphereConfig(
      roomId: json['roomId'] as String,
      elements: (json['elements'] as List<dynamic>? ?? const [])
          .map((e) =>
              MicroLifeElement.fromJson(e as Map<String, dynamic>))
          .toList(),
      lightingPreset:
          json['lightingPreset'] as String? ?? 'warm',
      landmarkReactivity:
          json['landmarkReactivity'] as String? ?? 'dormant',
      scarsHistory:
          (json['scarsHistory'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'elements': elements.map((e) => e.toJson()).toList(),
        'lightingPreset': lightingPreset,
        'landmarkReactivity': landmarkReactivity,
        'scarsHistory': scarsHistory,
      };
}

// ─── 8. Weekly Featured Room ────────────────────────────────────────

class FeaturedRoomConfig {
  final String roomId;
  final String weekKey;
  final double rewardMultiplier;
  final String? specialEventId;
  final String? challengeModifierId;
  final double codexGainBonus;
  final double relicFragmentChanceBonus;
  final String? visualThemeAccent;

  const FeaturedRoomConfig({
    required this.roomId,
    required this.weekKey,
    this.rewardMultiplier = 1.0,
    this.specialEventId,
    this.challengeModifierId,
    this.codexGainBonus = 0.0,
    this.relicFragmentChanceBonus = 0.0,
    this.visualThemeAccent,
  });

  factory FeaturedRoomConfig.fromJson(Map<String, dynamic> json) {
    return FeaturedRoomConfig(
      roomId: json['roomId'] as String,
      weekKey: json['weekKey'] as String,
      rewardMultiplier:
          (json['rewardMultiplier'] as num?)?.toDouble() ?? 1.0,
      specialEventId: json['specialEventId'] as String?,
      challengeModifierId: json['challengeModifierId'] as String?,
      codexGainBonus:
          (json['codexGainBonus'] as num?)?.toDouble() ?? 0.0,
      relicFragmentChanceBonus:
          (json['relicFragmentChanceBonus'] as num?)?.toDouble() ?? 0.0,
      visualThemeAccent: json['visualThemeAccent'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'weekKey': weekKey,
        'rewardMultiplier': rewardMultiplier,
        'specialEventId': specialEventId,
        'challengeModifierId': challengeModifierId,
        'codexGainBonus': codexGainBonus,
        'relicFragmentChanceBonus': relicFragmentChanceBonus,
        'visualThemeAccent': visualThemeAccent,
      };
}

// ─── 9. Personal Best / Performance ─────────────────────────────────

class PersonalBestRecord {
  final String roomId;
  final int bestPaceSeconds;
  final int bestCombo;
  final int bestEventChain;
  final String bestCompletionStyle;
  final Map<String, int> milestoneTimings;
  final DateTime? recordDate;

  const PersonalBestRecord({
    required this.roomId,
    this.bestPaceSeconds = 0,
    this.bestCombo = 0,
    this.bestEventChain = 0,
    this.bestCompletionStyle = 'methodical',
    this.milestoneTimings = const {},
    this.recordDate,
  });

  PersonalBestRecord copyWith({
    String? roomId,
    int? bestPaceSeconds,
    int? bestCombo,
    int? bestEventChain,
    String? bestCompletionStyle,
    Map<String, int>? milestoneTimings,
    DateTime? recordDate,
  }) {
    return PersonalBestRecord(
      roomId: roomId ?? this.roomId,
      bestPaceSeconds: bestPaceSeconds ?? this.bestPaceSeconds,
      bestCombo: bestCombo ?? this.bestCombo,
      bestEventChain: bestEventChain ?? this.bestEventChain,
      bestCompletionStyle:
          bestCompletionStyle ?? this.bestCompletionStyle,
      milestoneTimings: milestoneTimings ?? this.milestoneTimings,
      recordDate: recordDate ?? this.recordDate,
    );
  }

  factory PersonalBestRecord.fromJson(Map<String, dynamic> json) {
    return PersonalBestRecord(
      roomId: json['roomId'] as String,
      bestPaceSeconds: json['bestPaceSeconds'] as int? ?? 0,
      bestCombo: json['bestCombo'] as int? ?? 0,
      bestEventChain: json['bestEventChain'] as int? ?? 0,
      bestCompletionStyle:
          json['bestCompletionStyle'] as String? ?? 'methodical',
      milestoneTimings:
          (json['milestoneTimings'] as Map<String, dynamic>? ?? const {})
              .map((k, v) => MapEntry(k, v as int)),
      recordDate: json['recordDate'] != null
          ? DateTime.parse(json['recordDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'bestPaceSeconds': bestPaceSeconds,
        'bestCombo': bestCombo,
        'bestEventChain': bestEventChain,
        'bestCompletionStyle': bestCompletionStyle,
        'milestoneTimings': milestoneTimings,
        'recordDate': recordDate?.toIso8601String(),
      };
}

// ─── 10. Layered Multi-Room Secrets ─────────────────────────────────

class MultiRoomSecretClue {
  final String id;
  final String roomId;
  final String clueText;
  final int order;
  final bool discovered;

  const MultiRoomSecretClue({
    required this.id,
    required this.roomId,
    required this.clueText,
    this.order = 0,
    this.discovered = false,
  });

  MultiRoomSecretClue copyWith({
    String? id,
    String? roomId,
    String? clueText,
    int? order,
    bool? discovered,
  }) {
    return MultiRoomSecretClue(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      clueText: clueText ?? this.clueText,
      order: order ?? this.order,
      discovered: discovered ?? this.discovered,
    );
  }

  factory MultiRoomSecretClue.fromJson(Map<String, dynamic> json) {
    return MultiRoomSecretClue(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      clueText: json['clueText'] as String,
      order: json['order'] as int? ?? 0,
      discovered: json['discovered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'clueText': clueText,
        'order': order,
        'discovered': discovered,
      };
}

class MultiRoomSecret {
  final String id;
  final String title;
  final String description;
  final List<MultiRoomSecretClue> clues;
  final String payoffDescription;
  final String payoffRoomId;
  final String rewardType;
  final String rewardId;
  final bool solved;

  const MultiRoomSecret({
    required this.id,
    required this.title,
    required this.description,
    this.clues = const [],
    required this.payoffDescription,
    required this.payoffRoomId,
    required this.rewardType,
    required this.rewardId,
    this.solved = false,
  });

  MultiRoomSecret copyWith({
    String? id,
    String? title,
    String? description,
    List<MultiRoomSecretClue>? clues,
    String? payoffDescription,
    String? payoffRoomId,
    String? rewardType,
    String? rewardId,
    bool? solved,
  }) {
    return MultiRoomSecret(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      clues: clues ?? this.clues,
      payoffDescription:
          payoffDescription ?? this.payoffDescription,
      payoffRoomId: payoffRoomId ?? this.payoffRoomId,
      rewardType: rewardType ?? this.rewardType,
      rewardId: rewardId ?? this.rewardId,
      solved: solved ?? this.solved,
    );
  }

  factory MultiRoomSecret.fromJson(Map<String, dynamic> json) {
    return MultiRoomSecret(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      clues: (json['clues'] as List<dynamic>? ?? const [])
          .map((e) =>
              MultiRoomSecretClue.fromJson(e as Map<String, dynamic>))
          .toList(),
      payoffDescription: json['payoffDescription'] as String,
      payoffRoomId: json['payoffRoomId'] as String,
      rewardType: json['rewardType'] as String,
      rewardId: json['rewardId'] as String,
      solved: json['solved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'clues': clues.map((e) => e.toJson()).toList(),
        'payoffDescription': payoffDescription,
        'payoffRoomId': payoffRoomId,
        'rewardType': rewardType,
        'rewardId': rewardId,
        'solved': solved,
      };
}

// ─── 11. Mastery Contracts ──────────────────────────────────────────

class MasteryContract {
  final String id;
  final String roomId;
  final String title;
  final String description;
  final String metric;
  final int targetValue;
  final int currentValue;
  final bool completed;
  final String rewardType;
  final String rewardId;

  const MasteryContract({
    required this.id,
    required this.roomId,
    required this.title,
    required this.description,
    required this.metric,
    required this.targetValue,
    this.currentValue = 0,
    this.completed = false,
    required this.rewardType,
    required this.rewardId,
  });

  MasteryContract copyWith({
    String? id,
    String? roomId,
    String? title,
    String? description,
    String? metric,
    int? targetValue,
    int? currentValue,
    bool? completed,
    String? rewardType,
    String? rewardId,
  }) {
    return MasteryContract(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      description: description ?? this.description,
      metric: metric ?? this.metric,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      completed: completed ?? this.completed,
      rewardType: rewardType ?? this.rewardType,
      rewardId: rewardId ?? this.rewardId,
    );
  }

  factory MasteryContract.fromJson(Map<String, dynamic> json) {
    return MasteryContract(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      metric: json['metric'] as String,
      targetValue: json['targetValue'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      rewardType: json['rewardType'] as String,
      rewardId: json['rewardId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'title': title,
        'description': description,
        'metric': metric,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'completed': completed,
        'rewardType': rewardType,
        'rewardId': rewardId,
      };
}

// ─── 12. Room Summary Reports ───────────────────────────────────────

class RoomSummaryItem {
  final String category;
  final String description;
  final String? relatedId;

  const RoomSummaryItem({
    required this.category,
    required this.description,
    this.relatedId,
  });

  factory RoomSummaryItem.fromJson(Map<String, dynamic> json) {
    return RoomSummaryItem(
      category: json['category'] as String,
      description: json['description'] as String,
      relatedId: json['relatedId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'description': description,
        'relatedId': relatedId,
      };
}

class RoomSummaryReport {
  final String roomId;
  final DateTime generatedAt;
  final List<RoomSummaryItem> items;
  final int totalNewEntries;
  final int totalNewSecrets;
  final int masteryStarsGained;

  const RoomSummaryReport({
    required this.roomId,
    required this.generatedAt,
    this.items = const [],
    this.totalNewEntries = 0,
    this.totalNewSecrets = 0,
    this.masteryStarsGained = 0,
  });

  factory RoomSummaryReport.fromJson(Map<String, dynamic> json) {
    return RoomSummaryReport(
      roomId: json['roomId'] as String,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) =>
              RoomSummaryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalNewEntries: json['totalNewEntries'] as int? ?? 0,
      totalNewSecrets: json['totalNewSecrets'] as int? ?? 0,
      masteryStarsGained: json['masteryStarsGained'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'generatedAt': generatedAt.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'totalNewEntries': totalNewEntries,
        'totalNewSecrets': totalNewSecrets,
        'masteryStarsGained': masteryStarsGained,
      };
}

// ─── 13. Non-Stat Rewards ───────────────────────────────────────────

enum CosmeticRewardType {
  transitionStyle,
  guideReaction,
  roomDecor,
  landmarkVariant,
  archiveVisual,
  ambientTheme,
  titleUnlock,
  routeSeal,
  trophyItem,
  roomBadge,
  endingVisual,
}

class CosmeticReward {
  final String id;
  final String name;
  final String description;
  final CosmeticRewardType type;
  final String? roomId;
  final bool unlocked;

  const CosmeticReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.roomId,
    this.unlocked = false,
  });

  CosmeticReward copyWith({
    String? id,
    String? name,
    String? description,
    CosmeticRewardType? type,
    String? roomId,
    bool? unlocked,
  }) {
    return CosmeticReward(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  factory CosmeticReward.fromJson(Map<String, dynamic> json) {
    return CosmeticReward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: CosmeticRewardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CosmeticRewardType.roomDecor,
      ),
      roomId: json['roomId'] as String?,
      unlocked: json['unlocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'roomId': roomId,
        'unlocked': unlocked,
      };
}

// ─── 14. Social Hooks (Scaffold) ────────────────────────────────────

class CommunityStats {
  final Map<String, double> roomCompletionPercentages;
  final Map<String, String> mostCommonRoutePerRoom;
  final Map<String, double> rareSecretFoundPercentages;
  final int globalAnomalyTotal;
  final Map<String, int> featuredRoomParticipation;

  const CommunityStats({
    this.roomCompletionPercentages = const {},
    this.mostCommonRoutePerRoom = const {},
    this.rareSecretFoundPercentages = const {},
    this.globalAnomalyTotal = 0,
    this.featuredRoomParticipation = const {},
  });

  factory CommunityStats.fromJson(Map<String, dynamic> json) {
    return CommunityStats(
      roomCompletionPercentages:
          (json['roomCompletionPercentages'] as Map<String, dynamic>? ??
                  const {})
              .map((k, v) => MapEntry(k, (v as num).toDouble())),
      mostCommonRoutePerRoom:
          (json['mostCommonRoutePerRoom'] as Map<String, dynamic>? ??
                  const {})
              .map((k, v) => MapEntry(k, v as String)),
      rareSecretFoundPercentages:
          (json['rareSecretFoundPercentages'] as Map<String, dynamic>? ??
                  const {})
              .map((k, v) => MapEntry(k, (v as num).toDouble())),
      globalAnomalyTotal: json['globalAnomalyTotal'] as int? ?? 0,
      featuredRoomParticipation:
          (json['featuredRoomParticipation'] as Map<String, dynamic>? ??
                  const {})
              .map((k, v) => MapEntry(k, v as int)),
    );
  }

  Map<String, dynamic> toJson() => {
        'roomCompletionPercentages': roomCompletionPercentages,
        'mostCommonRoutePerRoom': mostCommonRoutePerRoom,
        'rareSecretFoundPercentages': rareSecretFoundPercentages,
        'globalAnomalyTotal': globalAnomalyTotal,
        'featuredRoomParticipation': featuredRoomParticipation,
      };
}

// ─── 15. Aggregate Post-Core State ──────────────────────────────────

class PostCoreState {
  final Map<String, RoomMasteryProfile> roomMastery;
  final GuideState guideState;
  final List<RelicSetProgress> relicSetProgress;
  final List<DelayedConsequence> pendingConsequences;
  final List<DelayedConsequence> resolvedConsequences;
  final Map<String, List<RevisitUnlock>> revisitUnlocks;
  final List<ArchiveCompletionReward> archiveRewards;
  final FeaturedRoomConfig? currentFeaturedRoom;
  final Map<String, PersonalBestRecord> personalBests;
  final List<MultiRoomSecret> multiRoomSecrets;
  final List<MasteryContract> activeContracts;
  final List<MasteryContract> completedContracts;
  final List<CosmeticReward> cosmeticRewards;
  final CommunityStats? communityStats;

  const PostCoreState({
    this.roomMastery = const {},
    this.guideState = const GuideState(),
    this.relicSetProgress = const [],
    this.pendingConsequences = const [],
    this.resolvedConsequences = const [],
    this.revisitUnlocks = const {},
    this.archiveRewards = const [],
    this.currentFeaturedRoom,
    this.personalBests = const {},
    this.multiRoomSecrets = const [],
    this.activeContracts = const [],
    this.completedContracts = const [],
    this.cosmeticRewards = const [],
    this.communityStats,
  });

  PostCoreState copyWith({
    Map<String, RoomMasteryProfile>? roomMastery,
    GuideState? guideState,
    List<RelicSetProgress>? relicSetProgress,
    List<DelayedConsequence>? pendingConsequences,
    List<DelayedConsequence>? resolvedConsequences,
    Map<String, List<RevisitUnlock>>? revisitUnlocks,
    List<ArchiveCompletionReward>? archiveRewards,
    FeaturedRoomConfig? currentFeaturedRoom,
    Map<String, PersonalBestRecord>? personalBests,
    List<MultiRoomSecret>? multiRoomSecrets,
    List<MasteryContract>? activeContracts,
    List<MasteryContract>? completedContracts,
    List<CosmeticReward>? cosmeticRewards,
    CommunityStats? communityStats,
  }) {
    return PostCoreState(
      roomMastery: roomMastery ?? this.roomMastery,
      guideState: guideState ?? this.guideState,
      relicSetProgress: relicSetProgress ?? this.relicSetProgress,
      pendingConsequences:
          pendingConsequences ?? this.pendingConsequences,
      resolvedConsequences:
          resolvedConsequences ?? this.resolvedConsequences,
      revisitUnlocks: revisitUnlocks ?? this.revisitUnlocks,
      archiveRewards: archiveRewards ?? this.archiveRewards,
      currentFeaturedRoom:
          currentFeaturedRoom ?? this.currentFeaturedRoom,
      personalBests: personalBests ?? this.personalBests,
      multiRoomSecrets: multiRoomSecrets ?? this.multiRoomSecrets,
      activeContracts: activeContracts ?? this.activeContracts,
      completedContracts:
          completedContracts ?? this.completedContracts,
      cosmeticRewards: cosmeticRewards ?? this.cosmeticRewards,
      communityStats: communityStats ?? this.communityStats,
    );
  }

  factory PostCoreState.fromJson(Map<String, dynamic> json) {
    return PostCoreState(
      roomMastery:
          (json['roomMastery'] as Map<String, dynamic>? ?? const {}).map(
              (k, v) => MapEntry(
                  k,
                  RoomMasteryProfile.fromJson(
                      v as Map<String, dynamic>))),
      guideState: json['guideState'] != null
          ? GuideState.fromJson(
              json['guideState'] as Map<String, dynamic>)
          : const GuideState(),
      relicSetProgress:
          (json['relicSetProgress'] as List<dynamic>? ?? const [])
              .map((e) =>
                  RelicSetProgress.fromJson(e as Map<String, dynamic>))
              .toList(),
      pendingConsequences:
          (json['pendingConsequences'] as List<dynamic>? ?? const [])
              .map((e) => DelayedConsequence.fromJson(
                  e as Map<String, dynamic>))
              .toList(),
      resolvedConsequences:
          (json['resolvedConsequences'] as List<dynamic>? ?? const [])
              .map((e) => DelayedConsequence.fromJson(
                  e as Map<String, dynamic>))
              .toList(),
      revisitUnlocks:
          (json['revisitUnlocks'] as Map<String, dynamic>? ?? const {})
              .map((k, v) => MapEntry(
                  k,
                  (v as List<dynamic>)
                      .map((e) => RevisitUnlock.fromJson(
                          e as Map<String, dynamic>))
                      .toList())),
      archiveRewards:
          (json['archiveRewards'] as List<dynamic>? ?? const [])
              .map((e) => ArchiveCompletionReward.fromJson(
                  e as Map<String, dynamic>))
              .toList(),
      currentFeaturedRoom: json['currentFeaturedRoom'] != null
          ? FeaturedRoomConfig.fromJson(
              json['currentFeaturedRoom'] as Map<String, dynamic>)
          : null,
      personalBests:
          (json['personalBests'] as Map<String, dynamic>? ?? const {})
              .map((k, v) => MapEntry(
                  k,
                  PersonalBestRecord.fromJson(
                      v as Map<String, dynamic>))),
      multiRoomSecrets:
          (json['multiRoomSecrets'] as List<dynamic>? ?? const [])
              .map((e) =>
                  MultiRoomSecret.fromJson(e as Map<String, dynamic>))
              .toList(),
      activeContracts:
          (json['activeContracts'] as List<dynamic>? ?? const [])
              .map((e) =>
                  MasteryContract.fromJson(e as Map<String, dynamic>))
              .toList(),
      completedContracts:
          (json['completedContracts'] as List<dynamic>? ?? const [])
              .map((e) =>
                  MasteryContract.fromJson(e as Map<String, dynamic>))
              .toList(),
      cosmeticRewards:
          (json['cosmeticRewards'] as List<dynamic>? ?? const [])
              .map((e) =>
                  CosmeticReward.fromJson(e as Map<String, dynamic>))
              .toList(),
      communityStats: json['communityStats'] != null
          ? CommunityStats.fromJson(
              json['communityStats'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomMastery':
            roomMastery.map((k, v) => MapEntry(k, v.toJson())),
        'guideState': guideState.toJson(),
        'relicSetProgress':
            relicSetProgress.map((e) => e.toJson()).toList(),
        'pendingConsequences':
            pendingConsequences.map((e) => e.toJson()).toList(),
        'resolvedConsequences':
            resolvedConsequences.map((e) => e.toJson()).toList(),
        'revisitUnlocks': revisitUnlocks.map((k, v) =>
            MapEntry(k, v.map((e) => e.toJson()).toList())),
        'archiveRewards':
            archiveRewards.map((e) => e.toJson()).toList(),
        'currentFeaturedRoom': currentFeaturedRoom?.toJson(),
        'personalBests':
            personalBests.map((k, v) => MapEntry(k, v.toJson())),
        'multiRoomSecrets':
            multiRoomSecrets.map((e) => e.toJson()).toList(),
        'activeContracts':
            activeContracts.map((e) => e.toJson()).toList(),
        'completedContracts':
            completedContracts.map((e) => e.toJson()).toList(),
        'cosmeticRewards':
            cosmeticRewards.map((e) => e.toJson()).toList(),
        'communityStats': communityStats?.toJson(),
      };
}
