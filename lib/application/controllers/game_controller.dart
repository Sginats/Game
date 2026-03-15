import 'dart:math' as math;

import '../../core/math/game_number.dart';
import '../../core/time/time_provider.dart';
import '../../data/repositories/game_repository.dart';
import '../../domain/mechanics/cost_calculator.dart';
import '../../domain/mechanics/offline_progression.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/codex.dart';
import '../../domain/models/era.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/gameplay_extensions.dart';
import '../../domain/models/meta_progression.dart';
import '../../domain/models/progression_content.dart';
import '../../domain/models/generator.dart';
import '../../domain/models/room_scene.dart';
import '../../domain/models/scene_event.dart';
import '../../domain/models/upgrade.dart';
import '../../domain/systems/achievement_system.dart';
import '../../domain/systems/generator_system.dart';
import '../../domain/systems/prestige_system.dart';
import '../../domain/systems/tap_system.dart';
import '../../domain/systems/upgrade_system.dart';
import '../services/config_service.dart';
import '../services/room_scene_service.dart';

/// Main game controller that orchestrates all game logic.
/// Pure Dart — no Flutter imports.
class GameController {
  static const bool _eventsEnabled = true;

  /// Tap multiplier bonus applied to Room 01 each time an environment-trigger
  /// event fires.  Matches the SALVAGE MODE room law's rhythm bonus.
  static const double _room01EnvTapBonus = 1.02;

  final ConfigService _config;
  final TimeProvider _timeProvider;
  final GameRepository? _repository;
  final RoomSceneService? _roomSceneService;
  final math.Random _random;
  GameState _state;
  double _autoSaveAccumulator = 0;
  double _eventAccumulator = 0;
  Future<void>? _saveFuture;
  SceneEventDefinition? _activeRoomSceneEvent;

  /// Monotonically increasing counter incremented on every state mutation that
  /// affects the tech tree (purchases, upgrades, era changes, room changes).
  /// The UI can compare this cheaply instead of hashing the full state map.
  int _stateVersion = 0;

  /// Room-state version counter. Incremented on room-specific state changes
  /// (transformation stage advance, room completion, twist activation, secret
  /// discovery) independently of tree mutations, so UI surfaces that only
  /// display room state can avoid unnecessary tree rebuilds.
  int _roomVersion = 0;

  List<AchievementDefinition> lastUnlockedAchievements = [];
  List<String> lastUnlockedMilestones = [];
  GameNumber? pendingOfflineEarnings;
  ReturnSummary? pendingReturnSummary;
  GameNumber lastTapGain = const GameNumber.zero();
  bool lastTapWasCritical = false;
  String? lastRecommendation;
  String? lastAiLine;

  /// Human-readable summary of the most recent event resolution reward
  /// (e.g. "+1 234 coins", "Transformation boosted", "Secret clue advanced").
  /// Set after a successful [resolveActiveEvent] and cleared on next event
  /// spawn.  UI can display this after the event card disappears.
  String? lastEventRewardSummary;

  /// Set to true when the very first tap happens — cleared after being read.
  bool firstTapJustHappened = false;

  /// Set to true when the very first upgrade is purchased — cleared after being read.
  bool firstUpgradeJustPurchased = false;

  /// Set to true when the very first room scene event spawns — cleared after being read.
  bool firstEventJustSpawned = false;

  GameController({
    required ConfigService config,
    required TimeProvider timeProvider,
    GameState? initialState,
    GameRepository? repository,
    RoomSceneService? roomSceneService,
    math.Random? random,
  })  : _config = config,
        _timeProvider = timeProvider,
        _repository = repository,
        _roomSceneService = roomSceneService,
        _random = random ?? math.Random(),
        _state = initialState ?? GameState.initial() {
    _syncRoomToCurrentEra(force: true);
    _bootstrapRoomCollections();
    _checkEraUnlocks();
    _checkSceneBadges();
    _checkRoomProgression();
    _ensureQuest();
    _ensureChallenges();
    _syncGuideMilestones();
    _refreshGuidance();
  }

  GameState get state => _state;
  ConfigService get config => _config;

  /// Monotonically increasing version counter. Incremented on every mutation
  /// that affects the tech tree (purchases, era changes, room changes). Used by
  /// the UI instead of the expensive O(n) state hash.
  int get stateVersion => _stateVersion;

  /// Room-state version counter. Incremented on room-specific changes
  /// (transformation advance, room completion, twist, secret discovery).
  /// Lets room-state UI surfaces rebuild independently of tree refreshes.
  int get roomVersion => _roomVersion;

  String get currentEraId => _currentEraId;
  Set<String> get loadedEraWindow {
    final ids = <String>{..._ownedEraIds, _currentEraId};
    final current = _eraById(_currentEraId);
    if (current != null) {
      for (final era in _config.eras) {
        if ((era.order - current.order).abs() <= 1) {
          ids.add(era.id);
        }
      }
    }
    return ids;
  }
  Map<String, ActiveAbilityState> get abilities => _state.abilities;
  GameEventState? get activeEvent => _state.activeEvent;
  QuestState? get activeQuest => _state.activeQuest;
  List<ChallengeState> get challenges => _state.challenges;
  Set<String> get seenEventTemplates => _state.seenEventTemplates;
  Set<String> get completedSceneBadges => _state.completedSceneBadges;
  double get guideAffinity => _state.guideAffinity;
  int get guideTier => 1 + (_state.guideAffinity ~/ 6).clamp(0, 4);

  /// Guide trust level label based on affinity tiers.
  String get guideTrustLevel {
    final tier = guideTier;
    if (tier >= 5) return 'Bonded';
    if (tier >= 4) return 'Trusted';
    if (tier >= 3) return 'Friendly';
    if (tier >= 2) return 'Familiar';
    return 'Cautious';
  }

  // ─── Room progression accessors ─────────────────────────────────────

  /// Current room ID from the state.
  String get currentRoomId => _state.currentRoomId;

  /// Current room scene data, if the RoomSceneService is available.
  RoomScene? get currentRoom =>
      _roomSceneService?.getRoomById(_state.currentRoomId);

  /// Next room after the current one.
  RoomScene? get nextRoom =>
      _roomSceneService?.getNextRoom(_state.currentRoomId);

  /// Room state for the current room.
  RoomSceneState get currentRoomState =>
      _state.roomStates[_state.currentRoomId] ??
      RoomSceneState(roomId: _state.currentRoomId);

  /// Total rooms completed.
  int get roomsCompleted => _state.metaProgression.roomsCompleted.length;

  /// Total rooms available.
  int get totalRooms => _roomSceneService?.totalRooms ?? 20;
  List<RoomScene> get allRooms => _roomSceneService?.allRooms ?? const [];
  RoomScene? roomForEra(String eraId) {
    final era = _eraById(eraId);
    if (era == null) return null;
    return _roomSceneService?.getRoomByOrder(era.order);
  }

  /// MetaProgression state accessor.
  MetaProgressionState get metaProgression => _state.metaProgression;

  /// Codex state accessor.
  CodexState get codexState => _state.codex;

  /// Transformation stage for the current room (0-based index).
  int get currentTransformationStage =>
      currentRoomState.currentTransformationStage;

  /// Whether the current room's mid-scene twist has activated.
  bool get twistActivated => currentRoomState.twistActivated;
  ChallengeState? get dailyChallenge => _challengeByPeriod(ChallengePeriod.daily);
  ChallengeState? get weeklyChallenge => _challengeByPeriod(ChallengePeriod.weekly);
  NarrativeBeat? get activeNarrativeBeat {
    for (final beat in _state.narrativeQueue) {
      if (!beat.viewed) return beat;
    }
    return null;
  }

  bool get canChooseBranch =>
      _state.unlockedMilestones.contains(_branchingMilestoneId);

  String get dominantPlaystyle {
    if (_state.playstyleTendencies.isEmpty) return 'Balanced';
    final sorted = _state.playstyleTendencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    switch (sorted.first.key) {
      case 'active':
        return 'Active Operator';
      case 'passive':
        return 'Automation Architect';
      case 'risky':
        return 'Risk Runner';
      case 'efficient':
        return 'Optimizer';
      default:
        return 'Balanced';
    }
  }

  GameNumber get productionPerSecond {
    return GeneratorSystem.calculateTotalProduction(
          _config.generators,
          _state.generators,
          _state.productionMultiplier,
        ) *
        _state.prestigeMultiplier *
        _productionBonusMultiplier *
        GameNumber.fromDouble(TapSystem.comboProductionMultiplier(_state.tapCombo));
  }

  // ─── Tap ─────────────────────────────────────────────────────────────

  bool get canTap => tapCooldownProgress >= 1;

  double get tapCooldownSeconds {
    final highestEraOrder = _highestReachedEraOrder;
    var value = TapSystem.baseCooldownMs / 1000.0;
    value -= math.min(0.18, _state.totalUpgradesPurchased * 0.0012);
    value -= math.min(0.08, highestEraOrder * 0.004);
    if (_state.chosenBranches.contains('tap')) value -= 0.05;
    if (_state.unlockedMilestones.contains('combo_master')) value -= 0.03;
    if (_abilityActive(ActiveAbilityType.focus)) value -= 0.16;
    if (_abilityActive(ActiveAbilityType.sync)) value -= 0.05;
    return value.clamp(0.12, TapSystem.baseCooldownMs / 1000.0);
  }

  double get tapCooldownProgress {
    final lastTapTime = _state.lastTapTime;
    if (lastTapTime == null) return 1;
    final elapsed =
        _timeProvider.now().difference(lastTapTime).inMilliseconds / 1000.0;
    return (elapsed / tapCooldownSeconds).clamp(0, 1);
  }

  double get tapCooldownRemainingSeconds =>
      tapCooldownSeconds * (1 - tapCooldownProgress);

  bool tap() {
    if (!canTap) return false;
    final before = _state.coins;
    final isFirstTap = _state.totalTaps == 0;
    var tapped = TapSystem.processTap(
      _state,
      _config.baseTapValue,
      now: _timeProvider.now(),
    );
    var gain = tapped.coins - before;

    if (isFirstTap) firstTapJustHappened = true;

    final tapBonus = _tapBonusMultiplier.toDouble();
    if (tapBonus > 1) {
      final boostedGain =
          gain * GameNumber.fromDouble(tapBonus);
      final bonus = boostedGain - gain;
      tapped = tapped.copyWith(
        coins: tapped.coins + bonus,
        totalCoinsEarned: tapped.totalCoinsEarned + bonus,
      );
      gain = boostedGain;
    }

    lastTapWasCritical = _random.nextDouble() < _criticalChance;
    if (lastTapWasCritical) {
      final critBonus = gain * GameNumber.fromDouble(_criticalMultiplier - 1);
      tapped = tapped.copyWith(
        coins: tapped.coins + critBonus,
        totalCoinsEarned: tapped.totalCoinsEarned + critBonus,
        totalCriticalClicks: tapped.totalCriticalClicks + 1,
      );
      gain = gain + critBonus;
    }

    tapped = tapped.copyWith(
      strongestCombo: math.max(tapped.strongestCombo, tapped.tapCombo),
      automationCharge:
          (tapped.automationCharge + (lastTapWasCritical ? 6 : 2)).clamp(0, 100),
      playstyleTendencies: _bumpTendency(
        tapped.playstyleTendencies,
        'active',
        1.2,
      ),
    );

    if (_abilityActive(ActiveAbilityType.sync)) {
      final syncBonus = gain * GameNumber.fromDouble(0.18);
      tapped = tapped.copyWith(
        coins: tapped.coins + syncBonus,
        totalCoinsEarned: tapped.totalCoinsEarned + syncBonus,
      );
      gain = gain + syncBonus;
    }

    _state = tapped;
    lastTapGain = gain;
    _updateQuestProgress();
    _checkEraUnlocks();
    _checkSceneBadges();
    _checkSecrets();
    _checkMilestones();
    _checkAchievements();
    _refreshGuidance();
    return true;
  }

  // ─── Purchases ───────────────────────────────────────────────────────

  bool purchaseGenerator(String generatorId, {int quantity = 1}) {
    if (quantity <= 0) return false;
    final definition = _config.generators[generatorId];
    if (definition == null) return false;

    final currentLevel = _state.generators[generatorId]?.level ?? 0;
    final totalCost = CostCalculator.calculateTotalCost(
      definition.baseCost,
      definition.costGrowthRate,
      currentLevel,
      quantity,
    );

    final newState =
        GeneratorSystem.purchaseGenerator(_state, definition, quantity);
    if (identical(newState, _state)) return false;

    final refund = totalCost *
        GameNumber.fromDouble((_state.purchaseMomentum * 0.01).clamp(0.0, 0.12));

    _state = newState.copyWith(
      coins: newState.coins + refund,
      totalGeneratorsPurchased:
          newState.totalGeneratorsPurchased + quantity,
      purchaseMomentum: (newState.purchaseMomentum + 1.4).clamp(0, 12),
      playstyleTendencies: _bumpTendency(
        newState.playstyleTendencies,
        'passive',
        quantity * 0.3,
      ),
      automationCharge:
          (newState.automationCharge + quantity * 1.2).clamp(0, 100),
    );

    _updateQuestProgress();
    _checkEraUnlocks();
    _checkSceneBadges();
    _checkMilestones();
    _checkAchievements();
    _refreshGuidance();
    _stateVersion++;
    return true;
  }

