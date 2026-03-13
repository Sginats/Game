import 'dart:math' as math;

import '../../core/math/game_number.dart';
import '../../core/time/time_provider.dart';
import '../../data/repositories/game_repository.dart';
import '../../domain/mechanics/cost_calculator.dart';
import '../../domain/mechanics/offline_progression.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/era.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/gameplay_extensions.dart';
import '../../domain/models/progression_content.dart';
import '../../domain/models/generator.dart';
import '../../domain/models/upgrade.dart';
import '../../domain/systems/achievement_system.dart';
import '../../domain/systems/generator_system.dart';
import '../../domain/systems/prestige_system.dart';
import '../../domain/systems/tap_system.dart';
import '../../domain/systems/upgrade_system.dart';
import '../services/config_service.dart';

/// Main game controller that orchestrates all game logic.
/// Pure Dart — no Flutter imports.
class GameController {
  static const bool _eventsEnabled = true;

  final ConfigService _config;
  final TimeProvider _timeProvider;
  final GameRepository? _repository;
  final math.Random _random;
  GameState _state;
  double _autoSaveAccumulator = 0;
  double _eventAccumulator = 0;
  Future<void>? _saveFuture;

  List<AchievementDefinition> lastUnlockedAchievements = [];
  List<String> lastUnlockedMilestones = [];
  GameNumber? pendingOfflineEarnings;
  ReturnSummary? pendingReturnSummary;
  GameNumber lastTapGain = const GameNumber.zero();
  bool lastTapWasCritical = false;
  String? lastRecommendation;
  String? lastAiLine;

  GameController({
    required ConfigService config,
    required TimeProvider timeProvider,
    GameState? initialState,
    GameRepository? repository,
    math.Random? random,
  })  : _config = config,
        _timeProvider = timeProvider,
        _repository = repository,
        _random = random ?? math.Random(),
        _state = initialState ?? GameState.initial() {
    _checkEraUnlocks();
    _checkSceneBadges();
    _ensureQuest();
    _ensureChallenges();
    _refreshGuidance();
  }

  GameState get state => _state;
  ConfigService get config => _config;
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
    var tapped = TapSystem.processTap(
      _state,
      _config.baseTapValue,
      now: _timeProvider.now(),
    );
    var gain = tapped.coins - before;

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
    return true;
  }

  bool purchaseUpgrade(String upgradeId, {int quantity = 1}) {
    if (quantity <= 0) return false;
    final definition = _config.upgrades[upgradeId];
    if (definition == null) return false;

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
    _updateQuestProgress();
    _checkEraUnlocks();
    _checkSceneBadges();
    _checkMilestones();
    _checkAchievements();
    _refreshGuidance();
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
    _refreshGuidance();
    return true;
  }

  bool setCurrentEra(String eraId) {
    if (!_state.unlockedEras.contains(eraId)) return false;
    if (_state.currentEraId == eraId) return true;
    _state = _state.copyWith(currentEraId: eraId);
    _refreshGuidance();
    return true;
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
    _state = _state.copyWith(
      coins: _state.coins + reward,
      totalCoinsEarned: _state.totalCoinsEarned + reward,
      guideAffinity: _state.guideAffinity + 1.2,
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
    _refreshGuidance();
    return true;
  }

  bool dismissActiveEvent() {
    final event = _state.activeEvent;
    if (event == null) return false;
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
    _checkEraUnlocks();
    _checkSceneBadges();
    _ensureQuest();
    _ensureChallenges();
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
    _state = saved.copyWith(activeEvent: null);
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
    _refreshGuidance();
    return true;
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

  ChallengeState? _challengeByPeriod(ChallengePeriod period) {
    for (final challenge in _state.challenges) {
      if (challenge.period == period) return challenge;
    }
    return null;
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
      ChallengeMetric.riskyChoices =>
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
      ChallengeMetric.riskyChoices =>
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
