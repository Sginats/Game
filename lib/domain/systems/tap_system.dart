import 'dart:math' as math;

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

  /// Soft cap for combo — no hard limit, but UI may truncate display.
  static const maxCombo = 9999;

  /// Calculate the current tap value (without combo).
  static GameNumber calculateTapValue(
    GameNumber baseTapValue,
    GameNumber tapMultiplier,
  ) {
    return baseTapValue * tapMultiplier;
  }

  /// Calculate combo bonus multiplier with diminishing returns.
  /// Formula: 1.0 + combo * 0.02 + ln(1 + combo) * 0.05
  /// At combo 10: ~1.32, combo 50: ~2.20, combo 100: ~3.23, combo 500: ~7.31
  static double comboTapMultiplier(int combo) {
    if (combo <= 0) return 1.0;
    return 1.0 + combo * 0.02 + math.log(1 + combo) * 0.05;
  }

  /// Calculate combo production bonus (very small per-combo).
  /// Formula: 1.0 + combo * 0.0001
  /// At combo 50: 1.005, combo 500: 1.05
  static double comboProductionMultiplier(int combo) {
    if (combo <= 0) return 1.0;
    return 1.0 + combo * 0.0001;
  }

  /// Calculate tap value including combo bonus.
  static GameNumber calculateTapValueWithCombo(
    GameNumber baseTapValue,
    GameNumber tapMultiplier,
    int combo,
    GameNumber prestigeMultiplier,
  ) {
    final base = baseTapValue * tapMultiplier;
    final comboBonus = GameNumber.fromDouble(comboTapMultiplier(combo));
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

