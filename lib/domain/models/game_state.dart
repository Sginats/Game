import '../../core/math/game_number.dart';
import 'codex.dart';
import 'companion.dart';
import 'gameplay_extensions.dart';
import 'generator.dart';
import 'meta_progression.dart';
import 'room_scene.dart';
import 'route_faction.dart';
import 'side_activity.dart';
import 'upgrade.dart';

/// Complete game state — immutable, updated via [copyWith].
class GameState {
  static const int currentEconomyRevision = 2;

  final GameNumber coins;
  final GameNumber totalCoinsEarned;
  final GameNumber tapMultiplier;
  final GameNumber productionMultiplier;
  final Map<String, GeneratorState> generators;
  final Map<String, UpgradeState> upgrades;
  final Set<String> unlockedEras;
  final String currentEraId;
  final DateTime lastSaveTime;
  final int totalTaps;
  final int prestigeCount;
  final GameNumber prestigeMultiplier;
  final Set<String> unlockedAchievements;
  final bool tutorialComplete;
  final int tapCombo;
  final DateTime? lastTapTime;
  final int strongestCombo;
  final int totalUpgradesPurchased;
  final int totalGeneratorsPurchased;
  final int totalCriticalClicks;
  final double totalPlaySeconds;
  final double totalOfflineSeconds;
  final double automationCharge;
  final double purchaseMomentum;
  final Set<String> unlockedMilestones;
  final Set<String> discoveredSecrets;
  final Set<String> chosenBranches;
  final Map<String, ActiveAbilityState> abilities;
  final GameEventState? activeEvent;
  final QuestState? activeQuest;
  final Map<String, double> playstyleTendencies;
  final List<ChallengeState> challenges;
  final List<NarrativeBeat> narrativeQueue;
  final List<GameplayMutatorState> activeMutators;
  final List<LoadoutPreset> loadoutPresets;
  final int eventPityCounter;
  final int totalEventsSpawned;
  final int totalEventsClicked;
  final int rareEventsFound;
  final int bestEventChain;
  final int currentEventChain;
  final int totalEventsMissed;
  final int riskyChoicesTaken;
  final int challengeRerollsRemaining;
  final int branchRespecTokens;
  final String currentSeasonKey;
  final String routeSignature;
  final int missedEventCharges;
  final Set<String> seenEventTemplates;
  final Set<String> completedSceneBadges;
  final double guideAffinity;
  final int economyRevision;
  final MetaProgressionState metaProgression;
  final CodexState codex;
  final String currentRoomId;
  final Map<String, RoomSceneState> roomStates;
  final CompanionSystemState companionSystem;
  final RouteState routeState;
  final SideActivityState sideActivityState;
  final List<QuestState> activeQuests;
  final int roomMasteryRank;
  final Map<String, int> sceneMasteryRanks;

  GameState({
    required this.coins,
    required this.totalCoinsEarned,
    required this.tapMultiplier,
    required this.productionMultiplier,
    required this.generators,
    required this.upgrades,
    required this.unlockedEras,
    required this.currentEraId,
    required this.lastSaveTime,
    this.totalTaps = 0,
    this.prestigeCount = 0,
    GameNumber? prestigeMultiplier,
    this.unlockedAchievements = const {},
    this.tutorialComplete = false,
    this.tapCombo = 0,
    this.lastTapTime,
    this.strongestCombo = 0,
    this.totalUpgradesPurchased = 0,
    this.totalGeneratorsPurchased = 0,
    this.totalCriticalClicks = 0,
    this.totalPlaySeconds = 0,
    this.totalOfflineSeconds = 0,
    this.automationCharge = 0,
    this.purchaseMomentum = 0,
    this.unlockedMilestones = const {},
    this.discoveredSecrets = const {},
    this.chosenBranches = const {},
    this.abilities = const {},
    this.activeEvent,
    this.activeQuest,
    this.playstyleTendencies = const {},
    this.challenges = const [],
    this.narrativeQueue = const [],
    this.activeMutators = const [],
    this.loadoutPresets = const [],
    this.eventPityCounter = 0,
    this.totalEventsSpawned = 0,
    this.totalEventsClicked = 0,
    this.rareEventsFound = 0,
    this.bestEventChain = 0,
    this.currentEventChain = 0,
    this.totalEventsMissed = 0,
    this.riskyChoicesTaken = 0,
    this.challengeRerollsRemaining = 2,
    this.branchRespecTokens = 1,
    this.currentSeasonKey = 'season_alpha',
    this.routeSignature = 'fresh',
    this.missedEventCharges = 0,
    this.seenEventTemplates = const {},
    this.completedSceneBadges = const {},
    this.guideAffinity = 0,
    this.economyRevision = currentEconomyRevision,
    this.metaProgression = const MetaProgressionState(),
    this.codex = const CodexState(),
    this.currentRoomId = 'room_01',
    this.roomStates = const {},
    this.companionSystem = const CompanionSystemState(),
    this.routeState = const RouteState(),
    this.sideActivityState = const SideActivityState(),
    this.activeQuests = const [],
    this.roomMasteryRank = 0,
    this.sceneMasteryRanks = const {},
  }) : prestigeMultiplier =
            prestigeMultiplier ?? GameNumber.fromDouble(1);

