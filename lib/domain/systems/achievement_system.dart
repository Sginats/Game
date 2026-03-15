import '../../core/math/game_number.dart';
import '../models/achievement.dart';
import '../models/game_state.dart';

/// Pure functions for checking and unlocking achievements.
class AchievementSystem {
  /// Check all achievements against the current state and return newly
  /// unlocked achievement IDs.
  static Set<String> checkAchievements(
    GameState state,
    List<AchievementDefinition> definitions,
    GameNumber productionPerSecond,
  ) {
    final newlyUnlocked = <String>{};

    for (final def in definitions) {
      if (state.unlockedAchievements.contains(def.id)) continue;

      final met = _isAchievementMet(state, def, productionPerSecond);
      if (met) newlyUnlocked.add(def.id);
    }

    return newlyUnlocked;
  }

  static bool _isAchievementMet(
    GameState state,
    AchievementDefinition def,
    GameNumber productionPerSecond,
  ) {
    switch (def.type) {
      case AchievementType.totalCoins:
        return state.totalCoinsEarned >= def.threshold;
      case AchievementType.totalTaps:
        return GameNumber.fromInt(state.totalTaps) >= def.threshold;
      case AchievementType.generatorLevel:
        if (def.targetId != null) {
          final gen = state.generators[def.targetId];
          if (gen != null) {
            return GameNumber.fromInt(gen.level) >= def.threshold;
          }
        }
        return false;
      case AchievementType.upgradeLevel:
        if (def.targetId != null) {
          final upg = state.upgrades[def.targetId];
          if (upg != null) {
            return GameNumber.fromInt(upg.level) >= def.threshold;
          }
        }
        return false;
      case AchievementType.productionRate:
        return productionPerSecond >= def.threshold;
      case AchievementType.strongestCombo:
        return GameNumber.fromInt(state.strongestCombo) >= def.threshold;
      case AchievementType.totalUpgradesPurchased:
        return GameNumber.fromInt(state.totalUpgradesPurchased) >= def.threshold;
      case AchievementType.totalGeneratorsPurchased:
        return GameNumber.fromInt(state.totalGeneratorsPurchased) >= def.threshold;
      case AchievementType.totalEventsClicked:
        return GameNumber.fromInt(state.totalEventsClicked) >= def.threshold;
      case AchievementType.totalPlaySeconds:
        return GameNumber.fromDouble(state.totalPlaySeconds) >= def.threshold;
      case AchievementType.prestigeCount:
        return GameNumber.fromInt(state.prestigeCount) >= def.threshold;
      case AchievementType.discoveredSecrets:
        return GameNumber.fromInt(state.discoveredSecrets.length) >= def.threshold;
      case AchievementType.riskyChoicesTaken:
        return GameNumber.fromInt(state.riskyChoicesTaken) >= def.threshold;
      case AchievementType.totalCriticalClicks:
        return GameNumber.fromInt(state.totalCriticalClicks) >= def.threshold;
      case AchievementType.roomsCompleted:
        return GameNumber.fromInt(
                state.metaProgression.roomsCompleted.length) >=
            def.threshold;
      case AchievementType.companionsOwned:
        return GameNumber.fromInt(
                state.companionSystem.ownedCompanions.length) >=
            def.threshold;
      case AchievementType.companionEvolutions:
        final evolved = state.companionSystem.ownedCompanions
            .where((c) => c.evolutionStage > 1)
            .length;
        return GameNumber.fromInt(evolved) >= def.threshold;
      case AchievementType.sideActivitiesCompleted:
        return GameNumber.fromInt(
                state.sideActivityState.totalActivitiesCompleted) >=
            def.threshold;
      case AchievementType.questsCompleted:
        final completed =
            state.activeQuests.where((q) => q.completed).length;
        return GameNumber.fromInt(completed) >= def.threshold;
      case AchievementType.codexCompletion:
        return GameNumber.fromInt(state.codex.totalDiscovered) >=
            def.threshold;
      case AchievementType.routeTiersReached:
        final maxTier = state.routeState.routeProgresses.isEmpty
            ? 0
            : state.routeState.routeProgresses
                .map((r) => r.tier)
                .reduce((a, b) => a > b ? a : b);
        return GameNumber.fromInt(maxTier) >= def.threshold;
      case AchievementType.bestEventChain:
        return GameNumber.fromInt(state.bestEventChain) >= def.threshold;
      case AchievementType.roomMasteryRank:
        return GameNumber.fromInt(state.roomMasteryRank) >= def.threshold;
      case AchievementType.totalTokensGenerated:
        return GameNumber.fromInt(
                state.companionSystem.totalTokensGenerated) >=
            def.threshold;
      case AchievementType.collectionBonusesFulfilled:
        return GameNumber.fromInt(
                state.companionSystem.collectionBonuses
                    .where((b) => b.fulfilled)
                    .length) >=
            def.threshold;
      case AchievementType.relicsAcquired:
        return GameNumber.fromInt(
                state.metaProgression.relics.length) >=
            def.threshold;
      case AchievementType.guideTrustLevel:
        return GameNumber.fromInt(
                state.metaProgression.guideMilestones.length) >=
            def.threshold;
      case AchievementType.roomLawsMastered:
        final mastered = state.roomStates.values
            .where((rs) => rs.completed)
            .length;
        return GameNumber.fromInt(mastered) >= def.threshold;
      case AchievementType.landmarksEvolved:
        final evolved = state.roomStates.values
            .where((rs) => rs.currentTransformationStage > 0)
            .length;
        return GameNumber.fromInt(evolved) >= def.threshold;
      case AchievementType.challengesCompleted:
        return GameNumber.fromInt(
                state.metaProgression.challengesCleared) >=
            def.threshold;
      case AchievementType.hiddenAchievement:
        // Hidden achievements are tracked via discoveredSecrets or
        // specific meta progression milestones.
        return GameNumber.fromInt(
                state.metaProgression.secretsArchived.length) >=
            def.threshold;
    }
  }

  /// Apply newly unlocked achievements to the game state.
  static GameState applyAchievements(
    GameState state,
    Set<String> newAchievements,
  ) {
    if (newAchievements.isEmpty) return state;
    return state.copyWith(
      unlockedAchievements: {...state.unlockedAchievements, ...newAchievements},
    );
  }
}
