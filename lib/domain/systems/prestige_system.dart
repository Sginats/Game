import 'dart:math' as math;

import '../../core/math/game_number.dart';
import '../models/game_state.dart';

/// Pure functions for the prestige (reset) system.
///
/// Prestige resets generators, upgrades, and coins but grants a permanent
/// multiplier based on total lifetime earnings.
class PrestigeSystem {
  /// Minimum total coins earned before prestige is available.
  static final prestigeThreshold = GameNumber.fromDouble(1e6);

  /// Calculate the prestige multiplier earned from a reset.
  ///
  /// Formula: 1 + 0.1 × floor(log10(totalCoinsEarned) - 5)
  /// So earning 1M = 1.1×, 10M = 1.2×, 100M = 1.3×, etc.
  static GameNumber calculatePrestigeMultiplier(GameNumber totalCoinsEarned) {
    if (totalCoinsEarned < prestigeThreshold || totalCoinsEarned.isZero) {
      return GameNumber.fromDouble(1);
    }
    // log10 of a GameNumber is approximately exponent + log10(mantissa)
    final absMantissa = totalCoinsEarned.mantissa.abs();
    if (absMantissa <= 0) return GameNumber.fromDouble(1);
    final log10 = totalCoinsEarned.exponent +
        (math.log(absMantissa) / math.ln10);
    final bonus = (log10 - 5).clamp(0, 100).toDouble();
    return GameNumber.fromDouble(1.0 + bonus * 0.1);
  }

  /// Whether the player can prestige.
  static bool canPrestige(GameState state) {
    return state.totalCoinsEarned >= prestigeThreshold;
  }

  /// Perform a prestige reset. Keeps prestigeCount, achieves, tutorialComplete.
  static GameState performPrestige(GameState state) {
    if (!canPrestige(state)) return state;

    final newMultiplier = calculatePrestigeMultiplier(state.totalCoinsEarned);
    // Accumulate: old prestige × new prestige bonus
    final combined = state.prestigeMultiplier * newMultiplier;

    return GameState(
      coins: const GameNumber.zero(),
      totalCoinsEarned: const GameNumber.zero(),
      tapMultiplier: GameNumber.fromDouble(1),
      productionMultiplier: GameNumber.fromDouble(1),
      generators: const {},
      upgrades: const {},
      unlockedEras: const {'era_1'},
      currentEraId: 'era_1',
      lastSaveTime: state.lastSaveTime,
      totalTaps: 0,
      prestigeCount: state.prestigeCount + 1,
      prestigeMultiplier: combined,
      unlockedAchievements: state.unlockedAchievements,
      tutorialComplete: state.tutorialComplete,
    );
  }
}