  bool purchaseUpgrade(String upgradeId, {int quantity = 1}) {
    if (quantity <= 0) return false;
    final definition = _config.upgrades[upgradeId];
    if (definition == null) return false;

    final isFirstUpgrade = _state.totalUpgradesPurchased == 0;
    final currentLevel = _state.upgrades[upgradeId]?.level ?? 0;
    final remainingLevels = math.max(0, definition.maxLevel - currentLevel);
    final targetQuantity = math.min(quantity, remainingLevels);
    if (targetQuantity <= 0) return false;

    final cost = CostCalculator.calculateTotalCost(
      definition.baseCost,
      definition.costGrowthRate,
      currentLevel,
      targetQuantity,
    );

    final newState = UpgradeSystem.purchaseUpgrade(
      _state,
      definition,
      quantity: targetQuantity,
    );
    if (identical(newState, _state)) return false;

    final levelsBought =
        (newState.upgrades[upgradeId]?.level ?? currentLevel) - currentLevel;
    if (levelsBought <= 0) return false;

    final refund = cost *
        GameNumber.fromDouble((_state.purchaseMomentum * 0.01).clamp(0.0, 0.1));
    var updated = newState.copyWith(
      coins: newState.coins + refund,
      totalUpgradesPurchased: newState.totalUpgradesPurchased + levelsBought,
      purchaseMomentum:
          (newState.purchaseMomentum + (levelsBought * 1.0)).clamp(0, 12),
      playstyleTendencies: _bumpTendency(
        newState.playstyleTendencies,
        'efficient',
        0.75 * levelsBought,
      ),
    );

    if (definition.category == UpgradeCategory.ai) {
      updated = updated.copyWith(
        automationCharge: (updated.automationCharge + 8).clamp(0, 100),
      );
    }

    _state = updated;
    if (isFirstUpgrade) firstUpgradeJustPurchased = true;
    _updateQuestProgress();
    _checkEraUnlocks();
    _checkSceneBadges();
    _checkMilestones();
    _checkAchievements();
    _refreshGuidance();
    _stateVersion++;
    return true;
  }

  bool chooseBranch(String branchId) {
    if (!canChooseBranch) return false;
    final supported = _config.progression.branches.map((item) => item.id).toSet();
    if (!supported.contains(branchId)) return false;
    if (_state.chosenBranches.contains(branchId)) return false;

    final chosen = <String>{branchId};
    _state = _state.copyWith(
      chosenBranches: chosen,
      routeSignature: branchId,
      guideAffinity: _state.guideAffinity + 0.8,
      playstyleTendencies: branchId == 'risky'
          ? _bumpTendency(_state.playstyleTendencies, 'risky', 2)
          : _state.playstyleTendencies,
    );
    _syncRouteArchive(branchId: branchId);
    _syncGuideMilestones();
    _refreshGuidance();
    return true;
  }

  bool respecBranch() {
    if (_state.branchRespecTokens <= 0 || _state.chosenBranches.isEmpty) {
      return false;
    }
    _state = _state.copyWith(
      chosenBranches: const {},
      branchRespecTokens: _state.branchRespecTokens - 1,
      routeSignature: '${_state.routeSignature}|respec',
    );
    _syncRouteArchive();
    _refreshGuidance();
    return true;
  }

  bool setCurrentEra(String eraId) {
    if (!_state.unlockedEras.contains(eraId)) return false;
    if (_state.currentEraId == eraId) return true;
    _state = _state.copyWith(currentEraId: eraId);
    _syncRoomToCurrentEra();
    _refreshGuidance();
    _stateVersion++;
    return true;
  }

  // ─── Room progression ───────────────────────────────────────────────

  /// Transition to a specific room by ID. Returns false if room is locked.
  bool transitionToRoom(String roomId) {
    if (_roomSceneService == null) return false;
    final completedRooms = _state.metaProgression.roomsCompleted;
    if (!_roomSceneService!.isRoomUnlocked(roomId, completedRooms)) {
      return false;
    }
    final room = _roomSceneService!.getRoomById(roomId);
    if (room == null) return false;

    // Initialize room state if not already tracked
    final roomStates = Map<String, RoomSceneState>.from(_state.roomStates);
    if (!roomStates.containsKey(roomId)) {
      roomStates[roomId] = RoomSceneState(roomId: roomId);
    }

    _state = _state.copyWith(
      currentRoomId: roomId,
      currentEraId: _eraIdForRoom(room) ?? _state.currentEraId,
      roomStates: roomStates,
      guideAffinity: _state.guideAffinity + 0.3,
    );

    _syncRouteArchive();
    recordGuideMemory(
      id: 'guide_room_intro_$roomId',
      title: room.name,
      content: room.guideIntroLine,
      messageType: 'room_intro',
    );
    _pushNarrativeBeat(
      id: 'room_enter_$roomId',
      title: 'Entering ${room.name}',
      body: room.introText,
    );
    _refreshGuidance();
    _stateVersion++;
    return true;
  }

  /// Mark the current room as completed and award meta-progression.
  bool completeCurrentRoom() {
    final roomId = _state.currentRoomId;
    final roomState = currentRoomState;
    if (roomState.completed) return false;

    final updatedRoomStates =
        Map<String, RoomSceneState>.from(_state.roomStates);
    updatedRoomStates[roomId] = roomState.copyWith(completed: true);

    final meta = _state.metaProgression;
    var updatedMeta = meta.copyWith(
      roomsCompleted: {...meta.roomsCompleted, roomId},
      totalPrestigeTokens: meta.totalPrestigeTokens + 1,
      lifetimePrestigeTokens: meta.lifetimePrestigeTokens + 1,
    );

    final room = _roomSceneService?.getRoomById(roomId);

    // Add scene lore entry to codex
    final codex = _state.codex;
    var updatedCodex = codex.copyWith(
      sceneLore: [
        ...codex.sceneLore,
        SceneLoreEntry(
          id: 'lore_complete_$roomId',
          roomId: roomId,
          title: '${room?.name ?? roomId} Mastered',
          content: room?.completionText ?? 'Room completed.',
          loreCategory: 'completion',
          chapter: updatedMeta.roomsCompleted.length,
          discovered: true,
        ),
      ],
    );

    if (room != null) {
      updatedMeta = _awardRoomCompletionMeta(room, updatedMeta);
      updatedCodex = _recordRoomCompletionArchives(room, updatedCodex);
    }

    _state = _state.copyWith(
      roomStates: updatedRoomStates,
      metaProgression: updatedMeta,
      codex: updatedCodex,
      guideAffinity: _state.guideAffinity + 2.0,
    );

    if (room != null) {
      recordGuideMemory(
        id: 'guide_room_complete_$roomId',
        title: '${room.name} Complete',
        content:
            'You stabilized ${room.name} and archived its lessons for the next run.',
        messageType: 'room_complete',
      );
    }
    _syncRouteArchive(completedRoomId: roomId);
    _syncGuideMilestones();
    _pushNarrativeBeat(
      id: 'room_complete_$roomId',
      title: '${room?.name ?? roomId} Complete',
      body: room?.completionText ??
          'The room has been mastered. New possibilities open ahead.',
    );
    _checkRoomProgression();
    _refreshGuidance();
    _roomVersion++;
    return true;
  }

  /// Advance the transformation stage for the current room.
  bool advanceTransformationStage() {
    final roomId = _state.currentRoomId;
    final roomState = currentRoomState;
    final room = _roomSceneService?.getRoomById(roomId);
    if (room == null) return false;

    final nextStage = roomState.currentTransformationStage + 1;
    if (nextStage >= room.transformationStages.length) return false;

    final stageData = room.transformationStages[nextStage];
    if (roomState.upgradesPurchased < stageData.requiredUpgrades) {
      return false;
    }

    final updatedRoomStates =
        Map<String, RoomSceneState>.from(_state.roomStates);
    updatedRoomStates[roomId] = roomState.copyWith(
      currentTransformationStage: nextStage,
    );

    _state = _state.copyWith(
      roomStates: updatedRoomStates,
      guideAffinity: _state.guideAffinity + 0.5,
    );

    _recordTransformationArchive(room, stageData, nextStage);
    _pushNarrativeBeat(
      id: 'transform_${roomId}_$nextStage',
      title: stageData.name,
      body:
          '${stageData.description}\n${stageData.environmentChanges.join(', ')}',
    );
    _syncGuideMilestones();
    _refreshGuidance();
    _roomVersion++;
    return true;
  }

  /// Discover a secret in the current room.
  bool discoverRoomSecret(String secretId) {
    final roomId = _state.currentRoomId;
    final roomState = currentRoomState;
    if (roomState.secretsDiscovered.contains(secretId)) return false;

    final updatedRoomStates =
        Map<String, RoomSceneState>.from(_state.roomStates);
    updatedRoomStates[roomId] = roomState.copyWith(
      secretsDiscovered: {...roomState.secretsDiscovered, secretId},
    );

    final meta = _state.metaProgression;
    var updatedMeta = meta.copyWith(
      secretsArchived: {...meta.secretsArchived, secretId},
    );

    final codex = _state.codex;
    final existingSecretIndex =
        codex.secretArchive.indexWhere((entry) => entry.id == secretId);
    final updatedSecretArchive = List<SecretArchiveEntry>.from(codex.secretArchive);
    if (existingSecretIndex >= 0) {
      final existing = updatedSecretArchive[existingSecretIndex];
      updatedSecretArchive[existingSecretIndex] = SecretArchiveEntry(
        id: existing.id,
        roomId: existing.roomId,
        title: existing.title,
        description: existing.description,
        hint: existing.hint,
        clueSource: existing.clueSource,
        discoveryMethod: existing.discoveryMethod,
        rewardDescription: existing.rewardDescription,
        discovered: true,
      );
    } else {
      updatedSecretArchive.add(
        SecretArchiveEntry(
          id: secretId,
          roomId: roomId,
          title: 'Secret: $secretId',
          description: 'A hidden discovery in $roomId.',
          discovered: true,
        ),
      );
    }
    var updatedCodex = codex.copyWith(secretArchive: updatedSecretArchive);
    final room = _roomSceneService?.getRoomById(roomId);
    RoomSecret? secret;
    if (room != null) {
      for (final item in room.secrets) {
        if (item.id == secretId) {
          secret = item;
          break;
        }
      }
    }
    if (room != null && secret != null) {
      updatedMeta = _awardSecretMeta(room, secret, updatedMeta);
      updatedCodex = _recordSecretRewardArchive(room, secret, updatedCodex);
    }

    _state = _state.copyWith(
      roomStates: updatedRoomStates,
      metaProgression: updatedMeta,
      codex: updatedCodex,
      discoveredSecrets: {..._state.discoveredSecrets, secretId},
      guideAffinity: _state.guideAffinity + 1.0,
    );
    _syncGuideMilestones();
    _refreshGuidance();
    _roomVersion++;
    return true;
  }

  /// Activate the mid-scene twist for the current room.
  bool activateRoomTwist() {
    final roomId = _state.currentRoomId;
    final roomState = currentRoomState;
    if (roomState.twistActivated) return false;

    final room = _roomSceneService?.getRoomById(roomId);
    if (room?.midSceneTwist == null) return false;

    final updatedRoomStates =
        Map<String, RoomSceneState>.from(_state.roomStates);
    updatedRoomStates[roomId] = roomState.copyWith(twistActivated: true);

    _state = _state.copyWith(
      roomStates: updatedRoomStates,
      guideAffinity: _state.guideAffinity + 0.8,
    );

    _recordTwistArchive(room!);
    recordGuideMemory(
      id: 'guide_room_twist_$roomId',
      title: room.midSceneTwist!.title,
      content: room.midSceneTwist!.effectDescription,
      messageType: 'room_twist',
    );
    _pushNarrativeBeat(
      id: 'twist_$roomId',
      title: room.midSceneTwist!.title,
      body: room.midSceneTwist!.effectDescription,
    );
    _syncGuideMilestones();
    _refreshGuidance();
    _roomVersion++;
    return true;
  }

  /// Record a guide memory entry to the codex.
  void recordGuideMemory({
    required String id,
    required String title,
    required String content,
    String messageType = 'general',
  }) {
    final codex = _state.codex;
    // Avoid duplicates
    if (codex.guideMemories.any((m) => m.id == id)) return;
    final updatedCodex = codex.copyWith(
      guideMemories: [
        ...codex.guideMemories,
        GuideMemoryLog(
          id: id,
          roomId: _state.currentRoomId,
          title: title,
          content: content,
          timestamp: _timeProvider.now(),
          guideAffinity: _state.guideAffinity,
          messageType: messageType,
        ),
      ],
    );
    _state = _state.copyWith(codex: updatedCodex);
  }

  bool applyLoadoutPreset(String presetId) {
    LoadoutPreset? preset;
    for (final item in _state.loadoutPresets) {
      if (item.id == presetId) {
        preset = item;
        break;
      }
    }
    if (preset == null || preset.preferredBranches.isEmpty) return false;
    _state = _state.copyWith(
      chosenBranches: preset.preferredBranches,
      routeSignature: preset.preferredBranches.join('+'),
    );
    _refreshGuidance();
    return true;
  }

  bool saveLoadoutPreset({
    String? presetId,
    required String name,
    required Set<String> preferredBranches,
    bool favorite = false,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || preferredBranches.isEmpty) return false;
    final validBranches = _config.progression.branches.map((item) => item.id).toSet();
    if (!preferredBranches.every(validBranches.contains)) return false;

    final presets = [..._state.loadoutPresets];
    final id = presetId ?? _createPresetId(trimmedName);
    final index = presets.indexWhere((item) => item.id == id);
    final preset = LoadoutPreset(
      id: id,
      name: trimmedName,
      preferredBranches: preferredBranches,
      favorite: favorite,
    );
    if (index >= 0) {
      presets[index] = preset;
    } else {
      presets.add(preset);
    }
    _state = _state.copyWith(loadoutPresets: presets);
    return true;
  }

  bool deleteLoadoutPreset(String presetId) {
    final presets =
        _state.loadoutPresets.where((item) => item.id != presetId).toList();
    if (presets.length == _state.loadoutPresets.length) return false;
    _state = _state.copyWith(loadoutPresets: presets);
    return true;
  }

  bool toggleLoadoutFavorite(String presetId) {
    var changed = false;
    final presets = _state.loadoutPresets.map((item) {
      if (item.id != presetId) return item;
      changed = true;
      return item.copyWith(favorite: !item.favorite);
    }).toList();
    if (!changed) return false;
    _state = _state.copyWith(loadoutPresets: presets);
    return true;
  }

