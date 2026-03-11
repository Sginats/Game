import 'dart:math' as math;

import '../../core/math/game_number.dart';

/// Pure functions for calculating upgrade/generator costs.
///
/// Formula: cost = baseCost × growthRate ^ level
/// No economic constants are hardcoded here.
class CostCalculator {
  /// Calculate the cost for a single level.
  static GameNumber calculateCost(
    GameNumber baseCost,
    double growthRate,
    int level,
  ) {
    if (level <= 0) return baseCost;
    final multiplier = math.pow(growthRate, level).toDouble();
    return baseCost * GameNumber.fromDouble(multiplier);
  }

  /// Calculate total cost for buying [quantity] levels starting at [fromLevel].
  static GameNumber calculateTotalCost(
    GameNumber baseCost,
    double growthRate,
    int fromLevel,
    int quantity,
  ) {
    if (quantity <= 0) return const GameNumber.zero();

    // Sum of geometric series: baseCost * r^fromLevel * (r^quantity - 1) / (r - 1)
    if ((growthRate - 1.0).abs() < 1e-9) {
      // Linear case (growthRate ≈ 1)
      return calculateCost(baseCost, growthRate, fromLevel) *
          GameNumber.fromInt(quantity);
    }

    final rFromLevel = math.pow(growthRate, fromLevel).toDouble();
    final rQuantity = math.pow(growthRate, quantity).toDouble();
    final sum = rFromLevel * (rQuantity - 1) / (growthRate - 1);
    return baseCost * GameNumber.fromDouble(sum);
  }

  /// Returns how many levels can be purchased with the given budget.
  static int maxAffordable(
    GameNumber baseCost,
    double growthRate,
    int currentLevel,
    GameNumber budget,
  ) {
    if (budget.isZero) return 0;

    // Binary search for maximum affordable quantity
    int lo = 0;
    int hi = 1;

    // Find upper bound
    while (calculateTotalCost(baseCost, growthRate, currentLevel, hi) <= budget) {
      hi *= 2;
      if (hi > 10000) break; // Safety limit
    }

    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      final cost = calculateTotalCost(baseCost, growthRate, currentLevel, mid);
      if (cost <= budget) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }

    return lo;
  }
}
