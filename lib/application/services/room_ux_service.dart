import '../../domain/models/ui_ux_systems.dart';

/// Service that manages room UX profiles, transitions, onboarding,
/// glossary, and milestone summaries.
///
/// Pure Dart — no Flutter imports.
class RoomUXService {
  final Map<String, RoomUXProfile> _profiles;
  final List<OnboardingStep> _onboardingSteps;
  final List<GlossaryEntry> _glossaryEntries;

  RoomUXService({required Map<String, dynamic> configJson})
      : _profiles = _buildProfiles(configJson),
        _onboardingSteps = _buildOnboardingSteps(configJson),
        _glossaryEntries = _buildGlossaryEntries(configJson);

  // ─── Profile Queries ──────────────────────────────────────────────

  /// Get the UX profile for a room by its id.
  RoomUXProfile? profileForRoom(String roomId) => _profiles[roomId];

  /// Get the transition config for a room.
  RoomTransitionConfig? transitionForRoom(String roomId) =>
      _profiles[roomId]?.transition;

  /// Get all micro-life effects for a room.
  List<MicroLifeEffect> microLifeForRoom(String roomId) =>
      _profiles[roomId]?.microLifeEffects ?? const [];

  /// Get active micro-life effects filtered by trigger condition.
  List<MicroLifeEffect> activeMicroLife(
    String roomId, {
    bool comboActive = false,
    bool dangerActive = false,
    bool trustHigh = false,
    bool progressionLate = false,
  }) {
    final effects = microLifeForRoom(roomId);
    return effects.where((e) {
      if (e.triggerCondition == 'always') return true;
      if (e.triggerCondition == 'combo_high' && comboActive) return true;
      if (e.triggerCondition == 'danger_active' && dangerActive) return true;
      if (e.triggerCondition == 'trust_high' && trustHigh) return true;
      if (e.triggerCondition == 'progression_late' && progressionLate) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Get landmark reactivity config for a room.
  LandmarkReactivity? landmarkReactivityForRoom(String roomId) =>
      _profiles[roomId]?.landmarkReactivity;

  /// All room UX profiles.
  List<RoomUXProfile> get allProfiles => _profiles.values.toList();

  // ─── Transition Helpers ───────────────────────────────────────────

  /// Check if a room transition has been seen before.
  bool hasSeenTransition(UIUXState state, String roomId) =>
      state.seenTransitions[roomId] ?? false;

  /// Mark a room transition as seen.
  UIUXState markTransitionSeen(UIUXState state, String roomId) {
    final updated = Map<String, bool>.from(state.seenTransitions);
    updated[roomId] = true;
    return state.copyWith(seenTransitions: updated);
  }

  /// Compute effective transition duration based on settings and seen state.
  int effectiveTransitionDurationMs(
    String roomId,
    UIUXState state, {
    bool reducedMotion = false,
    String transitionSpeed = 'full',
  }) {
    final config = transitionForRoom(roomId);
    if (config == null) return 400;
    if (reducedMotion) return 200;

    final baseMs = config.enterDurationMs;
    final seen = hasSeenTransition(state, roomId);
    final skipFast = seen && config.skippableAfterFirst;

    switch (transitionSpeed) {
      case 'instant':
        return 0;
      case 'fast':
        return skipFast ? (baseMs * 0.3).round() : (baseMs * 0.5).round();
      default:
        return skipFast ? (baseMs * 0.5).round() : baseMs;
    }
  }

  // ─── Onboarding ───────────────────────────────────────────────────

  /// All onboarding steps from config.
  List<OnboardingStep> get onboardingSteps => _onboardingSteps;

  /// Get the next uncompleted onboarding step for a trigger condition.
  OnboardingStep? nextOnboardingStep(
    UIUXState state,
    String triggerCondition,
  ) {
    final completedIds =
        state.onboardingProgress.where((s) => s.completed).map((s) => s.id).toSet();
    for (final step in _onboardingSteps) {
      if (step.triggerCondition == triggerCondition &&
          !completedIds.contains(step.id)) {
        return step;
      }
    }
    return null;
  }

  /// Mark an onboarding step as completed.
  UIUXState completeOnboardingStep(UIUXState state, String stepId) {
    final existing = state.onboardingProgress.toList();
    final index = existing.indexWhere((s) => s.id == stepId);
    if (index >= 0) {
      existing[index] = existing[index].copyWith(completed: true);
    } else {
      final def = _onboardingSteps.where((s) => s.id == stepId).firstOrNull;
      if (def != null) {
        existing.add(def.copyWith(completed: true));
      }
    }
    return state.copyWith(onboardingProgress: existing);
  }

  // ─── Glossary ─────────────────────────────────────────────────────

  /// All glossary entries from config.
  List<GlossaryEntry> get glossaryEntries => _glossaryEntries;

  /// Discover a glossary entry.
  UIUXState discoverGlossaryEntry(UIUXState state, String entryId) {
    final existing = state.discoveredGlossary.toList();
    if (existing.any((e) => e.id == entryId)) return state;
    final def = _glossaryEntries.where((e) => e.id == entryId).firstOrNull;
    if (def == null) return state;
    existing.add(def.copyWith(discoveredInGame: true));
    return state.copyWith(discoveredGlossary: existing);
  }

  /// Get glossary entries for a category.
  List<GlossaryEntry> glossaryForCategory(String category) =>
      _glossaryEntries.where((e) => e.category == category).toList();

  // ─── Milestone Summaries ──────────────────────────────────────────

  /// Add a milestone summary to recent summaries.
  UIUXState addMilestoneSummary(
    UIUXState state,
    RoomMilestoneSummary summary,
  ) {
    final summaries = state.recentSummaries.toList();
    summaries.insert(0, summary);
    // Keep only last 10 summaries.
    if (summaries.length > 10) {
      summaries.removeRange(10, summaries.length);
    }
    return state.copyWith(recentSummaries: summaries);
  }

  /// Build a room preview data object from room info.
  RoomPreviewData buildRoomPreview({
    required String roomId,
    required String name,
    required String subtitle,
    String? roomLawName,
    String? roomLawDescription,
    int masteryStars = 0,
    int maxMasteryStars = 7,
    double completionPercent = 0.0,
    double codexPercent = 0.0,
    int secretsFound = 0,
    int totalSecrets = 3,
    bool hasRevisitContent = false,
    String? featuredBadge,
    List<String> pinnedGoals = const [],
  }) {
    return RoomPreviewData(
      roomId: roomId,
      name: name,
      subtitle: subtitle,
      roomLawName: roomLawName,
      roomLawDescription: roomLawDescription,
      masteryStars: masteryStars,
      maxMasteryStars: maxMasteryStars,
      completionPercent: completionPercent,
      codexPercent: codexPercent,
      secretsFound: secretsFound,
      totalSecrets: totalSecrets,
      hasRevisitContent: hasRevisitContent,
      featuredBadge: featuredBadge,
      pinnedGoals: pinnedGoals,
    );
  }

  // ─── Focus Mode ───────────────────────────────────────────────────

  /// Toggle focus mode.
  UIUXState toggleFocusMode(UIUXState state) =>
      state.copyWith(focusModeEnabled: !state.focusModeEnabled);

  /// Toggle pinned goals minimization.
  UIUXState togglePinnedGoals(UIUXState state) =>
      state.copyWith(pinnedGoalsMinimized: !state.pinnedGoalsMinimized);

  // ─── Node State Classification ────────────────────────────────────

  /// Classify a node's visual state for the tech tree.
  NodeStateLabel classifyNodeState({
    required bool canAfford,
    required bool dependenciesMet,
    required bool owned,
    required bool maxed,
    bool blockedByLaw = false,
    bool blockedByRoute = false,
    bool guideRecommended = false,
    bool secretRelated = false,
    bool sideActivityRelated = false,
    bool archiveRelated = false,
  }) {
    if (maxed) return NodeStateLabel.maxLevel;
    if (owned) return NodeStateLabel.owned;
    if (blockedByLaw) return NodeStateLabel.blockedByRoomLaw;
    if (blockedByRoute) return NodeStateLabel.blockedByRoute;
    if (!dependenciesMet) return NodeStateLabel.blockedByDependency;
    if (!canAfford) return NodeStateLabel.blockedByResource;
    if (guideRecommended) return NodeStateLabel.guideRecommended;
    if (secretRelated) return NodeStateLabel.secretRelated;
    if (sideActivityRelated) return NodeStateLabel.sideActivityRelated;
    if (archiveRelated) return NodeStateLabel.archiveRelated;
    return NodeStateLabel.purchasable;
  }

  // ─── Config Parsing ───────────────────────────────────────────────

  static Map<String, RoomUXProfile> _buildProfiles(
    Map<String, dynamic> json,
  ) {
    final list = json['roomUXProfiles'] as List<dynamic>? ?? [];
    final result = <String, RoomUXProfile>{};
    for (final item in list) {
      if (item is Map<String, dynamic> && item['roomId'] != null) {
        final profile = RoomUXProfile.fromJson(item);
        result[profile.roomId] = profile;
      }
    }
    return result;
  }

  static List<OnboardingStep> _buildOnboardingSteps(
    Map<String, dynamic> json,
  ) {
    final list = json['onboardingSteps'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .where((e) => e['id'] != null)
        .map((e) => OnboardingStep.fromJson(e))
        .toList();
  }

  static List<GlossaryEntry> _buildGlossaryEntries(
    Map<String, dynamic> json,
  ) {
    final list = json['glossaryEntries'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .where((e) => e['id'] != null)
        .map((e) => GlossaryEntry.fromJson(e))
        .toList();
  }
}