  int purchaseAllInEra(String eraId) {
    var totalBought = 0;
    var progressed = true;
    var guard = 0;
    while (progressed && guard < 256) {
      progressed = false;
      guard++;

      final generators = _config.generators.values
          .where((item) => item.eraId == eraId)
          .toList()
        ..sort((a, b) => a.baseCost.toDouble().compareTo(b.baseCost.toDouble()));
      for (final generator in generators) {
        final currentLevel = _state.generators[generator.id]?.level ?? 0;
        final affordable = CostCalculator.maxAffordable(
          generator.baseCost,
          generator.costGrowthRate,
          currentLevel,
          _state.coins,
        );
        if (affordable <= 0) continue;
        final quantity = affordable.clamp(1, 9999);
        final before = _state.generators[generator.id]?.level ?? 0;
        if (purchaseGenerator(generator.id, quantity: quantity)) {
          final after = _state.generators[generator.id]?.level ?? before;
          totalBought += math.max(0, after - before);
          progressed = true;
        }
      }

      final upgrades = _config.upgrades.values
          .where((item) => item.eraId == eraId)
          .toList()
        ..sort((a, b) => a.baseCost.toDouble().compareTo(b.baseCost.toDouble()));
      for (final upgrade in upgrades) {
        final before = _state.upgrades[upgrade.id]?.level ?? 0;
        final remaining = math.max(0, upgrade.maxLevel - before);
        if (remaining <= 0) continue;
        final affordable = CostCalculator.maxAffordable(
          upgrade.baseCost,
          upgrade.costGrowthRate,
          before,
          _state.coins,
        );
        if (affordable <= 0) continue;
        final quantity = affordable.clamp(1, remaining);
        if (purchaseUpgrade(upgrade.id, quantity: quantity)) {
          final after = _state.upgrades[upgrade.id]?.level ?? before;
          totalBought += math.max(0, after - before);
          progressed = true;
        }
      }
    }
    return totalBought;
  }

  bool rerollChallenge(ChallengePeriod period) {
    if (_state.challengeRerollsRemaining <= 0) return false;
    final updated = _state.challenges.map((challenge) {
      if (challenge.period != period) return challenge;
      return _generateChallenge(
        period,
        seasonKey: _challengeSeasonKey(period),
        rerollsUsed: challenge.rerollsUsed + 1,
      );
    }).toList();
    _state = _state.copyWith(
      challenges: updated,
      challengeRerollsRemaining: _state.challengeRerollsRemaining - 1,
    );
    _updateChallengeProgress();
    _refreshGuidance();
    return true;
  }

  bool claimChallengeReward(String challengeId) {
    ChallengeState? challenge;
    for (final item in _state.challenges) {
      if (item.id == challengeId) {
        challenge = item;
        break;
      }
    }
    if (challenge == null || !challenge.completed || challenge.claimed) {
      return false;
    }
    final rewardTemplate = _config.challengeTemplateById(challengeId);
    final rewardBase =
        (challenge.period == ChallengePeriod.daily ? 0.08 : 0.22) *
            (rewardTemplate?.rewardMultiplier ?? 1);
    final reward = GameNumber.fromDouble(
      math.max(500, _state.totalCoinsEarned.toDouble() * rewardBase),
    );
    var updatedMeta = _state.metaProgression.copyWith(
      challengesCleared: _state.metaProgression.challengesCleared + 1,
    );
    var updatedCodex = _state.codex;
    if (challenge.period == ChallengePeriod.weekly) {
      updatedMeta = _awardChallengeBlueprint(challenge, updatedMeta);
    }
    updatedCodex = _recordChallengeArchive(challenge, updatedCodex);
    _state = _state.copyWith(
      coins: _state.coins + reward,
      totalCoinsEarned: _state.totalCoinsEarned + reward,
      guideAffinity: _state.guideAffinity + 1.2,
      metaProgression: updatedMeta,
      codex: updatedCodex,
      challenges: _state.challenges
          .map((item) =>
              item.id == challengeId ? item.copyWith(claimed: true) : item)
          .toList(),
    );
    if (challenge.period == ChallengePeriod.weekly) {
      _pushNarrativeForTrigger(
        triggerKey: 'challenge.weekly_complete',
        fallbackId: 'weekly_${challenge.id}',
        fallbackTitle: 'Weekly Pattern Complete',
        fallbackBody:
            'The AI recorded a durable strategy from your weekly challenge run.',
      );
    }
    recordGuideMemory(
      id: 'guide_challenge_$challengeId',
      title: challenge.title,
      content:
          'Challenge archived with ${challenge.progress.toStringAsFixed(0)} progress toward ${challenge.target.toStringAsFixed(0)}.',
      messageType: 'challenge',
    );
    _syncGuideMilestones();
    _refreshGuidance();
    return true;
  }

  bool dismissNarrativeBeat(String beatId) {
    if (_state.narrativeQueue.every((item) => item.id != beatId)) {
      return false;
    }
    _state = _state.copyWith(
      narrativeQueue: _state.narrativeQueue
          .map((item) => item.id == beatId ? item.copyWith(viewed: true) : item)
          .toList(),
    );
    return true;
  }

  // ─── Abilities / events / quests ────────────────────────────────────

  bool activateAbility(ActiveAbilityType type) {
    final ability = _state.abilities[type.name];
    if (ability == null || !ability.isReady) return false;

    final updatedAbilities = Map<String, ActiveAbilityState>.from(_state.abilities);
    switch (type) {
      case ActiveAbilityType.overclock:
        updatedAbilities[type.name] = ability.copyWith(
          activeRemaining: 10,
          cooldownRemaining: math.max(24, 42 - guideTier * 2),
        );
        break;
      case ActiveAbilityType.focus:
        updatedAbilities[type.name] = ability.copyWith(
          activeRemaining: 9,
          cooldownRemaining: math.max(18, 28 - guideTier * 1.5),
        );
        break;
      case ActiveAbilityType.surge:
        updatedAbilities[type.name] = ability.copyWith(
          activeRemaining: 0,
          cooldownRemaining: math.max(32, 55 - guideTier * 2),
        );
        final surgeReward = GameNumber.fromDouble(
          math.max(25, productionPerSecond.toDouble() * (5 + guideTier * 0.25)),
        );
        _state = _state.copyWith(
          coins: _state.coins + surgeReward,
          totalCoinsEarned: _state.totalCoinsEarned + surgeReward,
        );
        break;
      case ActiveAbilityType.sync:
        updatedAbilities[type.name] = ability.copyWith(
          activeRemaining: 12,
          cooldownRemaining: math.max(36, 60 - guideTier * 2),
        );
        break;
    }

    _state = _state.copyWith(abilities: updatedAbilities);
    _refreshGuidance();
    return true;
  }

  bool resolveActiveEvent({required bool aggressiveChoice}) {
    final event = _state.activeEvent;
    if (event == null) return false;
    if (_activeRoomSceneEvent != null) {
      final resolved = _resolveRoomSceneEvent(
        _activeRoomSceneEvent!,
        event,
        aggressiveChoice: aggressiveChoice,
      );
      _activeRoomSceneEvent = null;
      return resolved;
    }

    var updated = _state;
    final rewardScale =
        (aggressiveChoice && _state.chosenBranches.contains('risky')
                ? 1.7
                : aggressiveChoice
                    ? 1.3
                    : 1.0) *
            _rarityRewardMultiplier(event.rarity) *
            (1 + (_state.currentEventChain * 0.05).clamp(0, 0.45));

    switch (event.type) {
      case GameEventType.powerSurge:
        final pulseReward = GameNumber.fromDouble(
          math.max(
            10,
            productionPerSecond.toDouble() * 4 * rewardScale,
          ),
        );
        updated = updated.copyWith(
          coins: updated.coins + pulseReward,
          totalCoinsEarned: updated.totalCoinsEarned + pulseReward,
        );
        break;
      case GameEventType.aiIdea:
        updated = updated.copyWith(
          tapMultiplier: updated.tapMultiplier *
              GameNumber.fromDouble(aggressiveChoice ? 1.03 : 1.015),
          abilities: updated.abilities.map(
            (key, value) => MapEntry(
              key,
              value.copyWith(
                cooldownRemaining:
                    math.max(0, value.cooldownRemaining - (aggressiveChoice ? 4 : 2)),
              ),
            ),
          ),
        );
        break;
      case GameEventType.hardwareMalfunction:
        updated = updated.copyWith(
          automationCharge: aggressiveChoice
              ? (updated.automationCharge + 8).clamp(0, 100)
              : (updated.automationCharge + 3).clamp(0, 100),
          activeMutators: aggressiveChoice
              ? [
                  ...updated.activeMutators.where(
                    (item) => item.type != MutatorType.overheating,
                  ),
                  const GameplayMutatorState(
                    type: MutatorType.overheating,
                    title: 'Overheating',
                    description:
                        'Manual and automation output spike together, but pacing grows harsher.',
                    remainingSeconds: 32,
                  ),
                ]
              : updated.activeMutators,
        );
        break;
      case GameEventType.marketSpike:
        final spikeReward = GameNumber.fromDouble(
          math.max(20, productionPerSecond.toDouble() * 6 * rewardScale),
        );
        updated = updated.copyWith(
          coins: updated.coins + spikeReward,
          totalCoinsEarned: updated.totalCoinsEarned + spikeReward,
        );
        break;
      case GameEventType.mysteryCache:
        updated = updated.copyWith(
          discoveredSecrets: {
            ...updated.discoveredSecrets,
            if (aggressiveChoice) 'cache_echo',
          },
          coins: updated.coins +
              GameNumber.fromDouble(aggressiveChoice ? 120 : 45),
          totalCoinsEarned: updated.totalCoinsEarned +
              GameNumber.fromDouble(aggressiveChoice ? 120 : 45),
        );
        break;
      case GameEventType.breachFragment:
        final breachReward = GameNumber.fromDouble(
          math.max(35, productionPerSecond.toDouble() * 8 * rewardScale),
        );
        updated = updated.copyWith(
          coins: updated.coins + breachReward,
          totalCoinsEarned: updated.totalCoinsEarned + breachReward,
          discoveredSecrets: {
            ...updated.discoveredSecrets,
            if (aggressiveChoice) 'breach_echo',
          },
        );
        break;
      case GameEventType.dataCorruption:
        if (aggressiveChoice) {
          updated = updated.copyWith(
            productionMultiplier: updated.productionMultiplier *
                GameNumber.fromDouble(1.018),
            activeMutators: [
              ...updated.activeMutators.where(
                (item) => item.type != MutatorType.unstableEconomy,
              ),
              const GameplayMutatorState(
                type: MutatorType.unstableEconomy,
                title: 'Unstable Economy',
                description:
                    'Production is volatile, but chain rewards climb faster.',
                remainingSeconds: 40,
              ),
            ],
          );
        } else {
          updated = updated.copyWith(
            automationCharge: (updated.automationCharge + 5).clamp(0, 100),
          );
        }
        break;
    }

    _state = updated.copyWith(
      activeEvent: null,
      totalEventsClicked: updated.totalEventsClicked + 1,
      currentEventChain: updated.currentEventChain + 1,
      bestEventChain:
          math.max(updated.bestEventChain, updated.currentEventChain + 1),
      rareEventsFound: updated.rareEventsFound +
          (event.rarity.index >= EventRarity.rare.index ? 1 : 0),
      riskyChoicesTaken:
          updated.riskyChoicesTaken + (aggressiveChoice ? 1 : 0),
      eventPityCounter: 0,
      missedEventCharges: math.max(0, updated.missedEventCharges - 1),
      playstyleTendencies: _bumpTendency(
        aggressiveChoice
            ? _bumpTendency(updated.playstyleTendencies, 'risky', 1)
            : updated.playstyleTendencies,
        'event_hunter',
        0.8,
      ),
      guideAffinity: updated.guideAffinity + (aggressiveChoice ? 0.25 : 0.4),
    );
    _updateChallengeProgress();
    _checkSceneBadges();
    _checkMilestones();
    _syncGuideMilestones();
    _refreshGuidance();
    return true;
  }

  bool dismissActiveEvent() {
    final event = _state.activeEvent;
    if (event == null) return false;
    _activeRoomSceneEvent = null;
    _state = _state.copyWith(
      activeEvent: null,
      currentEventChain: 0,
      totalEventsMissed: _state.totalEventsMissed + 1,
      missedEventCharges: (_state.missedEventCharges + 1).clamp(0, 3),
      eventPityCounter: _state.eventPityCounter + 1,
    );
    _refreshGuidance();
    return true;
  }

  bool claimQuestReward() {
    final quest = _state.activeQuest;
    if (quest == null || !quest.completed || quest.claimed) return false;
    final reward = GameNumber.fromDouble(
      math.max(20, productionPerSecond.toDouble() * 10),
    );
    _state = _state.copyWith(
      coins: _state.coins + reward,
      totalCoinsEarned: _state.totalCoinsEarned + reward,
      guideAffinity: _state.guideAffinity + 1,
      activeQuest: quest.copyWith(claimed: true),
    );
    _ensureQuest(forceRefresh: true);
    _pushNarrativeBeat(
      id: 'quest_${quest.id}',
      title: 'Task Complete',
      body:
          'The AI logged your success and adjusted its future recommendations.',
    );
    _refreshGuidance();
    return true;
  }

  // ─── Tick / production ───────────────────────────────────────────────

  void tick(double deltaSeconds) {
    _decayComboIfNeeded();
    _updateAbilityTimers(deltaSeconds);
    _eventAccumulator += deltaSeconds;

    final earned = productionPerSecond * GameNumber.fromDouble(deltaSeconds);
    if (!earned.isZero) {
      _state = _state.copyWith(
        coins: _state.coins + earned,
        totalCoinsEarned: _state.totalCoinsEarned + earned,
        totalPlaySeconds: _state.totalPlaySeconds + deltaSeconds,
        automationCharge: (_state.automationCharge + deltaSeconds * 0.9)
            .clamp(0, 100),
        purchaseMomentum: (_state.purchaseMomentum - deltaSeconds * 0.18)
            .clamp(0, 12),
        playstyleTendencies: _bumpTendency(
          _state.playstyleTendencies,
          'passive',
          deltaSeconds * 0.03,
        ),
      );
    } else {
      _state = _state.copyWith(
        totalPlaySeconds: _state.totalPlaySeconds + deltaSeconds,
        purchaseMomentum: (_state.purchaseMomentum - deltaSeconds * 0.18)
            .clamp(0, 12),
      );
    }

    _updateActiveEvent(deltaSeconds);
    _updateMutators(deltaSeconds);
    _maybeSpawnEvent();
    _updateQuestProgress();
    _updateChallengeProgress();
    _checkEraUnlocks();
    _checkSceneBadges();
    _checkRoomProgression();
    _checkMilestones();
    _checkAchievements();
    _refreshGuidance();

    _autoSaveAccumulator += deltaSeconds;
    final autoSaveInterval = _config.autoSaveIntervalSeconds.clamp(15, 30);
    if (_autoSaveAccumulator >= autoSaveInterval) {
      _autoSaveAccumulator = 0;
      saveGame();
    }
  }

