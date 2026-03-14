// Domain models for the side activity / minigame system.
//
// Side activities are optional per-room challenges that reward the player
// with currency, companion drops, codex entries, upgrade unlocks, and
// relic fragments. They are gated by tickets, may be repeatable on daily
// or weekly cadences, and track individual best scores.

// ─── Enums ──────────────────────────────────────────────────────────

/// The distinct minigame / side-activity archetypes available in rooms.
enum SideActivityType {
  calibrationConsole,
  signalScan,
  salvageExcavation,
  terminalHack,
  anomalyInterception,
  routingPuzzle,
  maintenanceChallenge,
  benchmarkChallenge,
  stealthBypass,
  orbitalTiming,
  contradictionPuzzle,
  roomRestore,
  fabricationSequencing,
  memoryDefrag,
  cableRouting,
  coolingAlignment,
}

// ─── Value Classes ──────────────────────────────────────────────────

/// A single reward granted on completion of a side activity.
class SideActivityReward {
  final String type;
  final double value;
  final String description;
  final String rarity;

  const SideActivityReward({
    required this.type,
    required this.value,
    required this.description,
    this.rarity = 'common',
  });

  SideActivityReward copyWith({
    String? type,
    double? value,
    String? description,
    String? rarity,
  }) {
    return SideActivityReward(
      type: type ?? this.type,
      value: value ?? this.value,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
        'description': description,
        'rarity': rarity,
      };

  factory SideActivityReward.fromJson(Map<String, dynamic> json) {
    return SideActivityReward(
      type: json['type'] as String,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String,
      rarity: json['rarity'] as String? ?? 'common',
    );
  }
}

// ─── Definition Classes ─────────────────────────────────────────────

/// Static definition of a side activity available within a room.
class SideActivityDefinition {
  final String id;
  final String roomId;
  final String name;
  final String description;
  final SideActivityType type;
  final int difficultyTier;
  final double durationSeconds;
  final List<SideActivityReward> rewards;
  final bool repeatableDaily;
  final bool repeatableWeekly;
  final String? secretUnlockId;
  final String? upgradeUnlockId;
  final String? companionDropId;

  const SideActivityDefinition({
    required this.id,
    required this.roomId,
    required this.name,
    required this.description,
    required this.type,
    this.difficultyTier = 1,
    this.durationSeconds = 30.0,
    this.rewards = const [],
    this.repeatableDaily = false,
    this.repeatableWeekly = false,
    this.secretUnlockId,
    this.upgradeUnlockId,
    this.companionDropId,
  });

  SideActivityDefinition copyWith({
    String? id,
    String? roomId,
    String? name,
    String? description,
    SideActivityType? type,
    int? difficultyTier,
    double? durationSeconds,
    List<SideActivityReward>? rewards,
    bool? repeatableDaily,
    bool? repeatableWeekly,
    String? secretUnlockId,
    String? upgradeUnlockId,
    String? companionDropId,
  }) {
    return SideActivityDefinition(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      difficultyTier: difficultyTier ?? this.difficultyTier,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      rewards: rewards ?? this.rewards,
      repeatableDaily: repeatableDaily ?? this.repeatableDaily,
      repeatableWeekly: repeatableWeekly ?? this.repeatableWeekly,
      secretUnlockId: secretUnlockId ?? this.secretUnlockId,
      upgradeUnlockId: upgradeUnlockId ?? this.upgradeUnlockId,
      companionDropId: companionDropId ?? this.companionDropId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'name': name,
        'description': description,
        'type': type.name,
        'difficultyTier': difficultyTier,
        'durationSeconds': durationSeconds,
        'rewards': rewards.map((e) => e.toJson()).toList(),
        'repeatableDaily': repeatableDaily,
        'repeatableWeekly': repeatableWeekly,
        'secretUnlockId': secretUnlockId,
        'upgradeUnlockId': upgradeUnlockId,
        'companionDropId': companionDropId,
      };

  factory SideActivityDefinition.fromJson(Map<String, dynamic> json) {
    return SideActivityDefinition(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: SideActivityType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => SideActivityType.calibrationConsole,
      ),
      difficultyTier: json['difficultyTier'] as int? ?? 1,
      durationSeconds:
          (json['durationSeconds'] as num?)?.toDouble() ?? 30.0,
      rewards: (json['rewards'] as List<dynamic>? ?? const [])
          .map((e) =>
              SideActivityReward.fromJson(e as Map<String, dynamic>))
          .toList(),
      repeatableDaily: json['repeatableDaily'] as bool? ?? false,
      repeatableWeekly: json['repeatableWeekly'] as bool? ?? false,
      secretUnlockId: json['secretUnlockId'] as String?,
      upgradeUnlockId: json['upgradeUnlockId'] as String?,
      companionDropId: json['companionDropId'] as String?,
    );
  }
}

// ─── Runtime State ──────────────────────────────────────────────────

/// Tracks the player's progress on a single side activity.
class SideActivityProgress {
  final String activityId;
  final int completionCount;
  final double bestScore;
  final DateTime? lastCompletedAt;
  final int dailyCompletions;
  final int weeklyCompletions;
  final bool unlocked;

