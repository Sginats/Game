import '../../core/math/game_number.dart';
import '../models/game_state.dart';

/// Pure functions for the tapping system.
///
/// tapValue = baseTap × tapMultiplier
class TapSystem {
  /// Calculate the current tap value.
  static GameNumber calculateTapValue(
    GameNumber baseTapValue,
    GameNumber tapMultiplier,
  ) {
    return baseTapValue * tapMultiplier;
  }

  /// Process a tap event and return the updated game state.
  static GameState processTap(GameState state, GameNumber baseTapValue) {
    final tapValue = calculateTapValue(baseTapValue, state.tapMultiplier);
    return state.copyWith(
      coins: state.coins + tapValue,
      totalCoinsEarned: state.totalCoinsEarned + tapValue,
    );
  }
}
