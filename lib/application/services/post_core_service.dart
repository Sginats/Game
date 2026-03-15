import '../../domain/models/post_core_systems.dart';

/// Service that manages all post-core retention systems.
/// Pure Dart — no Flutter imports.
///
/// Config definitions are parsed eagerly from a raw JSON map via the
/// constructor and cached in internal collections for O(1) lookups.
/// Query helpers filter cached definitions by room, section, timing, etc.
/// State-mutation helpers operate on [PostCoreState] using the immutable
/// copyWith pattern — every mutation returns a *new* state instance.
class PostCoreService {
  // ---------------------------------------------------------------------------
  // Parsed config data (immutable after init)
  // ---------------------------------------------------------------------------

  /// Mastery goal definitions keyed by room id for fast room-level queries.
  final Map<String, List<RoomMasteryGoal>> _masteryGoalsByRoom;

  /// Relic set definitions keyed by set id.
  final Map<String, RelicSetDefinition> _relicSetDefsById;

  /// Ordered list of all relic set definitions.
  final List<RelicSetDefinition> _relicSetDefs;

  /// Multi-room secret definitions keyed by secret id.
  final Map<String, MultiRoomSecret> _multiRoomSecretDefsById;

  /// Ordered list of all multi-room secret definitions.
  final List<MultiRoomSecret> _multiRoomSecretDefs;

  /// Mastery contract definitions keyed by room id.
  final Map<String, List<MasteryContract>> _contractsByRoom;

  /// Archive completion reward definitions keyed by archive section.
  final Map<String, List<ArchiveCompletionReward>> _archiveRewardsBySection;

  /// Revisit unlock definitions keyed by room id.
  final Map<String, List<RevisitUnlock>> _revisitUnlockDefs;

  /// Room atmosphere configs keyed by room id.
  final Map<String, RoomAtmosphereConfig> _atmosphereDefs;

  /// Featured room rotation configs in config order.
  final List<FeaturedRoomConfig> _featuredRotation;

  /// Guide side-objective definitions.
  final List<GuideSideObjective> _guideSideObjectiveDefs;

  /// Cosmetic reward definitions keyed by id.
  final Map<String, CosmeticReward> _cosmeticRewardsById;

  /// Ordered list of all cosmetic reward definitions.
  final List<CosmeticReward> _cosmeticRewardDefs;

  // ---------------------------------------------------------------------------
  // Guide mood event → effect mapping
  // ---------------------------------------------------------------------------

  /// Maps a guide-event name to its trust-level delta.
  static const Map<String, int> _trustDeltas = {
    'recklessPlay': -1,
    'carefulPlay': 1,
    'anomalyHunt': 0,
    'ignoreGuide': -2,
    'followGuide': 1,
    'exploitDanger': -1,
    'protectRoom': 1,
    'routeRepeat': 0,
  };

  /// Maps a guide-event name to its affinity-score delta.
  static const Map<String, double> _affinityDeltas = {
    'recklessPlay': -0.5,
    'carefulPlay': 0.5,
    'anomalyHunt': 0.3,
    'ignoreGuide': -1.0,
    'followGuide': 0.7,
    'exploitDanger': -0.5,
    'protectRoom': 0.5,
    'routeRepeat': 0.0,
  };

  /// Maps a guide-event name to the resulting [GuideMood].
  static const Map<String, GuideMood> _eventMoods = {
    'recklessPlay': GuideMood.suspicious,
    'carefulPlay': GuideMood.proud,
    'anomalyHunt': GuideMood.fascinated,
    'ignoreGuide': GuideMood.disappointed,
    'followGuide': GuideMood.proud,
    'exploitDanger': GuideMood.worried,
    'protectRoom': GuideMood.hopeful,
    'routeRepeat': GuideMood.calm,
  };

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  /// Creates the service by eagerly parsing all definition data from
  /// [configJson].
  ///
  /// Missing top-level keys are handled gracefully — the corresponding
  /// collections default to empty.
  PostCoreService({required Map<String, dynamic> configJson})
      : _masteryGoalsByRoom = _buildMasteryGoalsByRoom(configJson),
        _relicSetDefsById = _buildRelicSetDefsById(configJson),
        _relicSetDefs = _buildRelicSetDefs(configJson),
        _multiRoomSecretDefsById = _buildMultiRoomSecretDefsById(configJson),
        _multiRoomSecretDefs = _buildMultiRoomSecretDefs(configJson),
        _contractsByRoom = _buildContractsByRoom(configJson),
        _archiveRewardsBySection = _buildArchiveRewardsBySection(configJson),
        _revisitUnlockDefs = _buildRevisitUnlockDefs(configJson),
        _atmosphereDefs = _buildAtmosphereDefs(configJson),
        _featuredRotation = _buildFeaturedRotation(configJson),
        _guideSideObjectiveDefs = _buildGuideSideObjectiveDefs(configJson),
        _cosmeticRewardsById = _buildCosmeticRewardsById(configJson),
        _cosmeticRewardDefs = _buildCosmeticRewardDefs(configJson);