  const SideActivityProgress({
    required this.activityId,
    this.completionCount = 0,
    this.bestScore = 0.0,
    this.lastCompletedAt,
    this.dailyCompletions = 0,
    this.weeklyCompletions = 0,
    this.unlocked = false,
  });

  SideActivityProgress copyWith({
    String? activityId,
    int? completionCount,
    double? bestScore,
    DateTime? lastCompletedAt,
    int? dailyCompletions,
    int? weeklyCompletions,
    bool? unlocked,
  }) {
    return SideActivityProgress(
      activityId: activityId ?? this.activityId,
      completionCount: completionCount ?? this.completionCount,
      bestScore: bestScore ?? this.bestScore,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      dailyCompletions: dailyCompletions ?? this.dailyCompletions,
      weeklyCompletions: weeklyCompletions ?? this.weeklyCompletions,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  Map<String, dynamic> toJson() => {
        'activityId': activityId,
        'completionCount': completionCount,
        'bestScore': bestScore,
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
        'dailyCompletions': dailyCompletions,
        'weeklyCompletions': weeklyCompletions,
        'unlocked': unlocked,
      };

  factory SideActivityProgress.fromJson(Map<String, dynamic> json) {
    return SideActivityProgress(
      activityId: json['activityId'] as String,
      completionCount: json['completionCount'] as int? ?? 0,
      bestScore: (json['bestScore'] as num?)?.toDouble() ?? 0.0,
      lastCompletedAt: json['lastCompletedAt'] != null
          ? DateTime.parse(json['lastCompletedAt'] as String)
          : null,
      dailyCompletions: json['dailyCompletions'] as int? ?? 0,
      weeklyCompletions: json['weeklyCompletions'] as int? ?? 0,
      unlocked: json['unlocked'] as bool? ?? false,
    );
  }
}

// ─── Aggregate State ────────────────────────────────────────────────

/// Aggregate state for the entire side-activity system.
class SideActivityState {
  final Map<String, SideActivityProgress> progresses;
  final int totalActivitiesCompleted;
  final int ticketsAvailable;

  const SideActivityState({
    this.progresses = const {},
    this.totalActivitiesCompleted = 0,
    this.ticketsAvailable = 0,
  });

  SideActivityState copyWith({
    Map<String, SideActivityProgress>? progresses,
    int? totalActivitiesCompleted,
    int? ticketsAvailable,
  }) {
    return SideActivityState(
      progresses: progresses ?? this.progresses,
      totalActivitiesCompleted:
          totalActivitiesCompleted ?? this.totalActivitiesCompleted,
      ticketsAvailable: ticketsAvailable ?? this.ticketsAvailable,
    );
  }

  Map<String, dynamic> toJson() => {
        'progresses': progresses
            .map((key, value) => MapEntry(key, value.toJson())),
        'totalActivitiesCompleted': totalActivitiesCompleted,
        'ticketsAvailable': ticketsAvailable,
      };

  factory SideActivityState.fromJson(Map<String, dynamic> json) {
    return SideActivityState(
      progresses:
          (json['progresses'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(
          key,
          SideActivityProgress.fromJson(value as Map<String, dynamic>),
        ),
      ),
      totalActivitiesCompleted:
          json['totalActivitiesCompleted'] as int? ?? 0,
      ticketsAvailable: json['ticketsAvailable'] as int? ?? 0,
    );
  }
}
