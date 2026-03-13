import '../../core/math/game_number.dart';
import '../models/game_state.dart';

/// Pure functions for the tapping system.
///
/// tapValue = baseTap × tapMultiplier × comboMultiplier × prestigeMultiplier
///
/// Tap combo: rapid tapping within [comboWindowMs] builds a combo counter
/// that grants bonus tap value, making active play more rewarding than
/// passive automation in early / mid game.
class TapSystem {
  /// Milliseconds within which taps count towards a combo.
  static const comboWindowMs = 2000;
  static const baseCooldownMs = 550;

  /// Maximum combo multiplier (caps the bonus).
  static const maxCombo = 50;

  /// Calculate the current tap value (without combo).
  static GameNumber calculateTapValue(
    GameNumber baseTapValue,
    GameNumber tapMultiplier,
  ) {
    return baseTapValue * tapMultiplier;
  }

  /// Calculate tap value including combo bonus.
  /// combo multiplier = 1 + combo * 0.1 (i.e. each combo hit adds 10%).
  static GameNumber calculateTapValueWithCombo(
    GameNumber baseTapValue,
    GameNumber tapMultiplier,
    int combo,
    GameNumber prestigeMultiplier,
  ) {
    final base = baseTapValue * tapMultiplier;
    final comboBonus = GameNumber.fromDouble(1.0 + combo * 0.1);
    return base * comboBonus * prestigeMultiplier;
  }

  /// Process a tap event and return the updated game state.
  /// Handles combo tracking and prestige multiplier.
  static GameState processTap(
    GameState state,
    GameNumber baseTapValue, {
    required DateTime now,
  }) {
    int newCombo = 0;
    if (state.lastTapTime != null) {
      final elapsed = now.difference(state.lastTapTime!).inMilliseconds;
      if (elapsed < comboWindowMs) {
        newCombo = (state.tapCombo + 1).clamp(0, maxCombo);
      }
    }

    final tapValue = calculateTapValueWithCombo(
      baseTapValue,
      state.tapMultiplier,
      newCombo,
      state.prestigeMultiplier,
    );

    return state.copyWith(
      coins: state.coins + tapValue,
      totalCoinsEarned: state.totalCoinsEarned + tapValue,
      totalTaps: state.totalTaps + 1,
      tapCombo: newCombo,
      lastTapTime: now,
    );
  }
}