  // ---------------------------------------------------------------------------
  // Factory parsing helpers
  // ---------------------------------------------------------------------------

  static Map<String, List<RoomMasteryGoal>> _buildMasteryGoalsByRoom(
    Map<String, dynamic> json,
  ) {
    final raw = json['masteryGoals'];
    if (raw is! List) return const {};
    final result = <String, List<RoomMasteryGoal>>{};
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['id'] is! String) continue;
      final goal = RoomMasteryGoal.fromJson(entry);
      result.putIfAbsent(goal.roomId, () => []).add(goal);
    }
    return result;
  }

  static Map<String, RelicSetDefinition> _buildRelicSetDefsById(
    Map<String, dynamic> json,
  ) {
    final raw = json['relicSets'];
    if (raw is! List) return const {};
    final result = <String, RelicSetDefinition>{};
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['id'] is! String) continue;
      final def = RelicSetDefinition.fromJson(entry);
      result[def.id] = def;
    }
    return result;
  }

  static List<RelicSetDefinition> _buildRelicSetDefs(
    Map<String, dynamic> json,
  ) {
    final raw = json['relicSets'];
    if (raw is! List) return const [];
    final result = <RelicSetDefinition>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['id'] is! String) continue;
      result.add(RelicSetDefinition.fromJson(entry));
    }
    return result;
  }

  static Map<String, MultiRoomSecret> _buildMultiRoomSecretDefsById(
    Map<String, dynamic> json,
  ) {
    final raw = json['multiRoomSecrets'];
    if (raw is! List) return const {};
    final result = <String, MultiRoomSecret>{};
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['id'] is! String) continue;
      final secret = MultiRoomSecret.fromJson(entry);
      result[secret.id] = secret;
    }
    return result;
  }

  static List<MultiRoomSecret> _buildMultiRoomSecretDefs(
    Map<String, dynamic> json,
  ) {
    final raw = json['multiRoomSecrets'];
    if (raw is! List) return const [];
    final result = <MultiRoomSecret>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['id'] is! String) continue;
      result.add(MultiRoomSecret.fromJson(entry));
    }
    return result;
  }

  static Map<String, List<MasteryContract>> _buildContractsByRoom(
    Map<String, dynamic> json,
  ) {
    final raw = json['contracts'];
    if (raw is! List) return const {};
    final result = <String, List<MasteryContract>>{};
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['id'] is! String) continue;
      final contract = MasteryContract.fromJson(entry);
      result.putIfAbsent(contract.roomId, () => []).add(contract);
    }
    return result;
  }

  static Map<String, List<ArchiveCompletionReward>>
      _buildArchiveRewardsBySection(Map<String, dynamic> json) {
    final raw = json['archiveRewards'];
    if (raw is! List) return const {};
    final result = <String, List<ArchiveCompletionReward>>{};
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['id'] is! String) continue;
      final reward = ArchiveCompletionReward.fromJson(entry);
      result.putIfAbsent(reward.archiveSection, () => []).add(reward);
    }
    return result;
  }

  static Map<String, List<RevisitUnlock>> _buildRevisitUnlockDefs(
    Map<String, dynamic> json,
  ) {
    final raw = json['revisitUnlocks'];
    if (raw is! Map<String, dynamic>) return const {};
    final result = <String, List<RevisitUnlock>>{};
    for (final entry in raw.entries) {
      final roomList = entry.value;
      if (roomList is! List) continue;
      final unlocks = <RevisitUnlock>[];
      for (final item in roomList) {
        if (item is! Map<String, dynamic>) continue;
        if (item['id'] is! String) continue;
        unlocks.add(RevisitUnlock.fromJson(item));
      }
      if (unlocks.isNotEmpty) {
        result[entry.key] = unlocks;
      }
    }
    return result;
  }

  static Map<String, RoomAtmosphereConfig> _buildAtmosphereDefs(
    Map<String, dynamic> json,
  ) {
    final raw = json['atmospheres'];
    if (raw is! Map<String, dynamic>) return const {};
    final result = <String, RoomAtmosphereConfig>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;
      result[entry.key] = RoomAtmosphereConfig.fromJson(value);
    }
    return result;
  }

  static List<FeaturedRoomConfig> _buildFeaturedRotation(
    Map<String, dynamic> json,
  ) {
    final raw = json['featuredRotation'];
    if (raw is! List) return const [];
    final result = <FeaturedRoomConfig>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['roomId'] is! String) continue;
      result.add(FeaturedRoomConfig.fromJson(entry));
    }
    return result;
  }

  static List<GuideSideObjective> _buildGuideSideObjectiveDefs(
    Map<String, dynamic> json,
  ) {
    final raw = json['guideSideObjectives'];
    if (raw is! List) return const [];
    final result = <GuideSideObjective>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['id'] is! String) continue;
      result.add(GuideSideObjective.fromJson(entry));
    }
    return result;
  }

  static Map<String, CosmeticReward> _buildCosmeticRewardsById(
    Map<String, dynamic> json,
  ) {
    final raw = json['cosmeticRewards'];
    if (raw is! List) return const {};
    final result = <String, CosmeticReward>{};
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['id'] is! String) continue;
      final reward = CosmeticReward.fromJson(entry);
      result[reward.id] = reward;
    }
    return result;
  }

  static List<CosmeticReward> _buildCosmeticRewardDefs(
    Map<String, dynamic> json,
  ) {
    final raw = json['cosmeticRewards'];
    if (raw is! List) return const [];
    final result = <CosmeticReward>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['id'] is! String) continue;
      result.add(CosmeticReward.fromJson(entry));
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. Room Mastery Queries
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns mastery goal definitions for the given [roomId].
  ///
  /// Returns an empty list when no goals are defined for the room.
  List<RoomMasteryGoal> masteryGoalsForRoom(String roomId) {
    return _masteryGoalsByRoom[roomId] ?? const [];
  }

  /// Builds a [RoomMasteryProfile] for [roomId] by merging definition
  /// data with the live [state].
  ///
  /// If the state already contains a profile for the room, its live values
  /// (stars, best times, etc.) are preserved; otherwise a fresh profile is
  /// created from the definitions alone.
  RoomMasteryProfile buildMasteryProfile(String roomId, PostCoreState state) {
    final existing = state.roomMastery[roomId];
    final goals = _masteryGoalsByRoom[roomId] ?? const [];
    final starsEarned = existing?.starsEarned ?? 0;
    final rank = computeMasteryRank(starsEarned);

    return RoomMasteryProfile(
      roomId: roomId,
      starsEarned: starsEarned,
      rank: rank,
      goals: goals,
      bestClearTimeSeconds: existing?.bestClearTimeSeconds ?? 0,
      bestCombo: existing?.bestCombo ?? 0,
      allSecretsFound: existing?.allSecretsFound ?? false,
      archiveComplete: existing?.archiveComplete ?? false,
    );
  }

  /// Converts a raw star count into a human-readable mastery rank string.
  ///
  /// Rank thresholds:
  /// - 0–1 → `'bronze'`
  /// - 2–3 → `'silver'`
  /// - 4–5 → `'gold'`
  /// - 6   → `'platinum'`
  /// - 7+  → `'diamond'`
  String computeMasteryRank(int starsEarned) {
    if (starsEarned >= 7) return 'diamond';
    if (starsEarned >= 6) return 'platinum';
    if (starsEarned >= 4) return 'gold';
    if (starsEarned >= 2) return 'silver';
    return 'bronze';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. Guide State
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns a new [GuideState] reflecting the mood, trust, and affinity
  /// changes caused by the given [event].
  ///
  /// Recognised events: `recklessPlay`, `carefulPlay`, `anomalyHunt`,
  /// `ignoreGuide`, `followGuide`, `exploitDanger`, `protectRoom`,
  /// `routeRepeat`.  Unrecognised events are silently ignored and the
  /// [current] state is returned unchanged.
  GuideState updateGuideMood(
    GuideState current, {
    required String event,
  }) {
    final mood = _eventMoods[event];
    if (mood == null) return current;

    final trustDelta = _trustDeltas[event] ?? 0;
    final affinityDelta = _affinityDeltas[event] ?? 0.0;

    // Update the behavior counter for this event.
    final counters = Map<String, int>.of(current.behaviorCounters);
    counters[event] = (counters[event] ?? 0) + 1;

    final newTrustLevel = (current.trustLevel + trustDelta).clamp(0, 10);
    final newAffinity = current.affinityScore + affinityDelta;

    return current.copyWith(
      currentMood: mood,
      trustLevel: newTrustLevel,
      affinityScore: newAffinity,
      behaviorCounters: counters,
    );
  }

  /// Computes the [GuideTrustPath] from the current [state].
  ///
  /// Path logic:
  /// - `trustLevel >= 7`  → [GuideTrustPath.highTrust]
  /// - `trustLevel <= 3`  → [GuideTrustPath.lowTrust]
  /// - Mixed positive and negative behaviour counters → [GuideTrustPath.conflicted]
  /// - Fewer than 3 total interactions → [GuideTrustPath.hidden]
  /// - Otherwise falls back to the existing trust path in the state.
  GuideTrustPath computeTrustPath(GuideState state) {
    // Count total interactions to detect very early game.
    final totalInteractions = state.behaviorCounters.values.fold<int>(
      0,
      (sum, v) => sum + v,
    );
    if (totalInteractions < 3) return GuideTrustPath.hidden;

    if (state.trustLevel >= 7) return GuideTrustPath.highTrust;
    if (state.trustLevel <= 3) return GuideTrustPath.lowTrust;

    // Check for conflicted: player exhibits both trust-positive and
    // trust-negative behaviours.
    const positiveEvents = {
      'carefulPlay',
      'followGuide',
      'protectRoom',
    };
    const negativeEvents = {
      'recklessPlay',
      'ignoreGuide',
      'exploitDanger',
    };
    final hasPositive = positiveEvents.any(
      (e) => (state.behaviorCounters[e] ?? 0) > 0,
    );
    final hasNegative = negativeEvents.any(
      (e) => (state.behaviorCounters[e] ?? 0) > 0,
    );
    if (hasPositive && hasNegative) return GuideTrustPath.conflicted;

    return state.trustPath;
  }

  /// Returns guide side-objectives available for the current [state].
  ///
  /// An objective is available when it has not already been completed by
  /// the player (i.e. its id is absent from
  /// [GuideState.completedObjectiveIds]).
  List<GuideSideObjective> availableSideObjectives(GuideState state) {
    return _guideSideObjectiveDefs
        .where((obj) => !state.completedObjectiveIds.contains(obj.id))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. Relic Sets
  // ═══════════════════════════════════════════════════════════════════════════

  /// All relic-set definitions in config order.
  List<RelicSetDefinition> get relicSets => List.unmodifiable(_relicSetDefs);

  /// Checks progress toward the relic set identified by [setId] given the
  /// player's [collectedRelicIds].
  ///
  /// Returns a [RelicSetProgress] reflecting which required relics have
  /// been collected and whether the set is completed.  Returns a zeroed
  /// progress object when [setId] is unknown.
  RelicSetProgress checkSetProgress(
    String setId,
    Set<String> collectedRelicIds,
  ) {
    final def = _relicSetDefsById[setId];
    if (def == null) {
      return RelicSetProgress(setId: setId);
    }
    final matched = collectedRelicIds
        .where((id) => def.requiredRelicIds.contains(id))
        .toSet();
    final isComplete = def.requiredRelicIds.isNotEmpty &&
        def.requiredRelicIds.every(matched.contains);
    return RelicSetProgress(
      setId: setId,
      collectedRelicIds: matched,
      completed: isComplete,
      bonusActive: isComplete,
    );
  }

  /// Returns progress for every defined relic set given the current [state].
  ///
  /// Collected relic ids are sourced from [PostCoreState.relicSetProgress].
  List<RelicSetProgress> allSetProgress(PostCoreState state) {
    // Aggregate all collected relics across state progress entries.
    final allCollected = <String>{};
    for (final progress in state.relicSetProgress) {
      allCollected.addAll(progress.collectedRelicIds);
    }
    return _relicSetDefs
        .map((def) => checkSetProgress(def.id, allCollected))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. Delayed Consequences
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns a new [PostCoreState] with [consequence] appended to the
  /// pending-consequences list.
  PostCoreState addConsequence(
    PostCoreState state,
    DelayedConsequence consequence,
  ) {
    return state.copyWith(
      pendingConsequences: [...state.pendingConsequences, consequence],
    );
  }

  /// Returns a new [PostCoreState] where the consequence identified by
  /// [consequenceId] has been moved from pending to resolved.
  ///
  /// If no pending consequence matches [consequenceId] the state is
  /// returned unchanged.
  PostCoreState resolveConsequence(
    PostCoreState state,
    String consequenceId,
  ) {
    final index = state.pendingConsequences.indexWhere(
      (c) => c.id == consequenceId,
    );
    if (index < 0) return state;

    final resolved =
        state.pendingConsequences[index].copyWith(resolved: true);
    final newPending = List<DelayedConsequence>.of(state.pendingConsequences)
      ..removeAt(index);
    return state.copyWith(
      pendingConsequences: newPending,
      resolvedConsequences: [...state.resolvedConsequences, resolved],
    );
  }

  /// Returns unresolved consequences targeting [roomId].
  ///
  /// A consequence targets a room when its [DelayedConsequence.targetRoomId]
  /// equals [roomId], or when it has no specific target and its
  /// [DelayedConsequence.sourceRoomId] equals [roomId].
  List<DelayedConsequence> pendingForRoom(
    PostCoreState state,
    String roomId,
  ) {
    return state.pendingConsequences.where((c) {
      if (c.targetRoomId != null) return c.targetRoomId == roomId;
      return c.sourceRoomId == roomId;
    }).toList();
  }

  /// Returns unresolved consequences that match the given [timing].
  List<DelayedConsequence> pendingForTiming(
    PostCoreState state,
    ConsequenceTiming timing,
  ) {
    return state.pendingConsequences
        .where((c) => c.timing == timing)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. Revisit Unlocks
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns revisit-unlock definitions for the given [roomId].
  List<RevisitUnlock> revisitUnlocksForRoom(String roomId) {
    return _revisitUnlockDefs[roomId] ?? const [];
  }

  /// Scans all revisit-unlock definitions and unlocks any whose
  /// [RevisitUnlock.triggerCondition] matches [triggerCondition].
  ///
  /// Returns a new [PostCoreState] with updated revisit-unlock entries.
  /// Already-unlocked entries are left unchanged.
  PostCoreState checkAndUnlockRevisits(
    PostCoreState state, {
    required String triggerCondition,
  }) {
    var changed = false;
    final updatedUnlocks = <String, List<RevisitUnlock>>{};

    for (final entry in _revisitUnlockDefs.entries) {
      final roomId = entry.key;
      final defs = entry.value;
      // Start from state overrides if present, else from definitions.
      final stateList = state.revisitUnlocks[roomId] ?? defs;
      final newList = <RevisitUnlock>[];
      for (final unlock in stateList) {
        if (!unlock.unlocked &&
            unlock.triggerCondition == triggerCondition) {
          newList.add(unlock.copyWith(unlocked: true, discovered: true));
          changed = true;
        } else {
          newList.add(unlock);
        }
      }
      updatedUnlocks[roomId] = newList;
    }

    if (!changed) return state;
    // Merge with any existing state entries for rooms not in definitions.
    final merged = Map<String, List<RevisitUnlock>>.of(state.revisitUnlocks);
    merged.addAll(updatedUnlocks);
    return state.copyWith(revisitUnlocks: merged);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. Archive Rewards
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns archive-reward definitions for the given [section].
  List<ArchiveCompletionReward> archiveRewardsForSection(String section) {
    return _archiveRewardsBySection[section] ?? const [];
  }

  /// Checks whether any archive rewards for [section] have become
  /// claimable given the [discoveredCount] and returns a new state with
  /// those rewards marked as claimed.
  ///
  /// Rewards that have already been claimed are left unchanged.
  PostCoreState checkArchiveRewards(
    PostCoreState state, {
    required String section,
    required int discoveredCount,
  }) {
    final defs = _archiveRewardsBySection[section];
    if (defs == null || defs.isEmpty) return state;

    // Build a set of already-claimed reward ids from state.
    final claimedIds = <String>{
      for (final r in state.archiveRewards)
        if (r.claimed) r.id,
    };

    var changed = false;
    final newRewards = <ArchiveCompletionReward>[];

    // Iterate definitions; check if threshold met and not already claimed.
    for (final def in defs) {
      if (!claimedIds.contains(def.id) &&
          discoveredCount >= def.requiredEntries) {
        newRewards.add(def.copyWith(claimed: true));
        changed = true;
      } else if (claimedIds.contains(def.id)) {
        // Keep the already-claimed version from state.
        newRewards.add(def.copyWith(claimed: true));
      } else {
        newRewards.add(def);
      }
    }

    if (!changed) return state;

    // Merge with state rewards for other sections.
    final otherRewards = state.archiveRewards
        .where((r) => r.archiveSection != section)
        .toList();
    return state.copyWith(archiveRewards: [...otherRewards, ...newRewards]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. Atmosphere
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns the [RoomAtmosphereConfig] for [roomId], or `null` if none
  /// is configured.
  RoomAtmosphereConfig? atmosphereForRoom(String roomId) {
    return _atmosphereDefs[roomId];
  }

  /// Returns the [MicroLifeElement]s within the atmosphere of [roomId]
  /// that are active under the given [triggerCondition].
  ///
  /// An element is considered active when its
  /// [MicroLifeElement.triggerCondition] equals `'always'` or matches the
  /// provided [triggerCondition].
  List<MicroLifeElement> activeElements(
    String roomId, {
    required String triggerCondition,
  }) {
    final config = _atmosphereDefs[roomId];
    if (config == null) return const [];
    return config.elements.where((el) {
      return el.triggerCondition == 'always' ||
          el.triggerCondition == triggerCondition;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. Featured Room
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns the [FeaturedRoomConfig] for the given [weekKey], or `null`
  /// if no featured room is scheduled for that week.
  FeaturedRoomConfig? currentFeaturedRoom(String weekKey) {
    for (final config in _featuredRotation) {
      if (config.weekKey == weekKey) return config;
    }
    return null;
  }

  /// Whether the room identified by [roomId] is the featured room for
  /// [weekKey].
  bool isRoomFeatured(String roomId, String weekKey) {
    final featured = currentFeaturedRoom(weekKey);
    return featured != null && featured.roomId == roomId;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. Personal Bests
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns a new [PostCoreState] with the personal-best [record] stored
  /// for its room.
  ///
  /// If a record already exists for the same room the new one replaces it
  /// only when it contains a strictly better pace (lower seconds) or a
  /// strictly higher combo.  When neither metric is better the state is
  /// returned unchanged.
  PostCoreState updatePersonalBest(
    PostCoreState state,
    PersonalBestRecord record,
  ) {
    final existing = state.personalBests[record.roomId];
    if (existing != null) {
      final betterPace = record.bestPaceSeconds > 0 &&
          (existing.bestPaceSeconds == 0 ||
              record.bestPaceSeconds < existing.bestPaceSeconds);
      final betterCombo = record.bestCombo > existing.bestCombo;
      if (!betterPace && !betterCombo) return state;

      // Merge: take the best of each metric.
      final merged = existing.copyWith(
        bestPaceSeconds: betterPace
            ? record.bestPaceSeconds
            : existing.bestPaceSeconds,
        bestCombo:
            betterCombo ? record.bestCombo : existing.bestCombo,
        bestEventChain: record.bestEventChain > existing.bestEventChain
            ? record.bestEventChain
            : existing.bestEventChain,
        bestCompletionStyle: record.bestCompletionStyle,
        recordDate: record.recordDate,
      );
      final updated = Map<String, PersonalBestRecord>.of(state.personalBests);
      updated[record.roomId] = merged;
      return state.copyWith(personalBests: updated);
    }
    final updated = Map<String, PersonalBestRecord>.of(state.personalBests);
    updated[record.roomId] = record;
    return state.copyWith(personalBests: updated);
  }

  /// Returns the [PersonalBestRecord] for [roomId], or `null` if none
  /// has been recorded.
  PersonalBestRecord? personalBestForRoom(
    PostCoreState state,
    String roomId,
  ) {
    return state.personalBests[roomId];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 10. Multi-Room Secrets
  // ═══════════════════════════════════════════════════════════════════════════

  /// All multi-room secret definitions in config order.
  List<MultiRoomSecret> get multiRoomSecrets =>
      List.unmodifiable(_multiRoomSecretDefs);

  /// Returns a new [PostCoreState] where the clue identified by [clueId]
  /// within the secret identified by [secretId] is marked as discovered.
  ///
  /// If the secret or clue is not found, or is already discovered, the
  /// state is returned unchanged.
  PostCoreState discoverClue(
    PostCoreState state,
    String secretId,
    String clueId,
  ) {
    final secretIndex = state.multiRoomSecrets.indexWhere(
      (s) => s.id == secretId,
    );

    // If the secret isn't in state yet, initialise from definitions.
    if (secretIndex < 0) {
      final def = _multiRoomSecretDefsById[secretId];
      if (def == null) return state;

      final clueIndex = def.clues.indexWhere((c) => c.id == clueId);
      if (clueIndex < 0) return state;
      if (def.clues[clueIndex].discovered) return state;

      final updatedClues = List<MultiRoomSecretClue>.of(def.clues);
      updatedClues[clueIndex] =
          updatedClues[clueIndex].copyWith(discovered: true);
      final updatedSecret = def.copyWith(clues: updatedClues);

      return state.copyWith(
        multiRoomSecrets: [...state.multiRoomSecrets, updatedSecret],
      );
    }

    final secret = state.multiRoomSecrets[secretIndex];
    final clueIndex = secret.clues.indexWhere((c) => c.id == clueId);
    if (clueIndex < 0) return state;
    if (secret.clues[clueIndex].discovered) return state;

    final updatedClues = List<MultiRoomSecretClue>.of(secret.clues);
    updatedClues[clueIndex] =
        updatedClues[clueIndex].copyWith(discovered: true);
    final updatedSecret = secret.copyWith(clues: updatedClues);

    final updatedSecrets =
        List<MultiRoomSecret>.of(state.multiRoomSecrets);
    updatedSecrets[secretIndex] = updatedSecret;
    return state.copyWith(multiRoomSecrets: updatedSecrets);
  }

  /// Whether all clues for the secret identified by [secretId] have been
  /// discovered (making the secret solvable).
  ///
  /// Returns `false` when the secret is unknown or has no clues.
  bool isSecretSolvable(PostCoreState state, String secretId) {
    // Check state first (may have partially discovered clues).
    final stateSecret = state.multiRoomSecrets.where(
      (s) => s.id == secretId,
    );
    if (stateSecret.isNotEmpty) {
      final secret = stateSecret.first;
      return secret.clues.isNotEmpty &&
          secret.clues.every((c) => c.discovered);
    }
    // Fall back to definition (nothing discovered yet).
    final def = _multiRoomSecretDefsById[secretId];
    if (def == null) return false;
    return def.clues.isNotEmpty && def.clues.every((c) => c.discovered);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 11. Mastery Contracts
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns mastery-contract definitions for the given [roomId].
  List<MasteryContract> contractsForRoom(String roomId) {
    return _contractsByRoom[roomId] ?? const [];
  }

  /// Returns a new [PostCoreState] with the contract identified by
  /// [contractId] updated to [newValue].
  ///
  /// If [newValue] meets or exceeds the contract's target the contract is
  /// moved from [PostCoreState.activeContracts] to
  /// [PostCoreState.completedContracts].  If the contract is not found in
  /// active contracts the state is returned unchanged.
  PostCoreState updateContractProgress(
    PostCoreState state,
    String contractId,
    int newValue,
  ) {
    final index = state.activeContracts.indexWhere(
      (c) => c.id == contractId,
    );
    if (index < 0) return state;

    final contract = state.activeContracts[index];
    final updated = contract.copyWith(
      currentValue: newValue,
      completed: newValue >= contract.targetValue,
    );

    final newActive = List<MasteryContract>.of(state.activeContracts)
      ..removeAt(index);

    if (updated.completed) {
      return state.copyWith(
        activeContracts: newActive,
        completedContracts: [...state.completedContracts, updated],
      );
    }
    newActive.insert(index, updated);
    return state.copyWith(activeContracts: newActive);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 12. Room Summary
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generates a [RoomSummaryReport] for [roomId] by aggregating mastery,
  /// consequence, revisit, and personal-best data from [state].
  RoomSummaryReport generateSummary(String roomId, PostCoreState state) {
    final items = <RoomSummaryItem>[];
    var totalSecrets = 0;
    var masteryStars = 0;

    // Mastery profile.
    final profile = state.roomMastery[roomId];
    if (profile != null) {
      masteryStars = profile.starsEarned;
      for (final goal in profile.goals) {
        if (goal.completed) {
          items.add(RoomSummaryItem(
            category: 'mastery',
            description: goal.title,
            relatedId: goal.id,
          ));
        }
      }
    }

    // Pending consequences targeting this room.
    for (final c in pendingForRoom(state, roomId)) {
      items.add(RoomSummaryItem(
        category: 'consequence',
        description: c.description,
        relatedId: c.id,
      ));
    }

    // Revisit unlocks.
    final unlocks = state.revisitUnlocks[roomId] ?? const [];
    for (final u in unlocks) {
      if (u.unlocked) {
        items.add(RoomSummaryItem(
          category: 'revisit',
          description: u.title,
          relatedId: u.id,
        ));
        totalSecrets++;
      }
    }

    // Personal best.
    final best = state.personalBests[roomId];
    if (best != null) {
      items.add(RoomSummaryItem(
        category: 'personalBest',
        description:
            'Pace: ${best.bestPaceSeconds}s, Combo: ${best.bestCombo}',
        relatedId: roomId,
      ));
    }

    return RoomSummaryReport(
      roomId: roomId,
      generatedAt: DateTime.now(),
      items: items,
      totalNewEntries: items.length,
      totalNewSecrets: totalSecrets,
      masteryStarsGained: masteryStars,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 13. Cosmetic Rewards
  // ═══════════════════════════════════════════════════════════════════════════

  /// All cosmetic-reward definitions in config order.
  List<CosmeticReward> get allCosmetics =>
      List.unmodifiable(_cosmeticRewardDefs);

  /// Returns a new [PostCoreState] with the cosmetic reward identified by
  /// [cosmeticId] marked as unlocked.
  ///
  /// If the cosmetic is already present and unlocked in [state], or if no
  /// definition exists for [cosmeticId], the state is returned unchanged.
  PostCoreState unlockCosmetic(PostCoreState state, String cosmeticId) {
    final def = _cosmeticRewardsById[cosmeticId];
    if (def == null) return state;

    // Check if already unlocked in state.
    final existingIndex = state.cosmeticRewards.indexWhere(
      (c) => c.id == cosmeticId,
    );
    if (existingIndex >= 0 && state.cosmeticRewards[existingIndex].unlocked) {
      return state;
    }

    final unlocked = def.copyWith(unlocked: true);

    if (existingIndex >= 0) {
      final updated = List<CosmeticReward>.of(state.cosmeticRewards);
      updated[existingIndex] = unlocked;
      return state.copyWith(cosmeticRewards: updated);
    }
    return state.copyWith(
      cosmeticRewards: [...state.cosmeticRewards, unlocked],
    );
  }
}
