import 'gameplay_extensions.dart';

enum ProgressMetric {
  totalCoins,
  totalGenerators,
  strongestCombo,
  eventClicks,
  totalTaps,
  riskyChoices,
}

class BranchDefinition {
  final String id;
  final String title;
  final String description;

  const BranchDefinition({
    required this.id,
    required this.title,
    required this.description,
  });

  factory BranchDefinition.fromJson(Map<String, dynamic> json) {
    return BranchDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }
}

class MilestoneDefinition {
  final String id;
  final String title;
  final ProgressMetric metric;
  final double target;
  final String narrative;
  final String? unlockAbilityId;

  const MilestoneDefinition({
    required this.id,
    required this.title,
    required this.metric,
    required this.target,
    required this.narrative,
    this.unlockAbilityId,
  });

  factory MilestoneDefinition.fromJson(Map<String, dynamic> json) {
    return MilestoneDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      metric: ProgressMetric.values.firstWhere(
        (value) => value.name == json['metric'],
      ),
      target: (json['target'] as num).toDouble(),
      narrative: json['narrative'] as String,
      unlockAbilityId: json['unlockAbilityId'] as String?,
    );
  }
}

class EventTemplateDefinition {
  final String id;
  final GameEventType type;
  final String title;
  final String description;
  final bool risky;
  final bool clickOnly;
  final double baseDurationSeconds;
  final EventRarity minimumRarity;
  final String? requiredMilestoneId;
  final String? requiredBranchId;

  const EventTemplateDefinition({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.risky = false,
    this.clickOnly = false,
    this.baseDurationSeconds = 10,
    this.minimumRarity = EventRarity.common,
    this.requiredMilestoneId,
    this.requiredBranchId,
  });

  factory EventTemplateDefinition.fromJson(Map<String, dynamic> json) {
    return EventTemplateDefinition(
      id: json['id'] as String,
      type: GameEventType.values.firstWhere(
        (value) => value.name == json['type'],
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      risky: json['risky'] as bool? ?? false,
      clickOnly: json['clickOnly'] as bool? ?? false,
      baseDurationSeconds:
          (json['baseDurationSeconds'] as num?)?.toDouble() ?? 10,
      minimumRarity: json['minimumRarity'] != null
          ? EventRarity.values.firstWhere(
              (value) => value.name == json['minimumRarity'],
            )
          : EventRarity.common,
      requiredMilestoneId: json['requiredMilestoneId'] as String?,
      requiredBranchId: json['requiredBranchId'] as String?,
    );
  }
}

class ChallengeTemplateDefinition {
  final String id;
  final ChallengePeriod period;
  final ChallengeMetric metric;
  final String title;
  final String description;
  final double target;
  final double rewardMultiplier;
  final int weight;
  final String? requiredMilestoneId;

  const ChallengeTemplateDefinition({
    required this.id,
    required this.period,
    required this.metric,
    required this.title,
    required this.description,
    required this.target,
    this.rewardMultiplier = 1,
    this.weight = 1,
    this.requiredMilestoneId,
  });

  factory ChallengeTemplateDefinition.fromJson(Map<String, dynamic> json) {
    return ChallengeTemplateDefinition(
      id: json['id'] as String,
      period: ChallengePeriod.values.firstWhere(
        (value) => value.name == json['period'],
      ),
      metric: ChallengeMetric.values.firstWhere(
        (value) => value.name == json['metric'],
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      target: (json['target'] as num).toDouble(),
      rewardMultiplier:
          (json['rewardMultiplier'] as num?)?.toDouble() ?? 1,
      weight: json['weight'] as int? ?? 1,
      requiredMilestoneId: json['requiredMilestoneId'] as String?,
    );
  }
}

class NarrativeBeatDefinition {
  final String id;
  final String title;
  final String body;
  final String triggerKey;

  const NarrativeBeatDefinition({
    required this.id,
    required this.title,
    required this.body,
    required this.triggerKey,
  });

