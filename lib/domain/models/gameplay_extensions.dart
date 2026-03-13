import 'package:flutter/foundation.dart';

enum ActiveAbilityType { overclock, focus, surge, sync }

enum EventRarity { common, rare, epic, corrupted, legendary }

enum ChallengePeriod { daily, weekly }

enum ChallengeMetric {
  totalTaps,
  eventClicks,
  bestEventChain,
  upgradesBought,
  combo,
  riskyChoices,
  productionBurst,
}

enum ColorblindMode { off, deuteranopia, protanopia, tritanopia }

enum MutatorType { eventStorm, overheating, noAutomation, unstableEconomy }

class ActiveAbilityState {
  final ActiveAbilityType type;
  final bool unlocked;
  final double cooldownRemaining;
  final double activeRemaining;

  const ActiveAbilityState({
    required this.type,
    this.unlocked = false,
    this.cooldownRemaining = 0,
    this.activeRemaining = 0,
  });

  bool get isReady => unlocked && cooldownRemaining <= 0;
  bool get isActive => activeRemaining > 0;

  ActiveAbilityState copyWith({
    ActiveAbilityType? type,
    bool? unlocked,
    double? cooldownRemaining,
    double? activeRemaining,
  }) {
    return ActiveAbilityState(
      type: type ?? this.type,
      unlocked: unlocked ?? this.unlocked,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      activeRemaining: activeRemaining ?? this.activeRemaining,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'unlocked': unlocked,
        'cooldownRemaining': cooldownRemaining,
        'activeRemaining': activeRemaining,
      };

  factory ActiveAbilityState.fromJson(Map<String, dynamic> json) {
    return ActiveAbilityState(
      type: ActiveAbilityType.values.firstWhere(
        (value) => value.name == json['type'],
      ),
      unlocked: json['unlocked'] as bool? ?? false,
      cooldownRemaining: (json['cooldownRemaining'] as num?)?.toDouble() ?? 0,
      activeRemaining: (json['activeRemaining'] as num?)?.toDouble() ?? 0,
    );
  }
}

enum GameEventType {
  powerSurge,
  aiIdea,
  hardwareMalfunction,
  marketSpike,
  mysteryCache,
}

class GameEventState {
  final String id;
  final GameEventType type;
  final String title;
  final String description;
  final double remainingSeconds;
  final bool risky;
  final EventRarity rarity;
  final bool clickOnly;

  const GameEventState({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.remainingSeconds,
    this.risky = false,
    this.rarity = EventRarity.common,
    this.clickOnly = false,
  });

