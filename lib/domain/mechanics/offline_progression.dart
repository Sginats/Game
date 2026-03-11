import '../../core/math/game_number.dart';
import '../models/game_state.dart';
import '../models/generator.dart';
import '../systems/generator_system.dart';

/// Pure functions for calculating offline progression.
class OfflineProgression {
  /// Calculate coins earned during offline time.
  ///
  /// [productionPerSecond] — current production rate.
  /// [offlineSeconds] — seconds elapsed since last save.
  /// [maxOfflineHours] — cap on offline time (from config).
  static GameNumber calculateOfflineEarnings(
    GameNumber productionPerSecond,
    int offlineSeconds,
    int maxOfflineHours,
  ) {
    if (productionPerSecond.isZero || offlineSeconds <= 0) {
      return const GameNumber.zero();
    }

    final maxSeconds = maxOfflineHours * 3600;
    final cappedSeconds = offlineSeconds > maxSeconds ? maxSeconds : offlineSeconds;
    return productionPerSecond * GameNumber.fromInt(cappedSeconds);
  }

  /// Apply offline earnings to the game state.
  static GameState applyOfflineEarnings(
    GameState state,
    Map<String, GeneratorDefinition> definitions,
    DateTime currentTime,
    int maxOfflineHours,
  ) {
    final offlineSeconds =
        currentTime.difference(state.lastSaveTime).inSeconds;
    if (offlineSeconds <= 0) return state;

    final production = GeneratorSystem.calculateTotalProduction(
      definitions,
      state.generators,
      state.productionMultiplier,
    );

    final earnings = calculateOfflineEarnings(
      production,
      offlineSeconds,
      maxOfflineHours,
    );

    if (earnings.isZero) return state;

    return state.copyWith(
      coins: state.coins + earnings,
      totalCoinsEarned: state.totalCoinsEarned + earnings,
      lastSaveTime: currentTime,
    );
  }
}