  // ─── Offline earnings ────────────────────────────────────────────────

  void applyOfflineEarnings() {
    final before = _state.coins;
    final lastSave = _state.lastSaveTime;
    _state = OfflineProgression.applyOfflineEarnings(
      _state,
      _config.generators,
      _timeProvider.now(),
      _config.maxOfflineHours,
    );
    final earned = _state.coins - before;
    final timeAway = _timeProvider.now().difference(lastSave);
    _state = _state.copyWith(
      totalOfflineSeconds: _state.totalOfflineSeconds + timeAway.inSeconds,
    );
    if (!earned.isZero) {
      pendingOfflineEarnings = earned;
      pendingReturnSummary = ReturnSummary(
        timeAway: timeAway,
        observation: _offlineObservation(timeAway),
        incentive: _returnIncentive(),
      );
    }
  }

  // ─── Save / load ────────────────────────────────────────────────────

  void updateSaveTime() {
    _state = _state.copyWith(lastSaveTime: _timeProvider.now());
  }

  void setState(GameState state) {
    _state = state;
    _activeRoomSceneEvent = null;
    _checkEraUnlocks();
    _checkSceneBadges();
    _checkRoomProgression();
    _ensureQuest();
    _ensureChallenges();
    _syncGuideMilestones();
    _refreshGuidance();
  }

  Future<void> saveGame() async {
    updateSaveTime();
    final saveOperation =
        _saveFuture?.then((_) => _persistState()) ?? _persistState();
    _saveFuture = saveOperation;
    await saveOperation;
  }

  Future<bool> loadGame() async {
    if (_repository == null) return false;
    final saved = await _repository!.loadGame();
    if (saved == null) return false;
    _activeRoomSceneEvent = null;
    _state = saved.copyWith(activeEvent: null);
    _syncRoomToCurrentEra(force: true);
    _bootstrapRoomCollections();
    _checkEraUnlocks();
    _checkSceneBadges();
    if (!_state.unlockedEras.contains(_state.currentEraId)) {
      _state = _state.copyWith(currentEraId: _highestUnlockedEraId);
    }
    _ensureQuest();
    _ensureChallenges();
    applyOfflineEarnings();
    _checkEraUnlocks();
    _checkSceneBadges();
    _syncGuideMilestones();
    _refreshGuidance();
    return true;
  }

  void _syncRoomToCurrentEra({bool force = false}) {
    if (_roomSceneService == null) return;
    final era = _eraById(_state.currentEraId);
    if (era == null) return;
    final room = _roomSceneService!.getRoomByOrder(era.order);
    if (room == null) return;
    if (!force && _state.currentRoomId == room.id) return;

    final roomStates = Map<String, RoomSceneState>.from(_state.roomStates);
    roomStates.putIfAbsent(room.id, () => RoomSceneState(roomId: room.id));
    _state = _state.copyWith(
      currentRoomId: room.id,
      roomStates: roomStates,
    );
  }

  void _bootstrapRoomCollections() {
    if (_roomSceneService == null) return;
    final rooms = _roomSceneService!.allRooms;
    if (rooms.isEmpty) return;

    final codex = _state.codex;
    final existingSecretIds = {
      for (final entry in codex.secretArchive) entry.id,
    };
    final existingLoreIds = {
      for (final entry in codex.sceneLore) entry.id,
    };
    final existingEntryIds = {
      for (final entry in codex.entries) entry.id,
    };
    final secretArchive = List<SecretArchiveEntry>.from(codex.secretArchive);
    final sceneLore = List<SceneLoreEntry>.from(codex.sceneLore);
    final entries = List<CodexEntry>.from(codex.entries);

    for (final room in rooms) {
      for (final secret in room.secrets) {
        if (existingSecretIds.add(secret.id)) {
          secretArchive.add(
            SecretArchiveEntry(
              id: secret.id,
              roomId: room.id,
              title: secret.title,
              description: secret.description,
              hint: secret.hint,
              clueSource: secret.clueSource,
              rewardDescription: '${secret.rewardType}:${secret.rewardValue}',
              discovered: _state.discoveredSecrets.contains(secret.id),
            ),
          );
        }
      }
      final introLoreId = 'scene_intro_${room.id}';
      if (existingLoreIds.add(introLoreId)) {
        sceneLore.add(
          SceneLoreEntry(
            id: introLoreId,
            roomId: room.id,
            title: '${room.name} Briefing',
            content: room.introText,
            loreCategory: 'intro',
            chapter: room.order,
            discovered: room.id == _state.currentRoomId,
          ),
        );
      }
      final transformationEntryId = 'transformation_${room.id}';
      if (existingEntryIds.add(transformationEntryId)) {
        entries.add(
          CodexEntry(
            id: transformationEntryId,
            title: '${room.name} Transformation Track',
            content: room.transformationStages
                .map((stage) => '${stage.name}: ${stage.description}')
                .join('\n'),
            type: CodexEntryType.transformationArchive,
            category: room.mechanicEmphasis.name,
            roomId: room.id,
            discovered: room.id == _state.currentRoomId,
            icon: 'room',
            rarity: 'uncommon',
          ),
        );
      }
    }

    _state = _state.copyWith(
      codex: codex.copyWith(
        entries: entries,
        secretArchive: secretArchive,
        sceneLore: sceneLore,
      ),
    );
  }

  String? _eraIdForRoom(RoomScene room) {
    for (final era in _config.eras) {
      if (era.order == room.order) return era.id;
    }
    return null;
  }

  // ─── Prestige ────────────────────────────────────────────────────────

  bool get canPrestige => PrestigeSystem.canPrestige(_state);

  GameNumber get nextPrestigeMultiplier =>
      PrestigeSystem.calculatePrestigeMultiplier(_state.totalCoinsEarned);

  bool prestige() {
    if (!canPrestige) return false;
    final preservedMilestones = _state.unlockedMilestones;
    final preservedSecrets = _state.discoveredSecrets;
    final preservedBranches = _state.chosenBranches;
    final preservedAbilities = _state.abilities.map(
      (k, v) => MapEntry(k, v.copyWith(cooldownRemaining: 0, activeRemaining: 0)),
    );
    final preservedMeta = _state.metaProgression;
    final preservedCodex = _state.codex;
    final preservedRoomStates = _state.roomStates;
    final preservedCurrentRoomId = _state.currentRoomId;

    _state = PrestigeSystem.performPrestige(_state).copyWith(
      unlockedMilestones: preservedMilestones,
      discoveredSecrets: preservedSecrets,
      chosenBranches: preservedBranches,
      abilities: preservedAbilities,
      seenEventTemplates: _state.seenEventTemplates,
      completedSceneBadges: _state.completedSceneBadges,
      guideAffinity: _state.guideAffinity,
      routeSignature:
          '${_state.routeSignature}|prestige${_state.prestigeCount + 1}',
      metaProgression: preservedMeta,
      codex: preservedCodex,
      roomStates: preservedRoomStates,
      currentRoomId: preservedCurrentRoomId,
    );
    saveGame();
    _refreshGuidance();
    return true;
  }

  // ─── Tutorial ────────────────────────────────────────────────────────

  void completeTutorial() {
    _state = _state.copyWith(tutorialComplete: true);
  }

  Future<void> _persistState() async {
    await _repository?.saveGame(_state);
  }

  // ─── Internal helpers ────────────────────────────────────────────────

  GameNumber get _tapBonusMultiplier {
    var value = 1.0;
    if (_abilityActive(ActiveAbilityType.focus)) value += 0.9;
    if (_abilityActive(ActiveAbilityType.sync)) value += 0.25;
    if (_state.chosenBranches.contains('tap')) value += 0.4;
    if (_state.chosenBranches.contains('hybrid')) value += 0.18;
    if (_state.unlockedMilestones.contains('combo_master')) {
      value += 0.15;
    }
    return GameNumber.fromDouble(value);
  }

  GameNumber get _productionBonusMultiplier {
    var value = 1.0;
    if (_abilityActive(ActiveAbilityType.overclock)) value += 0.8;
    if (_abilityActive(ActiveAbilityType.sync)) value += 0.25;
    if (_state.chosenBranches.contains('automation')) value += 0.48;
    if (_state.chosenBranches.contains('hybrid')) value += 0.18;
    if (_state.chosenBranches.contains('risky')) value += 0.22;
    if (_state.unlockedMilestones.contains('engine_room')) {
      value += 0.12;
    }
    return GameNumber.fromDouble(value);
  }

  double get _criticalChance {
    var value = 0.05 + (_state.tapCombo * 0.003);
    value += (_state.automationCharge / 900);
    if (_state.chosenBranches.contains('tap')) value += 0.08;
    if (_state.chosenBranches.contains('risky')) value += 0.12;
    if (_state.discoveredSecrets.contains('cache_echo')) value += 0.03;
    return value.clamp(0.05, 0.42);
  }

  double get _criticalMultiplier {
    var value = 2.2;
    if (_state.chosenBranches.contains('risky')) value += 0.7;
    if (_state.unlockedMilestones.contains('combo_master')) {
      value += 0.25;
    }
    return value;
  }

  int get _highestReachedEraOrder {
    var bestOrder = 1;
    for (final era in _config.eras) {
      if (_state.unlockedEras.contains(era.id) && era.order > bestOrder) {
        bestOrder = era.order;
      }
    }
    return bestOrder;
  }

  String get _currentEraId {
    if (_state.unlockedEras.contains(_state.currentEraId)) {
      return _state.currentEraId;
    }
    return _highestUnlockedEraId;
  }

  String get _highestUnlockedEraId {
    var best = _config.eras.first.id;
    var bestOrder = 1;
    for (final era in _config.eras) {
      if (_state.unlockedEras.contains(era.id) && era.order > bestOrder) {
        best = era.id;
        bestOrder = era.order;
      }
    }
    return best;
  }

  Set<String> get _ownedEraIds {
    final ids = <String>{'era_1'};
    for (final generator in _config.generators.values) {
      final level = _state.generators[generator.id]?.level ?? 0;
      if (level > 0) {
        ids.add(generator.eraId);
      }
    }
    return ids;
  }

  Era? _eraById(String eraId) {
    for (final era in _config.eras) {
      if (era.id == eraId) return era;
    }
    return null;
  }

  bool _abilityActive(ActiveAbilityType type) =>
      _state.abilities[type.name]?.isActive ?? false;

  void _updateAbilityTimers(double deltaSeconds) {
    if (_state.abilities.isEmpty) return;
    final updated = <String, ActiveAbilityState>{};
    for (final entry in _state.abilities.entries) {
      updated[entry.key] = entry.value.copyWith(
        cooldownRemaining:
            math.max(0, entry.value.cooldownRemaining - deltaSeconds),
        activeRemaining:
            math.max(0, entry.value.activeRemaining - deltaSeconds),
      );
    }
    _state = _state.copyWith(abilities: updated);
  }

  void _updateActiveEvent(double deltaSeconds) {
    final event = _state.activeEvent;
    if (event == null) return;
    final remaining = event.remainingSeconds - deltaSeconds;
    if (remaining <= 0) {
      _activeRoomSceneEvent = null;
      _state = _state.copyWith(
        activeEvent: null,
        currentEventChain: 0,
        totalEventsMissed: _state.totalEventsMissed + 1,
        missedEventCharges: (_state.missedEventCharges + 1).clamp(0, 3),
        eventPityCounter: _state.eventPityCounter + 1,
      );
      return;
    }
    _state = _state.copyWith(
      activeEvent: event.copyWith(remainingSeconds: remaining),
    );
  }

  void _maybeSpawnEvent() {
    if (!_eventsEnabled) return;
    // Cap accumulator to prevent unbounded growth even during active events
    if (_eventAccumulator > 60) _eventAccumulator = 60;
    if (_state.activeEvent != null || _eventAccumulator < 12) return;
    // Clear the previous event reward summary so the result banner goes away.
    lastEventRewardSummary = null;
    if (_trySpawnRoomSceneEvent()) return;

    final chance = (_state.chosenBranches.contains('risky') ? 0.045 : 0.024) +
        ((_state.eventPityCounter + _state.missedEventCharges) * 0.006)
            .clamp(0.0, 0.06) +
        (guideTier * 0.002);
    if (_random.nextDouble() > chance) return;
    final rarity = _rollEventRarity();
    final currentEra = _eraById(_currentEraId);
    final eraOrder = currentEra?.order ?? 1;
    final templates = _config.progression.events
        .where((item) => rarity.index >= item.minimumRarity.index)
        .where((item) => _isTemplateAvailableForEra(item, eraOrder))
        .where((item) =>
            item.requiredMilestoneId == null ||
            _state.unlockedMilestones.contains(item.requiredMilestoneId))
        .where((item) =>
            item.requiredBranchId == null ||
            _state.chosenBranches.contains(item.requiredBranchId))
        .toList();
    if (templates.isEmpty) return;
    _eventAccumulator = 0;

    final template = templates[_random.nextInt(templates.length)];
    final event = GameEventState(
      id: '${template.id}_${_state.totalEventsSpawned + 1}',
      type: template.type,
      title: template.title,
      description: template.description,
      remainingSeconds: template.baseDurationSeconds +
          (rarity.index >= EventRarity.epic.index ? 2 : 0),
      risky: template.risky || rarity.index >= EventRarity.corrupted.index,
      rarity: rarity,
      clickOnly: template.clickOnly || rarity.index >= EventRarity.epic.index,
    );

    _state = _state.copyWith(
      activeEvent: event,
      totalEventsSpawned: _state.totalEventsSpawned + 1,
      seenEventTemplates: {..._state.seenEventTemplates, template.id},
    );
    if (rarity.index >= EventRarity.epic.index) {
      _pushNarrativeBeat(
        id: 'event_${template.id}_${_state.totalEventsSpawned}',
        title: '${template.title} / ${currentEra?.name ?? 'Unknown Room'}',
        body: 'A higher-tier anomaly just manifested inside the current room.',
      );
    }
  }

