// UI/UX redesign domain models.
//
// These models power the 4-layer UI hierarchy, room transitions,
// onboarding, state clarity, micro-life animations, notifications,
// and room-specific UX authoring.

// ─── 1. UI Layer System ─────────────────────────────────────────────

/// Priority for temporary notification toasts.
enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

/// Notification category for styling and filtering.
enum NotificationCategory {
  event,
  warning,
  achievement,
  archive,
  mastery,
  guide,
  roomLaw,
  completion,
  secret,
  system,
}

/// A temporary notification toast (layer 4 of the 4-layer UI).
class ToastNotification {
  final String id;
  final String title;
  final String? subtitle;
  final NotificationPriority priority;
  final NotificationCategory category;
  final String? iconName;
  final int durationMs;
  final DateTime createdAt;
  final bool dismissed;

  const ToastNotification({
    required this.id,
    required this.title,
    this.subtitle,
    this.priority = NotificationPriority.medium,
    this.category = NotificationCategory.system,
    this.iconName,
    this.durationMs = 3000,
    required this.createdAt,
    this.dismissed = false,
  });

  ToastNotification copyWith({
    String? id,
    String? title,
    String? subtitle,
    NotificationPriority? priority,
    NotificationCategory? category,
    String? iconName,
    int? durationMs,
    DateTime? createdAt,
    bool? dismissed,
  }) {
    return ToastNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  factory ToastNotification.fromJson(Map<String, dynamic> json) {
    return ToastNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      category: NotificationCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => NotificationCategory.system,
      ),
      iconName: json['iconName'] as String?,
      durationMs: json['durationMs'] as int? ?? 3000,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      dismissed: json['dismissed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'priority': priority.name,
        'category': category.name,
        'iconName': iconName,
        'durationMs': durationMs,
        'createdAt': createdAt.toIso8601String(),
        'dismissed': dismissed,
      };
}

// ─── 2. Room Transition Framework ───────────────────────────────────

/// Visual transition effect type for entering/exiting rooms.
enum TransitionEffect {
  signalDistortion,
  geometryFold,
  dataTunnel,
  cableGrowth,
  lensZoom,
  environmentDissolve,
  orbitRotation,
  staticBloom,
  timeFracture,
  memoryEcho,
  routeColorWash,
  simpleFade,
}

/// Room transition configuration.
class RoomTransitionConfig {
  final String roomId;
  final TransitionEffect enterEffect;
  final TransitionEffect exitEffect;
  final int enterDurationMs;
  final int exitDurationMs;
  final String titleRevealStyle;
  final String subtitleStyle;
  final String? guideLineOnEnter;
  final bool skippableAfterFirst;

  const RoomTransitionConfig({
    required this.roomId,
    this.enterEffect = TransitionEffect.simpleFade,
    this.exitEffect = TransitionEffect.simpleFade,
    this.enterDurationMs = 800,
    this.exitDurationMs = 600,
    this.titleRevealStyle = 'slide_up',
    this.subtitleStyle = 'fade_in',
    this.guideLineOnEnter,
    this.skippableAfterFirst = true,
  });