  /// Factory for a fresh new-game state.
  factory GameState.initial() {
    return GameState(
      coins: const GameNumber.zero(),
      totalCoinsEarned: const GameNumber.zero(),
      tapMultiplier: GameNumber.fromDouble(1),
      productionMultiplier: GameNumber.fromDouble(1),
      generators: const {},
      upgrades: const {},
      unlockedEras: const {'era_1'},
      currentEraId: 'era_1',
      lastSaveTime: DateTime.now(),
      abilities: {
        for (final ability in ActiveAbilityType.values)
          ability.name: ActiveAbilityState(
            type: ability,
            unlocked: ability == ActiveAbilityType.overclock ||
                ability == ActiveAbilityType.focus,
          ),
      },
      playstyleTendencies: const {
        'active': 0,
        'passive': 0,
        'risky': 0,
        'efficient': 0,
        'event_hunter': 0,
      },
      guideAffinity: 2,
      loadoutPresets: const [
        LoadoutPreset(id: 'preset_tap', name: 'Tap Bias', preferredBranches: {'tap'}),
        LoadoutPreset(
          id: 'preset_auto',
          name: 'Auto Bias',
          preferredBranches: {'automation'},
        ),
      ],
    );
  }

  GameState copyWith({
    GameNumber? coins,
    GameNumber? totalCoinsEarned,
    GameNumber? tapMultiplier,
    GameNumber? productionMultiplier,
    Map<String, GeneratorState>? generators,
    Map<String, UpgradeState>? upgrades,
    Set<String>? unlockedEras,
    String? currentEraId,
    DateTime? lastSaveTime,
    int? totalTaps,
    int? prestigeCount,
    GameNumber? prestigeMultiplier,
    Set<String>? unlockedAchievements,
    bool? tutorialComplete,
    int? tapCombo,
    DateTime? lastTapTime,
    int? strongestCombo,
    int? totalUpgradesPurchased,
    int? totalGeneratorsPurchased,
    int? totalCriticalClicks,
    double? totalPlaySeconds,
    double? totalOfflineSeconds,
    double? automationCharge,
    double? purchaseMomentum,
    Set<String>? unlockedMilestones,
    Set<String>? discoveredSecrets,
    Set<String>? chosenBranches,
    Map<String, ActiveAbilityState>? abilities,
    GameEventState? activeEvent,
    QuestState? activeQuest,
    Map<String, double>? playstyleTendencies,
    List<ChallengeState>? challenges,
    List<NarrativeBeat>? narrativeQueue,
    List<GameplayMutatorState>? activeMutators,
    List<LoadoutPreset>? loadoutPresets,
    int? eventPityCounter,
    int? totalEventsSpawned,
    int? totalEventsClicked,
    int? rareEventsFound,
    int? bestEventChain,
    int? currentEventChain,
    int? totalEventsMissed,
    int? riskyChoicesTaken,
    int? challengeRerollsRemaining,
    int? branchRespecTokens,
    String? currentSeasonKey,
    String? routeSignature,
    int? missedEventCharges,
    Set<String>? seenEventTemplates,
    Set<String>? completedSceneBadges,
    double? guideAffinity,
    int? economyRevision,
    MetaProgressionState? metaProgression,
    CodexState? codex,
    String? currentRoomId,
    Map<String, RoomSceneState>? roomStates,
    CompanionSystemState? companionSystem,
    RouteState? routeState,
    SideActivityState? sideActivityState,
    List<QuestState>? activeQuests,
    int? roomMasteryRank,
    Map<String, int>? sceneMasteryRanks,
  }) {
    return GameState(
      coins: coins ?? this.coins,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      tapMultiplier: tapMultiplier ?? this.tapMultiplier,
      productionMultiplier: productionMultiplier ?? this.productionMultiplier,
      generators: generators ?? this.generators,
      upgrades: upgrades ?? this.upgrades,
      unlockedEras: unlockedEras ?? this.unlockedEras,
      currentEraId: currentEraId ?? this.currentEraId,
      lastSaveTime: lastSaveTime ?? this.lastSaveTime,
      totalTaps: totalTaps ?? this.totalTaps,
      prestigeCount: prestigeCount ?? this.prestigeCount,
      prestigeMultiplier: prestigeMultiplier ?? this.prestigeMultiplier,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      tutorialComplete: tutorialComplete ?? this.tutorialComplete,
      tapCombo: tapCombo ?? this.tapCombo,
      lastTapTime: lastTapTime ?? this.lastTapTime,
      strongestCombo: strongestCombo ?? this.strongestCombo,
      totalUpgradesPurchased:
          totalUpgradesPurchased ?? this.totalUpgradesPurchased,
      totalGeneratorsPurchased:
          totalGeneratorsPurchased ?? this.totalGeneratorsPurchased,
      totalCriticalClicks: totalCriticalClicks ?? this.totalCriticalClicks,
      totalPlaySeconds: totalPlaySeconds ?? this.totalPlaySeconds,
      totalOfflineSeconds: totalOfflineSeconds ?? this.totalOfflineSeconds,
      automationCharge: automationCharge ?? this.automationCharge,
      purchaseMomentum: purchaseMomentum ?? this.purchaseMomentum,
      unlockedMilestones: unlockedMilestones ?? this.unlockedMilestones,
      discoveredSecrets: discoveredSecrets ?? this.discoveredSecrets,
      chosenBranches: chosenBranches ?? this.chosenBranches,
      abilities: abilities ?? this.abilities,
      activeEvent: activeEvent ?? this.activeEvent,
      activeQuest: activeQuest ?? this.activeQuest,
      playstyleTendencies:
          playstyleTendencies ?? this.playstyleTendencies,
      challenges: challenges ?? this.challenges,
      narrativeQueue: narrativeQueue ?? this.narrativeQueue,
      activeMutators: activeMutators ?? this.activeMutators,
      loadoutPresets: loadoutPresets ?? this.loadoutPresets,
      eventPityCounter: eventPityCounter ?? this.eventPityCounter,
      totalEventsSpawned: totalEventsSpawned ?? this.totalEventsSpawned,
      totalEventsClicked: totalEventsClicked ?? this.totalEventsClicked,
      rareEventsFound: rareEventsFound ?? this.rareEventsFound,
      bestEventChain: bestEventChain ?? this.bestEventChain,
      currentEventChain: currentEventChain ?? this.currentEventChain,
      totalEventsMissed: totalEventsMissed ?? this.totalEventsMissed,
      riskyChoicesTaken: riskyChoicesTaken ?? this.riskyChoicesTaken,
      challengeRerollsRemaining:
          challengeRerollsRemaining ?? this.challengeRerollsRemaining,
      branchRespecTokens: branchRespecTokens ?? this.branchRespecTokens,
      currentSeasonKey: currentSeasonKey ?? this.currentSeasonKey,
      routeSignature: routeSignature ?? this.routeSignature,
      missedEventCharges: missedEventCharges ?? this.missedEventCharges,
      seenEventTemplates: seenEventTemplates ?? this.seenEventTemplates,
      completedSceneBadges: completedSceneBadges ?? this.completedSceneBadges,
      guideAffinity: guideAffinity ?? this.guideAffinity,
      economyRevision: economyRevision ?? this.economyRevision,
      metaProgression: metaProgression ?? this.metaProgression,
      codex: codex ?? this.codex,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      roomStates: roomStates ?? this.roomStates,
      companionSystem: companionSystem ?? this.companionSystem,
      routeState: routeState ?? this.routeState,
      sideActivityState: sideActivityState ?? this.sideActivityState,
      activeQuests: activeQuests ?? this.activeQuests,
      roomMasteryRank: roomMasteryRank ?? this.roomMasteryRank,
      sceneMasteryRanks: sceneMasteryRanks ?? this.sceneMasteryRanks,
    );
  }