  GameEventState copyWith({
    String? id,
    GameEventType? type,
    String? title,
    String? description,
    double? remainingSeconds,
    bool? risky,
    EventRarity? rarity,
    bool? clickOnly,
  }) {
    return GameEventState(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      risky: risky ?? this.risky,
      rarity: rarity ?? this.rarity,
      clickOnly: clickOnly ?? this.clickOnly,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'remainingSeconds': remainingSeconds,
        'risky': risky,
        'rarity': rarity.name,
        'clickOnly': clickOnly,
      };

  factory GameEventState.fromJson(Map<String, dynamic> json) {
    return GameEventState(
      id: json['id'] as String,
      type: GameEventType.values.firstWhere(
        (value) => value.name == json['type'],
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      remainingSeconds: (json['remainingSeconds'] as num?)?.toDouble() ?? 0,
      risky: json['risky'] as bool? ?? false,
      rarity: json['rarity'] != null
          ? EventRarity.values.firstWhere((value) => value.name == json['rarity'])
          : EventRarity.common,
      clickOnly: json['clickOnly'] as bool? ?? false,
    );
  }
}

class QuestState {
  final String id;
  final String title;
  final String description;
  final double target;
  final double progress;
  final bool completed;
  final bool claimed;

  const QuestState({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    this.progress = 0,
    this.completed = false,
    this.claimed = false,
  });

  QuestState copyWith({
    String? id,
    String? title,
    String? description,
    double? target,
    double? progress,
    bool? completed,
    bool? claimed,
  }) {
    return QuestState(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      claimed: claimed ?? this.claimed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'target': target,
        'progress': progress,
        'completed': completed,
        'claimed': claimed,
      };

  factory QuestState.fromJson(Map<String, dynamic> json) {
    return QuestState(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      target: (json['target'] as num).toDouble(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      completed: json['completed'] as bool? ?? false,
      claimed: json['claimed'] as bool? ?? false,
    );
  }
}

class ChallengeState {
  final String id;
  final ChallengePeriod period;
  final ChallengeMetric metric;
  final String title;
  final String description;
  final double target;
  final double startValue;
  final double progress;
  final bool completed;
  final bool claimed;
  final int rerollsUsed;
  final String seasonKey;

  const ChallengeState({
    required this.id,
    required this.period,
    required this.metric,
    required this.title,
    required this.description,
    required this.target,
    this.startValue = 0,
    this.progress = 0,
    this.completed = false,
    this.claimed = false,
    this.rerollsUsed = 0,
    this.seasonKey = 'default',
  });

  ChallengeState copyWith({
    String? id,
    ChallengePeriod? period,
    ChallengeMetric? metric,
    String? title,
    String? description,
    double? target,
    double? startValue,
    double? progress,
    bool? completed,
    bool? claimed,
    int? rerollsUsed,
    String? seasonKey,
  }) {
    return ChallengeState(
      id: id ?? this.id,
      period: period ?? this.period,
      metric: metric ?? this.metric,
      title: title ?? this.title,
      description: description ?? this.description,
      target: target ?? this.target,
      startValue: startValue ?? this.startValue,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      claimed: claimed ?? this.claimed,
      rerollsUsed: rerollsUsed ?? this.rerollsUsed,
      seasonKey: seasonKey ?? this.seasonKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'period': period.name,
        'metric': metric.name,
        'title': title,
        'description': description,
        'target': target,
        'startValue': startValue,
        'progress': progress,
        'completed': completed,
        'claimed': claimed,
        'rerollsUsed': rerollsUsed,
        'seasonKey': seasonKey,
      };

  factory ChallengeState.fromJson(Map<String, dynamic> json) {
    return ChallengeState(
      id: json['id'] as String,
      period: ChallengePeriod.values
          .firstWhere((value) => value.name == json['period']),
      metric: ChallengeMetric.values
          .firstWhere((value) => value.name == json['metric']),
      title: json['title'] as String,
      description: json['description'] as String,
      target: (json['target'] as num).toDouble(),
      startValue: (json['startValue'] as num?)?.toDouble() ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      completed: json['completed'] as bool? ?? false,
      claimed: json['claimed'] as bool? ?? false,
      rerollsUsed: json['rerollsUsed'] as int? ?? 0,
      seasonKey: json['seasonKey'] as String? ?? 'default',
    );
  }
}

class NarrativeBeat {
  final String id;
  final String title;
  final String body;
  final bool viewed;

  const NarrativeBeat({
    required this.id,
    required this.title,
    required this.body,
    this.viewed = false,
  });

  NarrativeBeat copyWith({
    String? id,
    String? title,
    String? body,
    bool? viewed,
  }) {
    return NarrativeBeat(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      viewed: viewed ?? this.viewed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'viewed': viewed,
      };

  factory NarrativeBeat.fromJson(Map<String, dynamic> json) {
    return NarrativeBeat(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      viewed: json['viewed'] as bool? ?? false,
    );
  }
}

class LoadoutPreset {
  final String id;
  final String name;
  final Set<String> preferredBranches;
  final bool favorite;

  const LoadoutPreset({
    required this.id,
    required this.name,
    this.preferredBranches = const {},
    this.favorite = false,
  });

  LoadoutPreset copyWith({
    String? id,
    String? name,
    Set<String>? preferredBranches,
    bool? favorite,
  }) {
    return LoadoutPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      preferredBranches: preferredBranches ?? this.preferredBranches,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'preferredBranches': preferredBranches.toList(),
        'favorite': favorite,
      };

  factory LoadoutPreset.fromJson(Map<String, dynamic> json) {
    return LoadoutPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      preferredBranches: (json['preferredBranches'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toSet(),
      favorite: json['favorite'] as bool? ?? false,
    );
  }
}

class GameplayMutatorState {
  final MutatorType type;
  final String title;
  final String description;
  final double remainingSeconds;

  const GameplayMutatorState({
    required this.type,
    required this.title,
    required this.description,
    required this.remainingSeconds,
  });

  GameplayMutatorState copyWith({
    MutatorType? type,
    String? title,
    String? description,
    double? remainingSeconds,
  }) {
    return GameplayMutatorState(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'description': description,
        'remainingSeconds': remainingSeconds,
      };

  factory GameplayMutatorState.fromJson(Map<String, dynamic> json) {
    return GameplayMutatorState(
      type: MutatorType.values.firstWhere((value) => value.name == json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      remainingSeconds: (json['remainingSeconds'] as num?)?.toDouble() ?? 0,
    );
  }
}

@immutable
class ReturnSummary {
  final Duration timeAway;
  final String observation;
  final String incentive;

  const ReturnSummary({
    required this.timeAway,
    required this.observation,
    required this.incentive,
  });
}