  void _decayComboIfNeeded() {
    final lastTapTime = _state.lastTapTime;
    if (lastTapTime == null || _state.tapCombo == 0) return;
    final elapsed = _timeProvider.now().difference(lastTapTime).inMilliseconds;
    if (elapsed > TapSystem.comboWindowMs) {
      _state = _state.copyWith(tapCombo: 0);
    }
  }

  void _checkMilestones() {
    final previous = _state.unlockedMilestones;
    final updated = <String>{...previous};

    for (final milestone in _config.progression.milestones) {
      if (_progressMetricValue(milestone.metric) >= milestone.target) {
        updated.add(milestone.id);
      }
    }

    if (updated.length == previous.length) return;

    final newIds = updated.difference(previous);
    final abilities = Map<String, ActiveAbilityState>.from(_state.abilities);
    for (final milestoneId in newIds) {
      final definition = _config.milestoneById(milestoneId);
      final abilityId = definition?.unlockAbilityId;
      if (abilityId != null) {
        final ability = abilities[abilityId];
        if (ability != null) {
          abilities[abilityId] = ability.copyWith(unlocked: true);
        }
      }
    }

    lastUnlockedMilestones = newIds.toList();
    _state = _state.copyWith(
      unlockedMilestones: updated,
      abilities: abilities,
    );
    for (final milestoneId in newIds) {
      final definition = _config.milestoneById(milestoneId);
      _pushNarrativeForTrigger(
        triggerKey: 'milestone.$milestoneId',
        fallbackId: 'milestone_$milestoneId',
        fallbackTitle: definition?.title ?? 'System Threshold Reached',
        fallbackBody:
            definition?.narrative ?? 'A new threshold has been crossed.',
      );
    }
  }

  void _checkEraUnlocks() {
    var unlocked = <String>{..._state.unlockedEras};
    String? newestEraId;
    var newestOrder = _highestReachedEraOrder;

    for (final era in _config.eras) {
      if (unlocked.contains(era.id)) continue;
      GeneratorDefinition? generator;
      for (final item in _config.generators.values) {
        if (item.eraId == era.id) {
          generator = item;
          break;
        }
      }
      final requirement = generator?.unlockRequirement ?? era.unlockRequirement;
      if (requirement == null || requirement.isEmpty) {
        unlocked.add(era.id);
      } else {
        final parts = requirement.split(':');
        if (parts.length != 2) continue;
        final generatorId = parts.first;
        final neededLevel = int.tryParse(parts.last) ?? 0;
        final currentLevel = _state.generators[generatorId]?.level ?? 0;
        if (currentLevel < neededLevel) continue;
        unlocked.add(era.id);
      }

      if (unlocked.contains(era.id) && era.order > newestOrder) {
        newestEraId = era.id;
        newestOrder = era.order;
      }
    }

    if (unlocked.length == _state.unlockedEras.length && newestEraId == null) {
      return;
    }

    _state = _state.copyWith(
      unlockedEras: unlocked,
      currentEraId: newestEraId ?? _currentEraId,
    );
    _stateVersion++;

    if (newestEraId != null) {
      final era = _eraById(newestEraId);
      _pushNarrativeForTrigger(
        triggerKey: 'era.$newestEraId',
        fallbackId: 'era_unlock_$newestEraId',
        fallbackTitle: era?.name ?? 'New Room Online',
        fallbackBody: era?.description ??
            'A new room configuration is ready for exploration.',
      );
    }
  }

  void _checkSecrets() {
    final previous = <String>{..._state.discoveredSecrets};
    final discovered = <String>{...previous};
    for (final secret in _config.progression.secrets) {
      if (secret.requiredBranchId != null &&
          !_state.chosenBranches.contains(secret.requiredBranchId)) {
        continue;
      }
      if (secret.requiredMilestoneId != null &&
          !_state.unlockedMilestones.contains(secret.requiredMilestoneId)) {
        continue;
      }
      if (_progressMetricValue(secret.metric) >= secret.target) {
        discovered.add(secret.id);
      }
    }
    final newSecrets = discovered.difference(previous);
    if (newSecrets.isNotEmpty) {
      _state = _state.copyWith(
        discoveredSecrets: discovered,
        guideAffinity: _state.guideAffinity + (newSecrets.length * 0.8),
      );
      for (final id in newSecrets) {
        final secret = _config.progression.secrets.firstWhere(
          (item) => item.id == id,
        );
        _pushNarrativeBeat(
          id: 'secret_$id',
          title: secret.title,
          body: secret.description,
        );
      }
    }
  }

  void _checkSceneBadges() {
    final completed = <String>{..._state.completedSceneBadges};
    for (final era in _config.eras) {
      final roomUpgrades = _config.upgrades.values
          .where((item) => item.eraId == era.id)
          .toList();
      if (roomUpgrades.isEmpty) continue;
      final bought = roomUpgrades
          .where((item) => (_state.upgrades[item.id]?.level ?? 0) > 0)
          .length;
      GeneratorDefinition? generator;
      for (final item in _config.generators.values) {
        if (item.eraId == era.id) {
          generator = item;
          break;
        }
      }
      final generatorLevel =
          generator == null ? 0 : (_state.generators[generator.id]?.level ?? 0);
      final ratio = bought / roomUpgrades.length;
      if (ratio >= 0.65 && generatorLevel >= 18) {
        completed.add(era.id);
      }
    }
    final newlyCompleted = completed.difference(_state.completedSceneBadges);
    if (newlyCompleted.isEmpty) return;
    _state = _state.copyWith(
      completedSceneBadges: completed,
      branchRespecTokens: _state.branchRespecTokens + newlyCompleted.length,
      challengeRerollsRemaining:
          (_state.challengeRerollsRemaining + newlyCompleted.length).clamp(0, 6),
      guideAffinity: _state.guideAffinity + newlyCompleted.length * 1.5,
    );
    for (final eraId in newlyCompleted) {
      final era = _eraById(eraId);
      _pushNarrativeBeat(
        id: 'scene_complete_$eraId',
        title: '${era?.name ?? eraId} Complete',
        body:
            'The room stabilized into a lasting configuration. The guide archived the run and opened stronger planning tools.',
      );
    }
  }

  void _checkRoomProgression() {
    if (_roomSceneService == null) return;

    final roomId = _state.currentRoomId;
    final roomState = currentRoomState;

    // Update upgrade count in room state based on current era upgrades
    final eraUpgrades = _config.upgrades.values
        .where((item) => item.eraId == _currentEraId)
        .toList();
    final bought =
        eraUpgrades.where((item) => (_state.upgrades[item.id]?.level ?? 0) > 0).length;

    if (bought != roomState.upgradesPurchased) {
      final updatedStates =
          Map<String, RoomSceneState>.from(_state.roomStates);
      updatedStates[roomId] = roomState.copyWith(upgradesPurchased: bought);
      _state = _state.copyWith(roomStates: updatedStates);
    }

    // Auto-advance transformation stages
    final room = _roomSceneService!.getRoomById(roomId);
    if (room != null) {
      final rs = _state.roomStates[roomId] ??
          RoomSceneState(roomId: roomId);
      for (var i = rs.currentTransformationStage + 1;
          i < room.transformationStages.length;
          i++) {
        if (rs.upgradesPurchased >=
            room.transformationStages[i].requiredUpgrades) {
          advanceTransformationStage();
        } else {
          break;
        }
      }
    }

    // Auto-detect room twist activation
    if (room?.midSceneTwist != null && !currentRoomState.twistActivated) {
      final twist = room!.midSceneTwist!;
      // Simple trigger: check if enough upgrades purchased
      final match =
          RegExp(r'upgrades.*>=?\s*(\d+)').firstMatch(twist.triggerCondition);
      if (match != null) {
        final threshold = int.tryParse(match.group(1)!) ?? 999999;
        if (currentRoomState.upgradesPurchased >= threshold) {
          activateRoomTwist();
        }
      }
    }
  }

  void _updateQuestProgress() {
    _ensureQuest();
    final quest = _state.activeQuest;
    if (quest == null) return;
    final definition = _config.questById(quest.id);
    final progress = definition == null
        ? _state.totalCoinsEarned.toDouble()
        : _progressMetricValue(definition.metric);

    _state = _state.copyWith(
      activeQuest: quest.copyWith(
        progress: progress.clamp(0, quest.target),
        completed: progress >= quest.target,
      ),
    );
  }

  void _ensureQuest({bool forceRefresh = false}) {
    if (!forceRefresh && _state.activeQuest != null && !_state.activeQuest!.claimed) {
      return;
    }

    final available = _config.progression.quests.where((quest) {
      if (quest.requiredMilestoneId != null &&
          !_state.unlockedMilestones.contains(quest.requiredMilestoneId)) {
        return false;
      }
      if (quest.requiredBranchId != null &&
          !_state.chosenBranches.contains(quest.requiredBranchId)) {
        return false;
      }
      final metricValue = _progressMetricValue(quest.metric);
      final target = _questTarget(quest);
      return metricValue < target;
    }).toList();

    final definition = available.isNotEmpty
        ? available.first
        : (_config.progression.quests.isNotEmpty
            ? _config.progression.quests.last
            : const QuestDefinition(
                id: 'fallback_expansion',
                title: 'Expansion Pulse',
                description: 'Push your total resources to the next target.',
                metric: ProgressMetric.totalCoins,
                targetMultiplier: 1.3,
                minimumTarget: 1000,
              ));
    final quest = QuestState(
      id: definition.id,
      title: definition.title,
      description: definition.description,
      target: _questTarget(definition),
    );

    _state = _state.copyWith(activeQuest: quest);
    _updateQuestProgress();
  }

  void _ensureChallenges() {
    final updated = [..._state.challenges];
    if (dailyChallenge == null) {
      updated.add(
        _generateChallenge(
          ChallengePeriod.daily,
          seasonKey: _challengeSeasonKey(ChallengePeriod.daily),
        ),
      );
    }
    if (weeklyChallenge == null) {
      updated.add(
        _generateChallenge(
          ChallengePeriod.weekly,
          seasonKey: _challengeSeasonKey(ChallengePeriod.weekly),
        ),
      );
    }
    final rotated = updated.map((challenge) {
      final periodKey = _challengeSeasonKey(challenge.period);
      if (challenge.seasonKey == periodKey) return challenge;
      return _generateChallenge(challenge.period, seasonKey: periodKey);
    }).toList();
    if (rotated.length != _state.challenges.length ||
        !_sameChallengeSet(rotated, _state.challenges)) {
      _state = _state.copyWith(challenges: rotated);
      _updateChallengeProgress();
    }
  }

  void _updateChallengeProgress() {
    if (_state.challenges.isEmpty) return;
    _state = _state.copyWith(
      challenges: _state.challenges.map((challenge) {
        final progress = _challengeProgressValue(challenge);
        return challenge.copyWith(
          progress: progress.clamp(0, challenge.target),
          completed: challenge.completed || progress >= challenge.target,
        );
      }).toList(),
    );
  }

  void _checkAchievements() {
    if (_config.achievements.isEmpty) return;
    final newIds = AchievementSystem.checkAchievements(
      _state,
      _config.achievements,
      productionPerSecond,
    );
    if (newIds.isNotEmpty) {
      _state = AchievementSystem.applyAchievements(_state, newIds);
      lastUnlockedAchievements = _config.achievements
          .where((a) => newIds.contains(a.id))
          .toList();
    } else {
      lastUnlockedAchievements = [];
    }
  }

  void _refreshGuidance() {
    final quest = _state.activeQuest;
    if (quest != null && !quest.completed) {
      lastRecommendation = 'Quest: ${quest.title}';
      lastAiLine = 'AI suggests a short-term objective: ${quest.description}';
      return;
    }

    if (_state.activeEvent != null) {
      lastRecommendation = 'Resolve ${_state.activeEvent!.title}';
      lastAiLine = 'A live event is affecting the room. Decide quickly.';
      return;
    }

    final readyAbility = _state.abilities.values.where((a) => a.isReady).toList();
    if (readyAbility.isNotEmpty) {
      lastRecommendation = 'Use ${readyAbility.first.type.name}';
      lastAiLine = 'Ability ready. Burst windows are strongest when stacked.';
      return;
    }

    final affordableUpgrade = _config.upgrades.values.where((upgrade) {
      final state = _state.upgrades[upgrade.id];
      final level = state?.level ?? 0;
      if (level >= upgrade.maxLevel) return false;
      final cost = CostCalculator.calculateCost(
        upgrade.baseCost,
        upgrade.costGrowthRate,
        level,
      );
      return _state.coins >= cost;
    }).toList()
      ..sort((a, b) => a.baseCost.toDouble().compareTo(b.baseCost.toDouble()));

    if (affordableUpgrade.isNotEmpty) {
      lastRecommendation = 'Buy ${affordableUpgrade.first.name}';
      lastAiLine = 'That upgrade is currently the cheapest power spike.';
      return;
    }

    lastRecommendation = 'Grow income toward the next branch';
    lastAiLine = 'The room is stable. Build momentum for the next unlock.';
  }

  String _offlineObservation(Duration timeAway) {
    if (dominantPlaystyle == 'Automation Architect') {
      return 'Your automation lattice held formation for ${timeAway.inMinutes} minutes.';
    }
    if (dominantPlaystyle == 'Active Operator') {
      return 'The room missed your input, but the core kept humming.';
    }
    if (dominantPlaystyle == 'Risk Runner') {
      return 'Several unstable patterns settled while you were away.';
    }
    return 'Background processes kept the room evolving while you were away.';
  }

  String _returnIncentive() {
    if (_state.missedEventCharges > 0) {
      return 'A comeback anomaly charge is waiting in the room.';
    }
    if (_state.challengeRerollsRemaining > 0) {
      return 'You still have challenge rerolls available.';
    }
    return 'Your next milestone is close. A short session should push the tree forward.';
  }

