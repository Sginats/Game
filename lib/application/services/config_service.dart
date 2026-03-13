import '../../core/math/game_number.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/era.dart';
import '../../domain/models/game_systems.dart';
import '../../domain/models/generator.dart';
import '../../domain/models/progression_content.dart';
import '../../domain/models/upgrade.dart';

/// Service that provides parsed configuration data to the game systems.
/// Pure Dart — no Flutter imports.
class ConfigService {
  final GameNumber baseTapValue;
  final GameNumber baseTapMultiplier;
  final Map<String, GeneratorDefinition> generators;
  final Map<String, UpgradeDefinition> upgrades;
  final List<Era> eras;
  final List<AchievementDefinition> achievements;
  final int maxOfflineHours;
  final int autoSaveIntervalSeconds;
  final int tickRateMs;
  final List<PurchaseMode> purchaseModes;
  final List<AITrait> aiTraits;
  final List<Ending> endings;
  final ProgressionContent progression;

  ConfigService({
    required this.baseTapValue,
    required this.baseTapMultiplier,
    required this.generators,
    required this.upgrades,
    required this.eras,
    this.achievements = const [],
    required this.maxOfflineHours,
    required this.autoSaveIntervalSeconds,
    required this.tickRateMs,
    this.purchaseModes = const [
      PurchaseMode.x1,
      PurchaseMode.x10,
      PurchaseMode.x100,
      PurchaseMode.max,
    ],
    this.aiTraits = const [
      AITrait.helpful,
      AITrait.obsessive,
      AITrait.chaotic,
      AITrait.transcendent,
    ],
    this.endings = const [],
    this.progression = const ProgressionContent(),
  });

  BranchDefinition? branchById(String id) {
    for (final branch in progression.branches) {
      if (branch.id == id) return branch;
    }
    return null;
  }

  MilestoneDefinition? milestoneById(String id) {
    for (final milestone in progression.milestones) {
      if (milestone.id == id) return milestone;
    }
    return null;
  }

  ChallengeTemplateDefinition? challengeTemplateById(String id) {
    for (final challenge in progression.challenges) {
      if (challenge.id == id) return challenge;
    }
    return null;
  }

  NarrativeBeatDefinition? narrativeByTrigger(String triggerKey) {
    for (final beat in progression.narrativeBeats) {
      if (beat.triggerKey == triggerKey) return beat;
    }
    return null;
  }

  QuestDefinition? questById(String id) {
    for (final quest in progression.quests) {
      if (quest.id == id) return quest;
    }
    return null;
  }
}