  factory RoomTransitionConfig.fromJson(Map<String, dynamic> json) {
    return RoomTransitionConfig(
      roomId: json['roomId'] as String,
      enterEffect: TransitionEffect.values.firstWhere(
        (e) => e.name == json['enterEffect'],
        orElse: () => TransitionEffect.simpleFade,
      ),
      exitEffect: TransitionEffect.values.firstWhere(
        (e) => e.name == json['exitEffect'],
        orElse: () => TransitionEffect.simpleFade,
      ),
      enterDurationMs: json['enterDurationMs'] as int? ?? 800,
      exitDurationMs: json['exitDurationMs'] as int? ?? 600,
      titleRevealStyle: json['titleRevealStyle'] as String? ?? 'slide_up',
      subtitleStyle: json['subtitleStyle'] as String? ?? 'fade_in',
      guideLineOnEnter: json['guideLineOnEnter'] as String?,
      skippableAfterFirst: json['skippableAfterFirst'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'enterEffect': enterEffect.name,
        'exitEffect': exitEffect.name,
        'enterDurationMs': enterDurationMs,
        'exitDurationMs': exitDurationMs,
        'titleRevealStyle': titleRevealStyle,
        'subtitleStyle': subtitleStyle,
        'guideLineOnEnter': guideLineOnEnter,
        'skippableAfterFirst': skippableAfterFirst,
      };
}

// ─── 3. Node State Clarity ──────────────────────────────────────────

/// Upgrade node visual state for clarity.
enum NodeStateLabel {
  purchasable,
  blockedByDependency,
  blockedByRoomLaw,
  blockedByRoute,
  blockedByResource,
  owned,
  maxLevel,
  guideRecommended,
  secretRelated,
  sideActivityRelated,
  archiveRelated,
}

/// Extended node display info for the tech tree.
class NodeDisplayInfo {
  final String nodeId;
  final NodeStateLabel state;
  final String? tooltipOverride;
  final String? whyThisMatters;
  final bool highlighted;

  const NodeDisplayInfo({
    required this.nodeId,
    required this.state,
    this.tooltipOverride,
    this.whyThisMatters,
    this.highlighted = false,
  });

  factory NodeDisplayInfo.fromJson(Map<String, dynamic> json) {
    return NodeDisplayInfo(
      nodeId: json['nodeId'] as String,
      state: NodeStateLabel.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => NodeStateLabel.blockedByResource,
      ),
      tooltipOverride: json['tooltipOverride'] as String?,
      whyThisMatters: json['whyThisMatters'] as String?,
      highlighted: json['highlighted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'state': state.name,
        'tooltipOverride': tooltipOverride,
        'whyThisMatters': whyThisMatters,
        'highlighted': highlighted,
      };
}

// ─── 4. Room Preview Card ───────────────────────────────────────────

/// Data for the room preview card shown before entering a room.
class RoomPreviewData {
  final String roomId;
  final String name;
  final String subtitle;
  final String? roomLawName;
  final String? roomLawDescription;
  final int masteryStars;
  final int maxMasteryStars;
  final double completionPercent;
  final double codexPercent;
  final int secretsFound;
  final int totalSecrets;
  final bool hasRevisitContent;
  final String? featuredBadge;
  final List<String> pinnedGoals;

  const RoomPreviewData({
    required this.roomId,
    required this.name,
    required this.subtitle,
    this.roomLawName,
    this.roomLawDescription,
    this.masteryStars = 0,
    this.maxMasteryStars = 7,
    this.completionPercent = 0.0,
    this.codexPercent = 0.0,
    this.secretsFound = 0,
    this.totalSecrets = 3,
    this.hasRevisitContent = false,
    this.featuredBadge,
    this.pinnedGoals = const [],
  });

  factory RoomPreviewData.fromJson(Map<String, dynamic> json) {
    return RoomPreviewData(
      roomId: json['roomId'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String,
      roomLawName: json['roomLawName'] as String?,
      roomLawDescription: json['roomLawDescription'] as String?,
      masteryStars: json['masteryStars'] as int? ?? 0,
      maxMasteryStars: json['maxMasteryStars'] as int? ?? 7,
      completionPercent:
          (json['completionPercent'] as num?)?.toDouble() ?? 0.0,
      codexPercent: (json['codexPercent'] as num?)?.toDouble() ?? 0.0,
      secretsFound: json['secretsFound'] as int? ?? 0,
      totalSecrets: json['totalSecrets'] as int? ?? 3,
      hasRevisitContent: json['hasRevisitContent'] as bool? ?? false,
      featuredBadge: json['featuredBadge'] as String?,
      pinnedGoals: (json['pinnedGoals'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'name': name,
        'subtitle': subtitle,
        'roomLawName': roomLawName,
        'roomLawDescription': roomLawDescription,
        'masteryStars': masteryStars,
        'maxMasteryStars': maxMasteryStars,
        'completionPercent': completionPercent,
        'codexPercent': codexPercent,
        'secretsFound': secretsFound,
        'totalSecrets': totalSecrets,
        'hasRevisitContent': hasRevisitContent,
        'featuredBadge': featuredBadge,
        'pinnedGoals': pinnedGoals,
      };
}

// ─── 5. Room Completion Summary ─────────────────────────────────────

/// Item in the "what changed" summary after room milestones.
class SummaryChangeItem {
  final String label;
  final String category;
  final String? detail;

  const SummaryChangeItem({
    required this.label,
    required this.category,
    this.detail,
  });

  factory SummaryChangeItem.fromJson(Map<String, dynamic> json) {
    return SummaryChangeItem(
      label: json['label'] as String,
      category: json['category'] as String,
      detail: json['detail'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'category': category,
        'detail': detail,
      };
}

/// Summary shown after major room milestones.
class RoomMilestoneSummary {
  final String roomId;
  final String milestoneTitle;
  final List<SummaryChangeItem> changes;
  final List<String> newArchiveEntries;
  final List<String> newSecretLeads;
  final int masteryStarsGained;
  final List<String> revisitHints;
  final DateTime generatedAt;

  const RoomMilestoneSummary({
    required this.roomId,
    required this.milestoneTitle,
    this.changes = const [],
    this.newArchiveEntries = const [],
    this.newSecretLeads = const [],
    this.masteryStarsGained = 0,
    this.revisitHints = const [],
    required this.generatedAt,
  });

  factory RoomMilestoneSummary.fromJson(Map<String, dynamic> json) {
    return RoomMilestoneSummary(
      roomId: json['roomId'] as String,
      milestoneTitle: json['milestoneTitle'] as String,
      changes: (json['changes'] as List<dynamic>?)
              ?.map(
                  (e) => SummaryChangeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      newArchiveEntries: (json['newArchiveEntries'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      newSecretLeads: (json['newSecretLeads'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      masteryStarsGained: json['masteryStarsGained'] as int? ?? 0,
      revisitHints: (json['revisitHints'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'milestoneTitle': milestoneTitle,
        'changes': changes.map((e) => e.toJson()).toList(),
        'newArchiveEntries': newArchiveEntries,
        'newSecretLeads': newSecretLeads,
        'masteryStarsGained': masteryStarsGained,
        'revisitHints': revisitHints,
        'generatedAt': generatedAt.toIso8601String(),
      };
}

// ─── 6. Onboarding / Glossary ───────────────────────────────────────

/// Onboarding step for progressive disclosure.
class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final String triggerCondition;
  final String? relatedMechanic;
  final bool completed;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.triggerCondition,
    this.relatedMechanic,
    this.completed = false,
  });

  OnboardingStep copyWith({
    String? id,
    String? title,
    String? description,
    String? triggerCondition,
    String? relatedMechanic,
    bool? completed,
  }) {
    return OnboardingStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      triggerCondition: triggerCondition ?? this.triggerCondition,
      relatedMechanic: relatedMechanic ?? this.relatedMechanic,
      completed: completed ?? this.completed,
    );
  }

  factory OnboardingStep.fromJson(Map<String, dynamic> json) {
    return OnboardingStep(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      triggerCondition: json['triggerCondition'] as String,
      relatedMechanic: json['relatedMechanic'] as String?,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'triggerCondition': triggerCondition,
        'relatedMechanic': relatedMechanic,
        'completed': completed,
      };
}

/// Glossary entry for in-context mechanic explanations.
class GlossaryEntry {
  final String id;
  final String term;
  final String definition;
  final String? category;
  final String? relatedRoomId;
  final bool discoveredInGame;

  const GlossaryEntry({
    required this.id,
    required this.term,
    required this.definition,
    this.category,
    this.relatedRoomId,
    this.discoveredInGame = false,
  });

  GlossaryEntry copyWith({
    String? id,
    String? term,
    String? definition,
    String? category,
    String? relatedRoomId,
    bool? discoveredInGame,
  }) {
    return GlossaryEntry(
      id: id ?? this.id,
      term: term ?? this.term,
      definition: definition ?? this.definition,
      category: category ?? this.category,
      relatedRoomId: relatedRoomId ?? this.relatedRoomId,
      discoveredInGame: discoveredInGame ?? this.discoveredInGame,
    );
  }

  factory GlossaryEntry.fromJson(Map<String, dynamic> json) {
    return GlossaryEntry(
      id: json['id'] as String,
      term: json['term'] as String,
      definition: json['definition'] as String,
      category: json['category'] as String?,
      relatedRoomId: json['relatedRoomId'] as String?,
      discoveredInGame: json['discoveredInGame'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'term': term,
        'definition': definition,
        'category': category,
        'relatedRoomId': relatedRoomId,
        'discoveredInGame': discoveredInGame,
      };
}

// ─── 7. Micro-Life / Atmosphere ─────────────────────────────────────

/// Type of ambient micro-life effect in a room.
enum MicroLifeType {
  drone,
  monitor,
  fan,
  shadow,
  particle,
  signalFog,
  thermalShimmer,
  staticRain,
  guideReaction,
  idleAnimation,
  machineWeather,
  landmarkBreathing,
  statusLed,
}

/// A single micro-life ambient element in a room.
class MicroLifeEffect {
  final String id;
  final MicroLifeType type;
  final String description;
  final String triggerCondition;
  final double intensityMin;
  final double intensityMax;
  final bool reactsToCombo;
  final bool reactsToDanger;
  final bool reactsToTrust;
  final bool reactsToProgression;

  const MicroLifeEffect({
    required this.id,
    required this.type,
    required this.description,
    this.triggerCondition = 'always',
    this.intensityMin = 0.1,
    this.intensityMax = 1.0,
    this.reactsToCombo = false,
    this.reactsToDanger = false,
    this.reactsToTrust = false,
    this.reactsToProgression = false,
  });

  factory MicroLifeEffect.fromJson(Map<String, dynamic> json) {
    return MicroLifeEffect(
      id: json['id'] as String,
      type: MicroLifeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MicroLifeType.particle,
      ),
      description: json['description'] as String,
      triggerCondition: json['triggerCondition'] as String? ?? 'always',
      intensityMin: (json['intensityMin'] as num?)?.toDouble() ?? 0.1,
      intensityMax: (json['intensityMax'] as num?)?.toDouble() ?? 1.0,
      reactsToCombo: json['reactsToCombo'] as bool? ?? false,
      reactsToDanger: json['reactsToDanger'] as bool? ?? false,
      reactsToTrust: json['reactsToTrust'] as bool? ?? false,
      reactsToProgression: json['reactsToProgression'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'description': description,
        'triggerCondition': triggerCondition,
        'intensityMin': intensityMin,
        'intensityMax': intensityMax,
        'reactsToCombo': reactsToCombo,
        'reactsToDanger': reactsToDanger,
        'reactsToTrust': reactsToTrust,
        'reactsToProgression': reactsToProgression,
      };
}

/// Landmark reactivity configuration for a room.
class LandmarkReactivity {
  final String landmarkId;
  final String breathingStyle;
  final String lightingShiftStyle;
  final List<String> scarConditions;

  const LandmarkReactivity({
    required this.landmarkId,
    this.breathingStyle = 'gentle_pulse',
    this.lightingShiftStyle = 'ambient',
    this.scarConditions = const [],
  });

  factory LandmarkReactivity.fromJson(Map<String, dynamic> json) {
    return LandmarkReactivity(
      landmarkId: json['landmarkId'] as String,
      breathingStyle: json['breathingStyle'] as String? ?? 'gentle_pulse',
      lightingShiftStyle:
          json['lightingShiftStyle'] as String? ?? 'ambient',
      scarConditions: (json['scarConditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'landmarkId': landmarkId,
        'breathingStyle': breathingStyle,
        'lightingShiftStyle': lightingShiftStyle,
        'scarConditions': scarConditions,
      };
}

// ─── 8. Room UX Authoring ───────────────────────────────────────────

/// Per-room UX authoring configuration.
class RoomUXProfile {
  final String roomId;
  final RoomTransitionConfig transition;
  final String roomLawBadgeStyle;
  final String eventCardStyle;
  final String sideActivityEntryStyle;
  final String landmarkAnimBehavior;
  final String transformRevealBehavior;
  final String completionCeremonyFormat;
  final List<MicroLifeEffect> microLifeEffects;
  final LandmarkReactivity? landmarkReactivity;

  const RoomUXProfile({
    required this.roomId,
    required this.transition,
    this.roomLawBadgeStyle = 'default',
    this.eventCardStyle = 'default',
    this.sideActivityEntryStyle = 'default',
    this.landmarkAnimBehavior = 'idle',
    this.transformRevealBehavior = 'glow_expand',
    this.completionCeremonyFormat = 'standard',
    this.microLifeEffects = const [],
    this.landmarkReactivity,
  });

  factory RoomUXProfile.fromJson(Map<String, dynamic> json) {
    return RoomUXProfile(
      roomId: json['roomId'] as String,
      transition: json['transition'] != null
          ? RoomTransitionConfig.fromJson(
              json['transition'] as Map<String, dynamic>)
          : RoomTransitionConfig(roomId: json['roomId'] as String),
      roomLawBadgeStyle: json['roomLawBadgeStyle'] as String? ?? 'default',
      eventCardStyle: json['eventCardStyle'] as String? ?? 'default',
      sideActivityEntryStyle:
          json['sideActivityEntryStyle'] as String? ?? 'default',
      landmarkAnimBehavior:
          json['landmarkAnimBehavior'] as String? ?? 'idle',
      transformRevealBehavior:
          json['transformRevealBehavior'] as String? ?? 'glow_expand',
      completionCeremonyFormat:
          json['completionCeremonyFormat'] as String? ?? 'standard',
      microLifeEffects: (json['microLifeEffects'] as List<dynamic>?)
              ?.map(
                  (e) => MicroLifeEffect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      landmarkReactivity: json['landmarkReactivity'] != null
          ? LandmarkReactivity.fromJson(
              json['landmarkReactivity'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'transition': transition.toJson(),
        'roomLawBadgeStyle': roomLawBadgeStyle,
        'eventCardStyle': eventCardStyle,
        'sideActivityEntryStyle': sideActivityEntryStyle,
        'landmarkAnimBehavior': landmarkAnimBehavior,
        'transformRevealBehavior': transformRevealBehavior,
        'completionCeremonyFormat': completionCeremonyFormat,
        'microLifeEffects':
            microLifeEffects.map((e) => e.toJson()).toList(),
        'landmarkReactivity': landmarkReactivity?.toJson(),
      };
}

// ─── 9. Accessibility Extensions ────────────────────────────────────

/// Contrast mode for UI readability.
enum ContrastMode {
  standard,
  highContrast,
  extraHighContrast,
}

/// Tooltip behavior mode.
enum TooltipBehavior {
  onHover,
  onTap,
  always,
  disabled,
}

/// Room transition speed preference.
enum TransitionSpeed {
  full,
  fast,
  instant,
}

// ─── 10. Aggregate UI/UX State ──────────────────────────────────────

/// Aggregate state for UI/UX systems, stored in game state.
class UIUXState {
  final List<OnboardingStep> onboardingProgress;
  final List<GlossaryEntry> discoveredGlossary;
  final List<RoomMilestoneSummary> recentSummaries;
  final Map<String, bool> seenTransitions;
  final ContrastMode contrastMode;
  final TooltipBehavior tooltipBehavior;
  final TransitionSpeed transitionSpeed;
  final bool focusModeEnabled;
  final bool pinnedGoalsMinimized;

  const UIUXState({
    this.onboardingProgress = const [],
    this.discoveredGlossary = const [],
    this.recentSummaries = const [],
    this.seenTransitions = const {},
    this.contrastMode = ContrastMode.standard,
    this.tooltipBehavior = TooltipBehavior.onHover,
    this.transitionSpeed = TransitionSpeed.full,
    this.focusModeEnabled = false,
    this.pinnedGoalsMinimized = false,
  });

  UIUXState copyWith({
    List<OnboardingStep>? onboardingProgress,
    List<GlossaryEntry>? discoveredGlossary,
    List<RoomMilestoneSummary>? recentSummaries,
    Map<String, bool>? seenTransitions,
    ContrastMode? contrastMode,
    TooltipBehavior? tooltipBehavior,
    TransitionSpeed? transitionSpeed,
    bool? focusModeEnabled,
    bool? pinnedGoalsMinimized,
  }) {
    return UIUXState(
      onboardingProgress: onboardingProgress ?? this.onboardingProgress,
      discoveredGlossary: discoveredGlossary ?? this.discoveredGlossary,
      recentSummaries: recentSummaries ?? this.recentSummaries,
      seenTransitions: seenTransitions ?? this.seenTransitions,
      contrastMode: contrastMode ?? this.contrastMode,
      tooltipBehavior: tooltipBehavior ?? this.tooltipBehavior,
      transitionSpeed: transitionSpeed ?? this.transitionSpeed,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
      pinnedGoalsMinimized:
          pinnedGoalsMinimized ?? this.pinnedGoalsMinimized,
    );
  }

  factory UIUXState.fromJson(Map<String, dynamic> json) {
    return UIUXState(
      onboardingProgress: (json['onboardingProgress'] as List<dynamic>?)
              ?.map(
                  (e) => OnboardingStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      discoveredGlossary: (json['discoveredGlossary'] as List<dynamic>?)
              ?.map((e) => GlossaryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recentSummaries: (json['recentSummaries'] as List<dynamic>?)
              ?.map((e) =>
                  RoomMilestoneSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      seenTransitions: (json['seenTransitions'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as bool)) ??
          const {},
      contrastMode: ContrastMode.values.firstWhere(
        (e) => e.name == json['contrastMode'],
        orElse: () => ContrastMode.standard,
      ),
      tooltipBehavior: TooltipBehavior.values.firstWhere(
        (e) => e.name == json['tooltipBehavior'],
        orElse: () => TooltipBehavior.onHover,
      ),
      transitionSpeed: TransitionSpeed.values.firstWhere(
        (e) => e.name == json['transitionSpeed'],
        orElse: () => TransitionSpeed.full,
      ),
      focusModeEnabled: json['focusModeEnabled'] as bool? ?? false,
      pinnedGoalsMinimized:
          json['pinnedGoalsMinimized'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'onboardingProgress':
            onboardingProgress.map((e) => e.toJson()).toList(),
        'discoveredGlossary':
            discoveredGlossary.map((e) => e.toJson()).toList(),
        'recentSummaries':
            recentSummaries.map((e) => e.toJson()).toList(),
        'seenTransitions': seenTransitions,
        'contrastMode': contrastMode.name,
        'tooltipBehavior': tooltipBehavior.name,
        'transitionSpeed': transitionSpeed.name,
        'focusModeEnabled': focusModeEnabled,
        'pinnedGoalsMinimized': pinnedGoalsMinimized,
      };
}