  ChallengeState _generateChallenge(
    ChallengePeriod period, {
    required String seasonKey,
    int rerollsUsed = 0,
  }) {
    final templates = _config.progression.challenges
        .where((item) => item.period == period)
        .where((item) =>
            item.requiredMilestoneId == null ||
            _state.unlockedMilestones.contains(item.requiredMilestoneId))
        .toList();

    if (templates.isEmpty) {
      return ChallengeState(
        id: '${period.name}_fallback',
        period: period,
        metric: ChallengeMetric.totalTaps,
        title: period == ChallengePeriod.weekly
            ? 'Weekly Calibration'
            : 'Daily Calibration',
        description: 'Keep the room active and maintain forward momentum.',
        target: period == ChallengePeriod.weekly ? 1200 : 120,
        startValue: _challengeMetricValue(ChallengeMetric.totalTaps),
        seasonKey: seasonKey,
        rerollsUsed: rerollsUsed,
      );
    }

    final totalWeight =
        templates.fold<int>(0, (sum, item) => sum + math.max(1, item.weight));
    var roll = _random.nextInt(math.max(1, totalWeight));
    ChallengeTemplateDefinition selected = templates.first;
    for (final template in templates) {
      roll -= math.max(1, template.weight);
      if (roll < 0) {
        selected = template;
        break;
      }
    }

    return ChallengeState(
      id: selected.id,
      period: period,
      metric: selected.metric,
      title: selected.title,
      description: selected.description,
      target: _scaledChallengeTarget(selected),
      startValue: _challengeStartValue(selected.metric),
      seasonKey: seasonKey,
      rerollsUsed: rerollsUsed,
    );
  }

  double _challengeMetricValue(ChallengeMetric metric) {
    return switch (metric) {
      ChallengeMetric.totalTaps => _state.totalTaps.toDouble(),
      ChallengeMetric.eventClicks => _state.totalEventsClicked.toDouble(),
      ChallengeMetric.bestEventChain => _state.currentEventChain.toDouble(),
      ChallengeMetric.upgradesBought => _state.totalUpgradesPurchased.toDouble(),
      ChallengeMetric.combo => _state.tapCombo.toDouble(),
      ChallengeMetric.riskyChoices => _state.riskyChoicesTaken.toDouble(),
      ChallengeMetric.productionBurst => productionPerSecond.toDouble(),
      ChallengeMetric.roomSecretsFound =>
        _state.metaProgression.secretsArchived.length.toDouble(),
      ChallengeMetric.roomTransformations =>
        _state.roomStates.values
            .fold<int>(0, (sum, rs) => sum + rs.currentTransformationStage)
            .toDouble(),
    };
  }

  EventRarity _rollEventRarity() {
    final roll = _random.nextDouble();
    final riskyBias = _state.chosenBranches.contains('risky') ? 0.04 : 0;
    final pityBias = (_state.eventPityCounter * 0.01).clamp(0.0, 0.08);
    if (roll < 0.01 + riskyBias + pityBias * 0.35) return EventRarity.legendary;
    if (roll < 0.04 + riskyBias + pityBias * 0.5) return EventRarity.corrupted;
    if (roll < 0.12 + riskyBias + pityBias) return EventRarity.epic;
    if (roll < 0.34 + riskyBias + pityBias) return EventRarity.rare;
    return EventRarity.common;
  }

  bool _isTemplateAvailableForEra(EventTemplateDefinition template, int eraOrder) {
    return switch (template.type) {
      GameEventType.powerSurge || GameEventType.aiIdea => true,
      GameEventType.hardwareMalfunction => eraOrder >= 4,
      GameEventType.marketSpike => eraOrder >= 3,
      GameEventType.mysteryCache => eraOrder >= 6,
      GameEventType.breachFragment => eraOrder >= 9,
      GameEventType.dataCorruption => eraOrder >= 5,
    };
  }

  void _updateMutators(double deltaSeconds) {
    if (_state.activeMutators.isEmpty) return;
    final updated = _state.activeMutators
        .map((item) =>
            item.copyWith(remainingSeconds: item.remainingSeconds - deltaSeconds))
        .where((item) => item.remainingSeconds > 0)
        .toList();
    if (updated.length != _state.activeMutators.length) {
      _state = _state.copyWith(activeMutators: updated);
    }
  }

  bool _trySpawnRoomSceneEvent() {
    final pool = _roomSceneService?.getEventPool(_state.currentRoomId);
    if (pool == null) return false;

    final chance = ((_state.chosenBranches.contains('risky') ? 0.038 : 0.022) *
            pool.spawnRateMultiplier) +
        ((_state.eventPityCounter + _state.missedEventCharges) * 0.006)
            .clamp(0.0, 0.08) +
        (guideTier * 0.0025);
    if (_random.nextDouble() > chance) return false;

    final rolledRarity = _rollEventRarity();
    final eligible = <SceneEventDefinition>[
      ...pool.events,
      if (currentRoomState.twistActivated) ...pool.midTwistEvents,
    ].where((event) {
      if (event.roomId != _state.currentRoomId) return false;
      if (currentRoomState.upgradesPurchased < event.requiredUpgradeCount) {
        return false;
      }
      if (event.requiredTwistActive && !currentRoomState.twistActivated) {
        return false;
      }
      return _sceneEventRarityRank(event.rarity) <= rolledRarity.index;
    }).toList();
    if (eligible.isEmpty) return false;

    final totalWeight = eligible.fold<int>(0, (sum, item) => sum + item.weight);
    var roll = _random.nextInt(math.max(1, totalWeight));
    SceneEventDefinition selected = eligible.first;
    for (final item in eligible) {
      roll -= item.weight;
      if (roll < 0) {
        selected = item;
        break;
      }
    }

    _eventAccumulator = 0;
    _activeRoomSceneEvent = selected;
    final runtimeEvent = GameEventState(
      id: '${selected.id}_${_state.totalEventsSpawned + 1}',
      type: _eventTypeForSceneEvent(selected.category),
      title: selected.title,
      description: selected.description,
      remainingSeconds: selected.durationSeconds,
      risky: selected.choices.length > 1 &&
          selected.choices.last.risk >= selected.choices.first.risk,
      rarity: _eventRarityFromScene(selected.rarity),
      clickOnly: selected.choices.isEmpty,
    );
    _state = _state.copyWith(
      activeEvent: runtimeEvent,
      totalEventsSpawned: _state.totalEventsSpawned + 1,
      seenEventTemplates: {..._state.seenEventTemplates, selected.id},
    );
    // Notify UI that the first room scene event just spawned.
    // totalEventsSpawned is already incremented above; value 1 = first event ever.
    if (_state.totalEventsSpawned == 1) firstEventJustSpawned = true;
    _recordSceneEventArchive(selected);
    if (runtimeEvent.rarity.index >= EventRarity.rare.index) {
      _pushNarrativeBeat(
        id: 'room_event_${selected.id}_${_state.totalEventsSpawned}',
        title: '${selected.title} / ${currentRoom?.name ?? _state.currentRoomId}',
        body: selected.flavorText.isEmpty
            ? selected.description
            : selected.flavorText,
      );
    }
    return true;
  }

  bool _resolveRoomSceneEvent(
    SceneEventDefinition definition,
    GameEventState runtimeEvent, {
    required bool aggressiveChoice,
  }) {
    var updated = _state;
    var triggerTransformation = false;
    final room = currentRoom;
    final rewardScale =
        _rarityRewardMultiplier(runtimeEvent.rarity) *
        (1 + (definition.chainBonus * 0.35)) *
        (1 + (_state.currentEventChain * 0.04).clamp(0, 0.4)) *
        _roomEventIdentityScale(room, definition, aggressiveChoice);
    final rewards = definition.choices.isEmpty
        ? definition.rewards
        : (aggressiveChoice && definition.choices.length > 1
            ? definition.choices.last.rewards
            : definition.choices.first.rewards);

    for (final reward in rewards) {
      switch (reward.type) {
        case EventRewardType.instantCurrency:
          final amount = GameNumber.fromDouble(
            math.max(
              reward.value * 12,
              productionPerSecond.toDouble() * (0.45 + reward.value * 0.11),
            ) *
                rewardScale,
          );
          updated = updated.copyWith(
            coins: updated.coins + amount,
            totalCoinsEarned: updated.totalCoinsEarned + amount,
          );
          break;
        case EventRewardType.temporaryBuff:
          final tapBias = _roomTapBuffBias(room, definition);
          final productionBias = _roomProductionBuffBias(room, definition);
          final tapFactor =
              1 + reward.value * (aggressiveChoice ? 0.015 : 0.01) * tapBias;
          final productionFactor =
              1 +
                  reward.value *
                      (aggressiveChoice ? 0.018 : 0.012) *
                      productionBias;
          updated = updated.copyWith(
            tapMultiplier:
                updated.tapMultiplier * GameNumber.fromDouble(tapFactor),
            productionMultiplier: updated.productionMultiplier *
                GameNumber.fromDouble(productionFactor),
          );
          break;
        case EventRewardType.comboAmplification:
          final comboGain =
              reward.value.round() + _roomComboReward(room, definition);
          updated = updated.copyWith(
            tapCombo: updated.tapCombo + comboGain,
            strongestCombo: math.max(
              updated.strongestCombo,
              updated.tapCombo + comboGain,
            ),
          );
          break;
        case EventRewardType.cooldownChange:
          final cooldownChange =
              reward.value + _roomCooldownReward(room, definition);
          updated = updated.copyWith(
            abilities: updated.abilities.map(
              (key, value) => MapEntry(
                key,
                value.copyWith(
                  cooldownRemaining: math.max(
                    0,
                    value.cooldownRemaining - cooldownChange,
                  ),
                ),
              ),
            ),
          );
          break;
        case EventRewardType.rareResource:
        case EventRewardType.relicFragment:
          final meta = _awardEventFragment(definition, reward, updated.metaProgression);
          updated = updated.copyWith(
            metaProgression: meta,
            branchRespecTokens: updated.branchRespecTokens +
                _roomFragmentBranchBonus(room, runtimeEvent.rarity),
          );
          break;
        case EventRewardType.secretClue:
          _discoverFirstHiddenRoomSecret();
          // Narrative beat for secret clue discovery
          _pushNarrativeBeat(
            id: 'secret_clue_${definition.id}',
            title: 'Secret Clue: ${definition.title}',
            body: definition.flavorText.isEmpty
                ? 'A hidden detail has come to light. Check the codex.'
                : definition.flavorText,
          );
          break;
        case EventRewardType.hiddenBranchProgress:
        case EventRewardType.routeReward:
          updated = updated.copyWith(
            branchRespecTokens: updated.branchRespecTokens +
                1 +
                _roomRouteRewardBonus(room, definition),
          );
          break;
        case EventRewardType.guideAffinity:
          updated = updated.copyWith(
            guideAffinity:
                updated.guideAffinity + reward.value + _roomGuideRewardBonus(room),
          );
          break;
        case EventRewardType.codexEntry:
          updated = updated.copyWith(
            codex: _upsertCodexEntry(
              updated.codex,
              CodexEntry(
                id: 'event_entry_${definition.id}',
                title: definition.title,
                content: reward.description,
                type: CodexEntryType.eventArchive,
                category: definition.category.name,
                roomId: definition.roomId,
                discovered: true,
                icon: 'event',
                rarity: definition.rarity,
              ),
            ),
          );
          break;
        case EventRewardType.environmentTrigger:
          triggerTransformation = true;
          // Room 01 bonus: a small tap multiplier stacks each time an
          // environment event fires in the Junk Corner, rewarding active play
          // in the tutorial room.
          if (_state.currentRoomId == 'room_01') {
            updated = updated.copyWith(
              tapMultiplier: updated.tapMultiplier *
                  GameNumber.fromDouble(_room01EnvTapBonus),
            );
          }
          break;
      }
    }

    updated = _applyRoomEventIdentityBonus(
      updated,
      room: room,
      definition: definition,
      rewardScale: rewardScale,
      aggressiveChoice: aggressiveChoice,
      rarity: runtimeEvent.rarity,
    );

    updated = updated.copyWith(
      activeEvent: null,
      totalEventsClicked: updated.totalEventsClicked + 1,
      currentEventChain: updated.currentEventChain + 1,
      bestEventChain:
          math.max(updated.bestEventChain, updated.currentEventChain + 1),
      rareEventsFound: updated.rareEventsFound +
          (runtimeEvent.rarity.index >= EventRarity.rare.index ? 1 : 0),
      riskyChoicesTaken:
          updated.riskyChoicesTaken + (aggressiveChoice ? 1 : 0),
      eventPityCounter: 0,
      missedEventCharges: math.max(0, updated.missedEventCharges - 1),
      playstyleTendencies: _bumpTendency(
        aggressiveChoice
            ? _bumpTendency(updated.playstyleTendencies, 'risky', 0.9)
            : updated.playstyleTendencies,
        'event_hunter',
        1 + definition.chainBonus,
      ),
      guideAffinity: updated.guideAffinity +
          (definition.category == SceneEventCategory.guideAdvisory ? 0.6 : 0.35),
    );
    _state = updated;

    // Build a concise reward summary for the UI event result banner.
    lastEventRewardSummary = _buildEventRewardSummary(
      definition: definition,
      rewards: rewards,
      rewardScale: rewardScale,
    );

    if (triggerTransformation) {
      advanceTransformationStage();
    }
    // After a long event chain (>3), run a room-progression check to see
    // whether upgrade thresholds or other conditions have been met.  This
    // does NOT guarantee a transformation advance — it simply re-evaluates
    // current progress, the same check that runs after every upgrade purchase.
    if (!triggerTransformation && _state.currentEventChain > 3) {
      _checkRoomProgression();
    }
    if (definition.category == SceneEventCategory.secretTrigger ||
        definition.category == SceneEventCategory.hiddenGlitch) {
      _discoverFirstHiddenRoomSecret();
    }
    if (definition.category == SceneEventCategory.guideAdvisory) {
      recordGuideMemory(
        id: 'guide_event_${definition.id}',
        title: definition.title,
        content: definition.flavorText.isEmpty
            ? definition.description
            : definition.flavorText,
        messageType: 'event',
      );
    }
    _syncGuideMilestones();
    _updateChallengeProgress();
    _checkSceneBadges();
    _checkMilestones();
    _refreshGuidance();
    return true;
  }