  factory NarrativeBeatDefinition.fromJson(Map<String, dynamic> json) {
    return NarrativeBeatDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      triggerKey: json['triggerKey'] as String,
    );
  }
}

class QuestDefinition {
  final String id;
  final String title;
  final String description;
  final ProgressMetric metric;
  final double target;
  final double? targetMultiplier;
  final double minimumTarget;
  final String? requiredMilestoneId;
  final String? requiredBranchId;

  const QuestDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    this.target = 0,
    this.targetMultiplier,
    this.minimumTarget = 0,
    this.requiredMilestoneId,
    this.requiredBranchId,
  });

  factory QuestDefinition.fromJson(Map<String, dynamic> json) {
    return QuestDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      metric: ProgressMetric.values.firstWhere(
        (value) => value.name == json['metric'],
      ),
      target: (json['target'] as num?)?.toDouble() ?? 0,
      targetMultiplier: (json['targetMultiplier'] as num?)?.toDouble(),
      minimumTarget: (json['minimumTarget'] as num?)?.toDouble() ?? 0,
      requiredMilestoneId: json['requiredMilestoneId'] as String?,
      requiredBranchId: json['requiredBranchId'] as String?,
    );
  }
}

class SecretDefinition {
  final String id;
  final String title;
  final String description;
  final ProgressMetric metric;
  final double target;
  final String eraId;
  final String parentId;
  final double offsetX;
  final double offsetY;
  final String icon;
  final String effectLabel;
  final String? requiredBranchId;
  final String? requiredMilestoneId;

  const SecretDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.target,
    required this.eraId,
    required this.parentId,
    required this.offsetX,
    required this.offsetY,
    required this.icon,
    required this.effectLabel,
    this.requiredBranchId,
    this.requiredMilestoneId,
  });

  factory SecretDefinition.fromJson(Map<String, dynamic> json) {
    return SecretDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      metric: ProgressMetric.values.firstWhere(
        (value) => value.name == json['metric'],
      ),
      target: (json['target'] as num).toDouble(),
      eraId: json['eraId'] as String,
      parentId: json['parentId'] as String,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0,
      icon: json['icon'] as String? ?? '?',
      effectLabel: json['effectLabel'] as String? ?? 'Hidden branch',
      requiredBranchId: json['requiredBranchId'] as String?,
      requiredMilestoneId: json['requiredMilestoneId'] as String?,
    );
  }
}

class ProgressionContent {
  final List<BranchDefinition> branches;
  final List<MilestoneDefinition> milestones;
  final List<EventTemplateDefinition> events;
  final List<ChallengeTemplateDefinition> challenges;
  final List<NarrativeBeatDefinition> narrativeBeats;
  final List<QuestDefinition> quests;
  final List<SecretDefinition> secrets;

  const ProgressionContent({
    this.branches = const [],
    this.milestones = const [],
    this.events = const [],
    this.challenges = const [],
    this.narrativeBeats = const [],
    this.quests = const [],
    this.secrets = const [],
  });

  factory ProgressionContent.fromJson(Map<String, dynamic> json) {
    return ProgressionContent(
      branches: (json['branches'] as List<dynamic>? ?? const [])
          .map((item) => BranchDefinition.fromJson(item as Map<String, dynamic>))
          .toList(),
      milestones: (json['milestones'] as List<dynamic>? ?? const [])
          .map((item) => MilestoneDefinition.fromJson(item as Map<String, dynamic>))
          .toList(),
      events: (json['events'] as List<dynamic>? ?? const [])
          .map((item) => EventTemplateDefinition.fromJson(item as Map<String, dynamic>))
          .toList(),
      challenges: (json['challenges'] as List<dynamic>? ?? const [])
          .map((item) =>
              ChallengeTemplateDefinition.fromJson(item as Map<String, dynamic>))
          .toList(),
      narrativeBeats: (json['narrativeBeats'] as List<dynamic>? ?? const [])
          .map((item) =>
              NarrativeBeatDefinition.fromJson(item as Map<String, dynamic>))
          .toList(),
      quests: (json['quests'] as List<dynamic>? ?? const [])
          .map((item) => QuestDefinition.fromJson(item as Map<String, dynamic>))
          .toList(),
      secrets: (json['secrets'] as List<dynamic>? ?? const [])
          .map((item) => SecretDefinition.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