  Map<String, dynamic> toJson() => {
        'coins': coins.toJson(),
        'totalCoinsEarned': totalCoinsEarned.toJson(),
        'tapMultiplier': tapMultiplier.toJson(),
        'productionMultiplier': productionMultiplier.toJson(),
        'generators': generators.map((k, v) => MapEntry(k, v.toJson())),
        'upgrades': upgrades.map((k, v) => MapEntry(k, v.toJson())),
        'unlockedEras': unlockedEras.toList(),
        'currentEraId': currentEraId,
        'lastSaveTime': lastSaveTime.toIso8601String(),
        'totalTaps': totalTaps,
        'prestigeCount': prestigeCount,
        'prestigeMultiplier': prestigeMultiplier.toJson(),
        'unlockedAchievements': unlockedAchievements.toList(),
        'tutorialComplete': tutorialComplete,
        'tapCombo': tapCombo,
        'lastTapTime': lastTapTime?.toIso8601String(),
        'strongestCombo': strongestCombo,
        'totalUpgradesPurchased': totalUpgradesPurchased,
        'totalGeneratorsPurchased': totalGeneratorsPurchased,
        'totalCriticalClicks': totalCriticalClicks,
        'totalPlaySeconds': totalPlaySeconds,
        'totalOfflineSeconds': totalOfflineSeconds,
        'automationCharge': automationCharge,
        'purchaseMomentum': purchaseMomentum,
        'unlockedMilestones': unlockedMilestones.toList(),
        'discoveredSecrets': discoveredSecrets.toList(),
        'chosenBranches': chosenBranches.toList(),
        'abilities': abilities.map((k, v) => MapEntry(k, v.toJson())),
        'activeEvent': activeEvent?.toJson(),
        'activeQuest': activeQuest?.toJson(),
        'playstyleTendencies': playstyleTendencies,
        'challenges': challenges.map((item) => item.toJson()).toList(),
        'narrativeQueue': narrativeQueue.map((item) => item.toJson()).toList(),
        'activeMutators': activeMutators.map((item) => item.toJson()).toList(),
        'loadoutPresets': loadoutPresets.map((item) => item.toJson()).toList(),
        'eventPityCounter': eventPityCounter,
        'totalEventsSpawned': totalEventsSpawned,
        'totalEventsClicked': totalEventsClicked,
        'rareEventsFound': rareEventsFound,
        'bestEventChain': bestEventChain,
        'currentEventChain': currentEventChain,
        'totalEventsMissed': totalEventsMissed,
        'riskyChoicesTaken': riskyChoicesTaken,
        'challengeRerollsRemaining': challengeRerollsRemaining,
        'branchRespecTokens': branchRespecTokens,
        'currentSeasonKey': currentSeasonKey,
        'routeSignature': routeSignature,
        'missedEventCharges': missedEventCharges,
        'seenEventTemplates': seenEventTemplates.toList(),
        'completedSceneBadges': completedSceneBadges.toList(),
        'guideAffinity': guideAffinity,
        'economyRevision': economyRevision,
        'metaProgression': metaProgression.toJson(),
        'codex': codex.toJson(),
        'currentRoomId': currentRoomId,
        'roomStates': roomStates.map((k, v) => MapEntry(k, v.toJson())),
        'companionSystem': companionSystem.toJson(),
        'routeState': routeState.toJson(),
        'sideActivityState': sideActivityState.toJson(),
        'activeQuests': activeQuests.map((e) => e.toJson()).toList(),
        'roomMasteryRank': roomMasteryRank,
        'sceneMasteryRanks': sceneMasteryRanks,
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      coins: GameNumber.fromJson(json['coins'] as Map<String, dynamic>),
      totalCoinsEarned:
          GameNumber.fromJson(json['totalCoinsEarned'] as Map<String, dynamic>),
      tapMultiplier:
          GameNumber.fromJson(json['tapMultiplier'] as Map<String, dynamic>),
      productionMultiplier: GameNumber.fromJson(
          json['productionMultiplier'] as Map<String, dynamic>),
      generators: (json['generators'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, GeneratorState.fromJson(v as Map<String, dynamic>)),
      ),
      upgrades: (json['upgrades'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, UpgradeState.fromJson(v as Map<String, dynamic>)),
      ),
      unlockedEras:
          (json['unlockedEras'] as List<dynamic>).map((e) => e as String).toSet(),
      currentEraId: json['currentEraId'] as String? ?? 'era_1',
      lastSaveTime: DateTime.parse(json['lastSaveTime'] as String),
      totalTaps: json['totalTaps'] as int? ?? 0,
      prestigeCount: json['prestigeCount'] as int? ?? 0,
      prestigeMultiplier: json['prestigeMultiplier'] != null
          ? GameNumber.fromJson(json['prestigeMultiplier'] as Map<String, dynamic>)
          : null,
      unlockedAchievements: json['unlockedAchievements'] != null
          ? (json['unlockedAchievements'] as List<dynamic>)
              .map((e) => e as String)
              .toSet()
          : const {},
      tutorialComplete: json['tutorialComplete'] as bool? ?? false,
      tapCombo: json['tapCombo'] as int? ?? 0,
      lastTapTime: json['lastTapTime'] != null
          ? DateTime.parse(json['lastTapTime'] as String)
          : null,
      strongestCombo: json['strongestCombo'] as int? ?? 0,
      totalUpgradesPurchased: json['totalUpgradesPurchased'] as int? ?? 0,
      totalGeneratorsPurchased:
          json['totalGeneratorsPurchased'] as int? ?? 0,
      totalCriticalClicks: json['totalCriticalClicks'] as int? ?? 0,
      totalPlaySeconds:
          (json['totalPlaySeconds'] as num?)?.toDouble() ?? 0,
      totalOfflineSeconds:
          (json['totalOfflineSeconds'] as num?)?.toDouble() ?? 0,
      automationCharge:
          (json['automationCharge'] as num?)?.toDouble() ?? 0,
      purchaseMomentum:
          (json['purchaseMomentum'] as num?)?.toDouble() ?? 0,
      unlockedMilestones: json['unlockedMilestones'] != null
          ? (json['unlockedMilestones'] as List<dynamic>)
              .map((e) => e as String)
              .toSet()
          : const {},
      discoveredSecrets: json['discoveredSecrets'] != null
          ? (json['discoveredSecrets'] as List<dynamic>)
              .map((e) => e as String)
              .toSet()
          : const {},
      chosenBranches: json['chosenBranches'] != null
          ? (json['chosenBranches'] as List<dynamic>)
              .map((e) => e as String)
              .toSet()
          : const {},
      abilities: json['abilities'] != null
          ? (json['abilities'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(
                k,
                ActiveAbilityState.fromJson(v as Map<String, dynamic>),
              ),
            )
          : {
              for (final ability in ActiveAbilityType.values)
                ability.name: ActiveAbilityState(
                  type: ability,
                  unlocked: ability == ActiveAbilityType.overclock ||
                      ability == ActiveAbilityType.focus,
                ),
            },
      activeEvent: json['activeEvent'] != null
          ? GameEventState.fromJson(
              json['activeEvent'] as Map<String, dynamic>,
            )
          : null,
      activeQuest: json['activeQuest'] != null
          ? QuestState.fromJson(json['activeQuest'] as Map<String, dynamic>)
          : null,
      playstyleTendencies: json['playstyleTendencies'] != null
          ? (json['playstyleTendencies'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            )
          : const {
              'active': 0,
              'passive': 0,
              'risky': 0,
              'efficient': 0,
              'event_hunter': 0,
            },
      challenges: json['challenges'] != null
          ? (json['challenges'] as List<dynamic>)
              .map((e) => ChallengeState.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      narrativeQueue: json['narrativeQueue'] != null
          ? (json['narrativeQueue'] as List<dynamic>)
              .map((e) => NarrativeBeat.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      activeMutators: json['activeMutators'] != null
          ? (json['activeMutators'] as List<dynamic>)
              .map((e) => GameplayMutatorState.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      loadoutPresets: json['loadoutPresets'] != null
          ? (json['loadoutPresets'] as List<dynamic>)
              .map((e) => LoadoutPreset.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [
              LoadoutPreset(
                id: 'preset_tap',
                name: 'Tap Bias',
                preferredBranches: {'tap'},
              ),
              LoadoutPreset(
                id: 'preset_auto',
                name: 'Auto Bias',
                preferredBranches: {'automation'},
              ),
            ],
      eventPityCounter: json['eventPityCounter'] as int? ?? 0,
      totalEventsSpawned: json['totalEventsSpawned'] as int? ?? 0,
      totalEventsClicked: json['totalEventsClicked'] as int? ?? 0,
      rareEventsFound: json['rareEventsFound'] as int? ?? 0,
      bestEventChain: json['bestEventChain'] as int? ?? 0,
      currentEventChain: json['currentEventChain'] as int? ?? 0,
      totalEventsMissed: json['totalEventsMissed'] as int? ?? 0,
      riskyChoicesTaken: json['riskyChoicesTaken'] as int? ?? 0,
      challengeRerollsRemaining:
          json['challengeRerollsRemaining'] as int? ?? 2,
      branchRespecTokens: json['branchRespecTokens'] as int? ?? 1,
      currentSeasonKey: json['currentSeasonKey'] as String? ?? 'season_alpha',
      routeSignature: json['routeSignature'] as String? ?? 'fresh',
      missedEventCharges: json['missedEventCharges'] as int? ?? 0,
      seenEventTemplates: (json['seenEventTemplates'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toSet(),
      completedSceneBadges:
          (json['completedSceneBadges'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toSet(),
      guideAffinity: (json['guideAffinity'] as num?)?.toDouble() ?? 0,
      economyRevision:
          json['economyRevision'] as int? ?? currentEconomyRevision,
      metaProgression: json['metaProgression'] != null
          ? MetaProgressionState.fromJson(
              json['metaProgression'] as Map<String, dynamic>)
          : const MetaProgressionState(),
      codex: json['codex'] != null
          ? CodexState.fromJson(json['codex'] as Map<String, dynamic>)
          : const CodexState(),
      currentRoomId: json['currentRoomId'] as String? ?? 'room_01',
      roomStates: json['roomStates'] != null
          ? (json['roomStates'] as Map<String, dynamic>).map(
              (k, v) =>
                  MapEntry(k, RoomSceneState.fromJson(v as Map<String, dynamic>)),
            )
          : const {},
      companionSystem: json['companionSystem'] != null
          ? CompanionSystemState.fromJson(
              json['companionSystem'] as Map<String, dynamic>)
          : const CompanionSystemState(),
      routeState: json['routeState'] != null
          ? RouteState.fromJson(json['routeState'] as Map<String, dynamic>)
          : const RouteState(),
      sideActivityState: json['sideActivityState'] != null
          ? SideActivityState.fromJson(
              json['sideActivityState'] as Map<String, dynamic>)
          : const SideActivityState(),
      activeQuests: json['activeQuests'] != null
          ? (json['activeQuests'] as List<dynamic>)
              .map((e) => QuestState.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      roomMasteryRank: json['roomMasteryRank'] as int? ?? 0,
      sceneMasteryRanks: json['sceneMasteryRanks'] != null
          ? (json['sceneMasteryRanks'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as int))
          : const {},
    );
  }
}