  double _roomEventIdentityScale(
    RoomScene? room,
    SceneEventDefinition definition,
    bool aggressiveChoice,
  ) {
    if (room == null) return 1;
    final stageFactor = 1 + (currentRoomState.currentTransformationStage * 0.025);
    final riskyFactor = aggressiveChoice && room.mechanicEmphasis == RoomMechanicEmphasis.heat
        ? 1.12
        : 1.0;
    final categoryFactor = switch (room.mechanicEmphasis) {
      RoomMechanicEmphasis.tap =>
        definition.category == SceneEventCategory.instant ? 1.08 : 1.0,
      RoomMechanicEmphasis.hybrid =>
        definition.category == SceneEventCategory.shortChoice ? 1.05 : 1.0,
      RoomMechanicEmphasis.combo =>
        definition.category == SceneEventCategory.timedChain ? 1.1 : 1.02,
      RoomMechanicEmphasis.automation =>
        definition.category == SceneEventCategory.utility ? 1.08 : 1.03,
      RoomMechanicEmphasis.signal =>
        definition.category == SceneEventCategory.guideAdvisory ? 1.1 : 1.02,
      RoomMechanicEmphasis.heat =>
        definition.category == SceneEventCategory.warningRisk ? 1.12 : 1.03,
      RoomMechanicEmphasis.maintenance =>
        definition.category == SceneEventCategory.utility ? 1.1 : 1.02,
      RoomMechanicEmphasis.event =>
        definition.category == SceneEventCategory.legendaryAnomaly ? 1.1 : 1.04,
      RoomMechanicEmphasis.temporal =>
        definition.category == SceneEventCategory.hiddenGlitch ? 1.12 : 1.04,
      RoomMechanicEmphasis.synthesis =>
        definition.category == SceneEventCategory.miniBoss ? 1.12 : 1.05,
    };
    return stageFactor * riskyFactor * categoryFactor;
  }

  double _roomTapBuffBias(RoomScene? room, SceneEventDefinition definition) {
    if (room == null) return 1;
    return switch (room.mechanicEmphasis) {
      RoomMechanicEmphasis.tap => 1.22,
      RoomMechanicEmphasis.combo => 1.18,
      RoomMechanicEmphasis.hybrid => 1.08,
      RoomMechanicEmphasis.signal when
          definition.category == SceneEventCategory.guideAdvisory =>
        1.06,
      _ => 1.0,
    };
  }

  double _roomProductionBuffBias(
    RoomScene? room,
    SceneEventDefinition definition,
  ) {
    if (room == null) return 1;
    return switch (room.mechanicEmphasis) {
      RoomMechanicEmphasis.automation => 1.24,
      RoomMechanicEmphasis.maintenance => 1.18,
      RoomMechanicEmphasis.synthesis => 1.14,
      RoomMechanicEmphasis.temporal when
          definition.category == SceneEventCategory.hiddenGlitch =>
        1.12,
      _ => 1.0,
    };
  }

  int _roomComboReward(RoomScene? room, SceneEventDefinition definition) {
    if (room == null) return 0;
    return switch (room.mechanicEmphasis) {
      RoomMechanicEmphasis.combo => 2,
      RoomMechanicEmphasis.tap => 1,
      RoomMechanicEmphasis.event when
          definition.category == SceneEventCategory.timedChain =>
        1,
      _ => 0,
    };
  }

  double _roomCooldownReward(RoomScene? room, SceneEventDefinition definition) {
    if (room == null) return 0;
    return switch (room.mechanicEmphasis) {
      RoomMechanicEmphasis.temporal => 0.8,
      RoomMechanicEmphasis.maintenance => 0.55,
      RoomMechanicEmphasis.signal when
          definition.category == SceneEventCategory.guideAdvisory =>
        0.35,
      _ => 0,
    };
  }

  int _roomFragmentBranchBonus(RoomScene? room, EventRarity rarity) {
    if (room == null || rarity.index < EventRarity.epic.index) return 0;
    return switch (room.mechanicEmphasis) {
      RoomMechanicEmphasis.temporal ||
      RoomMechanicEmphasis.signal ||
      RoomMechanicEmphasis.event =>
        1,
      _ => 0,
    };
  }

  int _roomRouteRewardBonus(RoomScene? room, SceneEventDefinition definition) {
    if (room == null) return 0;
    return switch (room.mechanicEmphasis) {
      RoomMechanicEmphasis.hybrid => 1,
      RoomMechanicEmphasis.signal => 1,
      RoomMechanicEmphasis.event when
          definition.category == SceneEventCategory.legendaryAnomaly =>
        1,
      _ => 0,
    };
  }

  double _roomGuideRewardBonus(RoomScene? room) {
    if (room == null) return 0;
    return switch (room.mechanicEmphasis) {
      RoomMechanicEmphasis.signal => 0.45,
      RoomMechanicEmphasis.event => 0.35,
      RoomMechanicEmphasis.synthesis => 0.2,
      _ => 0.0,
    };
  }

  /// Build a short, human-readable reward summary for the event result banner.
  /// Returns the primary effect (the one most impactful to the player).
  String _buildEventRewardSummary({
    required SceneEventDefinition definition,
    required List<SceneEventReward> rewards,
    required double rewardScale,
  }) {
    if (rewards.isEmpty) return definition.title;

    // Find the most significant reward type in order of player impact.
    for (final reward in rewards) {
      switch (reward.type) {
        case EventRewardType.instantCurrency:
          // Estimate from reward.value and rewardScale (same formula used when resolving)
          final est = math.max(
            reward.value * 12,
            productionPerSecond.toDouble() * (0.45 + reward.value * 0.11),
          ) * rewardScale;
          final display = est >= 1e9
              ? '${(est / 1e9).toStringAsFixed(1)}B'
              : est >= 1e6
                  ? '${(est / 1e6).toStringAsFixed(1)}M'
                  : est >= 1e3
                      ? '${(est / 1e3).toStringAsFixed(1)}K'
                      : est.round().toString();
          return '+$display coins';
        case EventRewardType.temporaryBuff:
          return 'Tap & production boosted';
        case EventRewardType.comboAmplification:
          return '+${reward.value.round()} combo';
        case EventRewardType.cooldownChange:
          return 'Ability cooldowns reduced';
        case EventRewardType.relicFragment:
          return 'Relic fragment discovered';
        case EventRewardType.secretClue:
          return 'Secret clue advanced';
        case EventRewardType.hiddenBranchProgress:
          return 'Hidden branch unlocked';
        case EventRewardType.routeReward:
          return 'Route progress gained';
        case EventRewardType.rareResource:
          return 'Rare resource acquired';
        case EventRewardType.guideAffinity:
          return 'Guide trust increased';
        case EventRewardType.codexEntry:
          return 'Codex entry added';
        case EventRewardType.environmentTrigger:
          return 'Transformation triggered!';
      }
    }
    return definition.title;
  }

  GameState _applyRoomEventIdentityBonus(
    GameState state, {
    required RoomScene? room,
    required SceneEventDefinition definition,
    required double rewardScale,
    required bool aggressiveChoice,
    required EventRarity rarity,
  }) {
    if (room == null) return state;
    return switch (room.mechanicEmphasis) {
      RoomMechanicEmphasis.tap => state.copyWith(
          tapCombo: state.tapCombo + 1,
          strongestCombo: math.max(state.strongestCombo, state.tapCombo + 1),
        ),
      RoomMechanicEmphasis.hybrid => state.copyWith(
          purchaseMomentum: (state.purchaseMomentum + 0.75).clamp(0, 12),
          automationCharge: (state.automationCharge + 5).clamp(0, 100),
        ),
      RoomMechanicEmphasis.combo => state.copyWith(
          tapCombo: state.tapCombo + 2,
          strongestCombo: math.max(state.strongestCombo, state.tapCombo + 2),
        ),
      RoomMechanicEmphasis.automation => state.copyWith(
          automationCharge: (state.automationCharge + 8).clamp(0, 100),
          productionMultiplier: state.productionMultiplier *
              GameNumber.fromDouble(1 + rewardScale * 0.006),
        ),
      RoomMechanicEmphasis.signal => state.copyWith(
          missedEventCharges: math.min(5, state.missedEventCharges + 1),
          guideAffinity: state.guideAffinity + 0.25,
        ),
      RoomMechanicEmphasis.heat => state.copyWith(
          purchaseMomentum:
              (state.purchaseMomentum + (aggressiveChoice ? 1.2 : 0.45))
                  .clamp(0, 12),
          coins: aggressiveChoice
              ? state.coins +
                  GameNumber.fromDouble(
                    productionPerSecond.toDouble() * 0.06 * rewardScale,
                  )
              : state.coins,
          totalCoinsEarned: aggressiveChoice
              ? state.totalCoinsEarned +
                  GameNumber.fromDouble(
                    productionPerSecond.toDouble() * 0.06 * rewardScale,
                  )
              : state.totalCoinsEarned,
        ),
      RoomMechanicEmphasis.maintenance => state.copyWith(
          missedEventCharges: math.min(5, state.missedEventCharges + 1),
          purchaseMomentum: (state.purchaseMomentum + 0.4).clamp(0, 12),
        ),
      RoomMechanicEmphasis.event => state.copyWith(
          currentEventChain: state.currentEventChain + 1,
          bestEventChain:
              math.max(state.bestEventChain, state.currentEventChain + 1),
          missedEventCharges:
              math.min(5, state.missedEventCharges + (rarity.index >= EventRarity.rare.index ? 1 : 0)),
        ),
      RoomMechanicEmphasis.temporal => state.copyWith(
          branchRespecTokens: state.branchRespecTokens +
              (definition.category == SceneEventCategory.hiddenGlitch ? 1 : 0),
          abilities: state.abilities.map(
            (key, value) => MapEntry(
              key,
              value.copyWith(
                cooldownRemaining:
                    math.max(0, value.cooldownRemaining - 0.5),
              ),
            ),
          ),
        ),
      RoomMechanicEmphasis.synthesis => state.copyWith(
          tapMultiplier:
              state.tapMultiplier * GameNumber.fromDouble(1 + rewardScale * 0.004),
          productionMultiplier: state.productionMultiplier *
              GameNumber.fromDouble(1 + rewardScale * 0.005),
        ),
    };
  }

  void _discoverFirstHiddenRoomSecret() {
    final room = currentRoom;
    if (room == null) return;
    for (final secret in room.secrets) {
      if (!currentRoomState.secretsDiscovered.contains(secret.id)) {
        discoverRoomSecret(secret.id);
        return;
      }
    }
  }

  GameEventType _eventTypeForSceneEvent(SceneEventCategory category) {
    return switch (category) {
      SceneEventCategory.instant => GameEventType.powerSurge,
      SceneEventCategory.shortChoice => GameEventType.aiIdea,
      SceneEventCategory.timedChain => GameEventType.marketSpike,
      SceneEventCategory.utility => GameEventType.hardwareMalfunction,
      SceneEventCategory.secretTrigger => GameEventType.mysteryCache,
      SceneEventCategory.legendaryAnomaly => GameEventType.breachFragment,
      SceneEventCategory.warningRisk => GameEventType.hardwareMalfunction,
      SceneEventCategory.miniBoss => GameEventType.breachFragment,
      SceneEventCategory.guideAdvisory => GameEventType.aiIdea,
      SceneEventCategory.hiddenGlitch => GameEventType.dataCorruption,
    };
  }

  EventRarity _eventRarityFromScene(String rarity) {
    return switch (rarity) {
      'legendary' => EventRarity.legendary,
      'corrupted' => EventRarity.corrupted,
      'epic' => EventRarity.epic,
      'rare' => EventRarity.rare,
      _ => EventRarity.common,
    };
  }

  int _sceneEventRarityRank(String rarity) {
    return _eventRarityFromScene(rarity).index;
  }

  void _recordSceneEventArchive(SceneEventDefinition definition) {
    _state = _state.copyWith(
      codex: _upsertCodexEntry(
        _state.codex,
        CodexEntry(
          id: 'event_${definition.id}',
          title: definition.title,
          content:
              '${definition.description}\n\n${definition.flavorText}'.trim(),
          type: CodexEntryType.eventArchive,
          category: definition.category.name,
          roomId: definition.roomId,
          discovered: true,
          icon: 'event',
          rarity: definition.rarity,
        ),
      ),
    );
  }

  MetaProgressionState _awardEventFragment(
    SceneEventDefinition definition,
    SceneEventReward reward,
    MetaProgressionState meta,
  ) {
    final shardId = 'fragment_${definition.id}';
    if (meta.blueprintShards.any((item) => item.id == shardId)) {
      return meta;
    }
    return meta.copyWith(
      blueprintShards: [
        ...meta.blueprintShards,
        BlueprintShard(
          id: shardId,
          name: definition.title,
          description: reward.description,
          roomId: definition.roomId,
          category: definition.category.name,
          shardsRequired: 1,
          shardsCollected: 1,
          completed: true,
        ),
      ],
    );
  }

  ChallengeState? _challengeByPeriod(ChallengePeriod period) {
    for (final challenge in _state.challenges) {
      if (challenge.period == period) return challenge;
    }
    return null;
  }

  MetaProgressionState _awardRoomCompletionMeta(
    RoomScene room,
    MetaProgressionState meta,
  ) {
    final relicId = 'relic_${room.id}';
    final heirloomId = 'heirloom_${room.id}';
    final memoryId = 'memory_${room.id}';
    return meta.copyWith(
      relics: meta.relics.any((item) => item.id == relicId)
          ? meta.relics
          : [
              ...meta.relics,
              Relic(
                id: relicId,
                name: '${room.name} Relic',
                description: room.subtitle,
                rarity: room.order >= 15
                    ? RelicRarity.legendary
                    : room.order >= 10
                        ? RelicRarity.epic
                        : room.order >= 5
                            ? RelicRarity.rare
                            : RelicRarity.uncommon,
                effects: [
                  RelicEffect(
                    effectType: room.mechanicEmphasis.name,
                    targetSystem: room.currency,
                    magnitude: 0.02 + (room.order * 0.003),
                    description:
                        'Improves ${room.currency.toLowerCase()} efficiency in future runs.',
                  ),
                ],
                acquired: true,
                sourceDescription: 'Awarded for completing ${room.name}.',
              ),
            ],
      memoryFragments: meta.memoryFragments.any((item) => item.id == memoryId)
          ? meta.memoryFragments
          : [
              ...meta.memoryFragments,
              MemoryFragment(
                id: memoryId,
                title: '${room.name} Memory',
                content: room.completionText,
                sourceRoomId: room.id,
                sourceType: 'room_completion',
                acquiredAt: _timeProvider.now(),
                acquired: true,
              ),
            ],
      sceneHeirlooms: meta.sceneHeirlooms.any((item) => item.id == heirloomId)
          ? meta.sceneHeirlooms
          : [
              ...meta.sceneHeirlooms,
              SceneHeirloom(
                id: heirloomId,
                roomId: room.id,
                name: '${room.name} Heirloom',
                description: room.guideIntroLine,
                effectDescription:
                    'Carries the solved patterns of ${room.name} into later rooms.',
                unlocked: true,
              ),
            ],
    );
  }

