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

      bool met = false;
      switch (def.type) {
        case AchievementType.totalCoins:
          met = state.totalCoinsEarned >= def.threshold;
          break;
        case AchievementType.totalTaps:
          met = GameNumber.fromInt(state.totalTaps) >= def.threshold;
          break;
        case AchievementType.generatorLevel:
          if (def.targetId != null) {
            final gen = state.generators[def.targetId];
            if (gen != null) {
              met = GameNumber.fromInt(gen.level) >= def.threshold;
            }
          }
          break;
        case AchievementType.upgradeLevel:
          if (def.targetId != null) {
            final upg = state.upgrades[def.targetId];
            if (upg != null) {
              met = GameNumber.fromInt(upg.level) >= def.threshold;
            }
          }
          break;
        case AchievementType.productionRate:
          met = productionPerSecond >= def.threshold;
          break;
      }

      if (met) newlyUnlocked.add(def.id);
    }

    return newlyUnlocked;
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