  MetaProgressionState _awardSecretMeta(
    RoomScene room,
    RoomSecret secret,
    MetaProgressionState meta,
  ) {
    final memoryId = 'secret_memory_${secret.id}';
    final shardId = 'secret_shard_${secret.id}';
    return meta.copyWith(
      memoryFragments: meta.memoryFragments.any((item) => item.id == memoryId)
          ? meta.memoryFragments
          : [
              ...meta.memoryFragments,
              MemoryFragment(
                id: memoryId,
                title: secret.title,
                content: secret.description,
                sourceRoomId: room.id,
                sourceType: 'secret',
                acquiredAt: _timeProvider.now(),
                acquired: true,
              ),
            ],
      blueprintShards: meta.blueprintShards.any((item) => item.id == shardId)
          ? meta.blueprintShards
          : [
              ...meta.blueprintShards,
              BlueprintShard(
                id: shardId,
                name: secret.title,
                description: secret.rewardType,
                roomId: room.id,
                category: 'secret',
                shardsRequired: 1,
                shardsCollected: 1,
                completed: true,
              ),
            ],
    );
  }

  MetaProgressionState _awardChallengeBlueprint(
    ChallengeState challenge,
    MetaProgressionState meta,
  ) {
    final shardId = 'challenge_${challenge.id}';
    if (meta.blueprintShards.any((item) => item.id == shardId)) {
      return meta;
    }
    return meta.copyWith(
      blueprintShards: [
        ...meta.blueprintShards,
        BlueprintShard(
          id: shardId,
          name: challenge.title,
          description: challenge.description,
          roomId: _state.currentRoomId,
          category: 'challenge',
          shardsRequired: 1,
          shardsCollected: 1,
          completed: true,
        ),
      ],
    );
  }

  CodexState _recordRoomCompletionArchives(RoomScene room, CodexState codex) {
    return _upsertCodexEntry(
      codex,
      CodexEntry(
        id: 'relic_${room.id}',
        title: '${room.name} Completion Relic',
        content:
            '${room.completionText}\n\nHeirloom effect: Carries ${room.currency} mastery into future runs.',
        type: CodexEntryType.relicArchive,
        category: room.mechanicEmphasis.name,
        roomId: room.id,
        discovered: true,
        icon: 'relic',
        rarity: room.order >= 10 ? 'epic' : 'rare',
      ),
    );
  }

  CodexState _recordSecretRewardArchive(
    RoomScene room,
    RoomSecret secret,
    CodexState codex,
  ) {
    return _upsertCodexEntry(
      codex,
      CodexEntry(
        id: 'secret_reward_${secret.id}',
        title: secret.title,
        content:
            '${secret.description}\n\nHint: ${secret.hint}\nReward: ${secret.rewardType} ${secret.rewardValue}',
        type: CodexEntryType.secretArchive,
        category: secret.clueSource,
        roomId: room.id,
        discovered: true,
        icon: 'secret',
        rarity: 'rare',
      ),
    );
  }

  CodexState _recordChallengeArchive(
    ChallengeState challenge,
    CodexState codex,
  ) {
    return _upsertCodexEntry(
      codex,
      CodexEntry(
        id: 'challenge_${challenge.id}',
        title: challenge.title,
        content:
            '${challenge.description}\n\nSeason: ${challenge.seasonKey}\nTarget: ${challenge.target.toStringAsFixed(0)}',
        type: CodexEntryType.challengeArchive,
        category: challenge.period.name,
        roomId: _state.currentRoomId,
        discovered: true,
        icon: 'challenge',
        rarity: challenge.period == ChallengePeriod.weekly ? 'epic' : 'uncommon',
      ),
    );
  }

  void _recordTransformationArchive(
    RoomScene room,
    TransformationStage stage,
    int stageIndex,
  ) {
    _state = _state.copyWith(
      codex: _upsertCodexEntry(
        _state.codex,
        CodexEntry(
          id: 'transform_${room.id}_$stageIndex',
          title: stage.name,
          content:
              '${stage.description}\n\n${stage.environmentChanges.join('\n')}',
          type: CodexEntryType.transformationArchive,
          category: room.mechanicEmphasis.name,
          roomId: room.id,
          discovered: true,
          icon: 'transform',
          rarity: stageIndex >= 3 ? 'epic' : 'uncommon',
        ),
      ),
    );
  }

  void _recordTwistArchive(RoomScene room) {
    final twist = room.midSceneTwist;
    if (twist == null) return;
    _state = _state.copyWith(
      codex: _upsertCodexEntry(
        _state.codex,
        CodexEntry(
          id: 'twist_${room.id}',
          title: twist.title,
          content: '${twist.description}\n\n${twist.effectDescription}',
          type: CodexEntryType.transformationArchive,
          category: 'twist',
          roomId: room.id,
          discovered: true,
          icon: 'twist',
          rarity: 'epic',
        ),
      ),
    );
  }

  CodexState _upsertCodexEntry(CodexState codex, CodexEntry entry) {
    final entries = List<CodexEntry>.from(codex.entries);
    final index = entries.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    return codex.copyWith(entries: entries);
  }

  void _syncRouteArchive({
    String? branchId,
    String? completedRoomId,
  }) {
    final codex = _state.codex;
    final branches = <String>{
      ..._state.chosenBranches,
      if (branchId != null) branchId,
    }.toList()
      ..sort();
    final routeId = _state.routeSignature.isEmpty ? 'unassigned' : _state.routeSignature;
    final archive = List<RouteArchiveEntry>.from(codex.routeArchive);
    final index = archive.indexWhere((item) => item.routeId == routeId);
    final roomsVisited = <String>{
      _state.currentRoomId,
      if (completedRoomId != null) completedRoomId,
      if (index >= 0) ...archive[index].roomsVisited,
    }.toList()
      ..sort();
    final title = branches.isEmpty ? 'Unaligned Route' : '${branches.join(' / ')} Route';
    final entry = RouteArchiveEntry(
      id: 'route_$routeId',
      routeId: routeId,
      title: title,
      description: 'A long-form record of how this intelligence was shaped.',
      roomsVisited: roomsVisited,
      branchesChosen: branches,
      completionPercentage: totalRooms <= 0
          ? 0
          : (roomsVisited.length / totalRooms) * 100,
      endingReached: roomsCompleted >= totalRooms ? 'room_mastery' : null,
    );
    if (index >= 0) {
      archive[index] = entry;
    } else {
      archive.add(entry);
    }
    _state = _state.copyWith(codex: codex.copyWith(routeArchive: archive));
  }

  void _syncGuideMilestones() {
    final reached = <String>{..._state.metaProgression.guideMilestones};
    var meta = _state.metaProgression;
    var codex = _state.codex;
    var changed = false;
    for (var tier = 2; tier <= guideTier; tier++) {
      final id = 'guide_tier_$tier';
      if (reached.contains(id)) continue;
      reached.add(id);
      changed = true;
      final fragmentId = 'guide_fragment_$tier';
      meta = meta.copyWith(
        guideMilestones: reached,
        memoryFragments: meta.memoryFragments.any((item) => item.id == fragmentId)
            ? meta.memoryFragments
            : [
                ...meta.memoryFragments,
                MemoryFragment(
                  id: fragmentId,
                  title: 'Guide Tier $tier',
                  content:
                      'The guide reached a new level of trust and opened deeper analysis.',
                  sourceRoomId: _state.currentRoomId,
                  sourceType: 'guide',
                  acquiredAt: _timeProvider.now(),
                  acquired: true,
                ),
              ],
      );
      codex = _upsertCodexEntry(
        codex,
        CodexEntry(
          id: id,
          title: 'Guide Tier $tier',
          content:
              'Trust increased to tier $tier. The guide now offers deeper hints and stronger archival insight.',
          type: CodexEntryType.guideMemo,
          category: 'guide',
          roomId: _state.currentRoomId,
          discovered: true,
          icon: 'guide',
          rarity: tier >= 4 ? 'epic' : 'uncommon',
        ),
      );
    }
    if (changed) {
      _state = _state.copyWith(metaProgression: meta, codex: codex);
    }
  }

  void _pushNarrativeBeat({
    required String id,
    required String title,
    required String body,
  }) {
    if (_state.narrativeQueue.any((item) => item.id == id)) return;
    _state = _state.copyWith(
      narrativeQueue: [
        ..._state.narrativeQueue,
        NarrativeBeat(id: id, title: title, body: body),
      ],
    );
  }

  Map<String, double> _bumpTendency(
    Map<String, double> source,
    String key,
    double amount,
  ) {
    final map = Map<String, double>.from(source);
    map[key] = (map[key] ?? 0) + amount;
    return map;
  }

  String get _branchingMilestoneId => 'branching';

  double _questTarget(QuestDefinition definition) {
    if (definition.targetMultiplier != null) {
      final scaled = _progressMetricValue(definition.metric) *
          definition.targetMultiplier!;
      return math.max(definition.minimumTarget, scaled.roundToDouble());
    }
    return math.max(definition.minimumTarget, definition.target);
  }

  String _challengeSeasonKey(ChallengePeriod period) {
    final now = _timeProvider.now().toUtc();
    return switch (period) {
      ChallengePeriod.daily =>
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      ChallengePeriod.weekly => _weeklyKey(now),
    };
  }

  double _progressMetricValue(ProgressMetric metric) {
    return switch (metric) {
      ProgressMetric.totalCoins => _state.totalCoinsEarned.toDouble(),
      ProgressMetric.totalGenerators => _state.totalGeneratorsPurchased.toDouble(),
      ProgressMetric.strongestCombo => _state.strongestCombo.toDouble(),
      ProgressMetric.eventClicks => _state.totalEventsClicked.toDouble(),
      ProgressMetric.totalTaps => _state.totalTaps.toDouble(),
      ProgressMetric.riskyChoices => _state.riskyChoicesTaken.toDouble(),
    };
  }

  double _challengeStartValue(ChallengeMetric metric) {
    return switch (metric) {
      ChallengeMetric.totalTaps ||
      ChallengeMetric.eventClicks ||
      ChallengeMetric.upgradesBought ||
      ChallengeMetric.riskyChoices ||
      ChallengeMetric.roomSecretsFound ||
      ChallengeMetric.roomTransformations =>
        _challengeMetricValue(metric),
      ChallengeMetric.bestEventChain ||
      ChallengeMetric.combo ||
      ChallengeMetric.productionBurst =>
        0,
    };
  }

  double _challengeProgressValue(ChallengeState challenge) {
    final current = _challengeMetricValue(challenge.metric);
    final measured = switch (challenge.metric) {
      ChallengeMetric.totalTaps ||
      ChallengeMetric.eventClicks ||
      ChallengeMetric.upgradesBought ||
      ChallengeMetric.riskyChoices ||
      ChallengeMetric.roomSecretsFound ||
      ChallengeMetric.roomTransformations =>
        current - challenge.startValue,
      ChallengeMetric.bestEventChain ||
      ChallengeMetric.combo ||
      ChallengeMetric.productionBurst =>
        current,
    };
    return math.max(challenge.progress, measured);
  }

  double _scaledChallengeTarget(ChallengeTemplateDefinition template) {
    if (template.metric != ChallengeMetric.productionBurst) {
      return template.target;
    }
    final baseline = math.max(
      template.target,
      productionPerSecond.toDouble() * (template.period == ChallengePeriod.weekly ? 1.8 : 1.35),
    );
    return baseline.ceilToDouble();
  }

  double _rarityRewardMultiplier(EventRarity rarity) {
    return switch (rarity) {
      EventRarity.common => 1,
      EventRarity.uncommon => 1.08,
      EventRarity.rare => 1.18,
      EventRarity.epic => 1.42,
      EventRarity.corrupted => 1.8,
      EventRarity.legendary => 2.35,
    };
  }

  void _pushNarrativeForTrigger({
    required String triggerKey,
    required String fallbackId,
    required String fallbackTitle,
    required String fallbackBody,
  }) {
    final definition = _config.narrativeByTrigger(triggerKey);
    _pushNarrativeBeat(
      id: definition?.id ?? fallbackId,
      title: definition?.title ?? fallbackTitle,
      body: definition?.body ?? fallbackBody,
    );
  }

  bool _sameChallengeSet(
    List<ChallengeState> a,
    List<ChallengeState> b,
  ) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index].id != b[index].id ||
          a[index].seasonKey != b[index].seasonKey ||
          a[index].period != b[index].period) {
        return false;
      }
    }
    return true;
  }

  String _createPresetId(String name) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final suffix = _state.loadoutPresets.length + 1;
    return 'preset_${base.isEmpty ? 'custom' : base}_$suffix';
  }

  String _weeklyKey(DateTime date) {
    final weekday = date.weekday == DateTime.sunday ? 7 : date.weekday;
    final thursday = date.add(Duration(days: 4 - weekday));
    final firstThursday = DateTime.utc(thursday.year, 1, 4);
    final firstWeekday =
        firstThursday.weekday == DateTime.sunday ? 7 : firstThursday.weekday;
    final firstWeekStart =
        firstThursday.subtract(Duration(days: firstWeekday - 1));
    final weekNumber =
        ((thursday.difference(firstWeekStart).inDays) / 7).floor() + 1;
    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
}
