import 'dart:math' as math;

import '../../../lib/core/math/game_number.dart';
import '../../../lib/domain/mechanics/cost_calculator.dart';

void main() {
  var passed = 0;
  var failed = 0;

  void expectTrue(bool condition, String name) {
    if (condition) {
      passed++;
    } else {
      print('FAIL: $name');
      failed++;
    }
  }

  // --- calculateCost ---
  final baseCost = GameNumber.fromDouble(10);
  const growthRate = 1.15;

  // Level 0: cost = baseCost
  final cost0 = CostCalculator.calculateCost(baseCost, growthRate, 0);
  expectTrue((cost0.toDouble() - 10).abs() < 0.1, 'cost at level 0 = baseCost');

  // Level 1: cost = 10 * 1.15 = 11.5
  final cost1 = CostCalculator.calculateCost(baseCost, growthRate, 1);
  expectTrue((cost1.toDouble() - 11.5).abs() < 0.1, 'cost at level 1');

  // Level 10: cost = 10 * 1.15^10 ≈ 40.46
  final cost10 = CostCalculator.calculateCost(baseCost, growthRate, 10);
  final expected10 = 10 * math.pow(1.15, 10);
  expectTrue((cost10.toDouble() - expected10).abs() < 0.5, 'cost at level 10');

  // --- calculateTotalCost ---
  final totalCost = CostCalculator.calculateTotalCost(baseCost, growthRate, 0, 3);
  // Sum: 10 + 10*1.15 + 10*1.15^2
  final expectedTotal = 10 * (math.pow(1.15, 3) - 1) / (1.15 - 1);
  expectTrue(
    (totalCost.toDouble() - expectedTotal).abs() / expectedTotal < 0.01,
    'totalCost for 3 levels',
  );

  // Zero quantity
  final zeroCost = CostCalculator.calculateTotalCost(baseCost, growthRate, 0, 0);
  expectTrue(zeroCost.isZero, 'totalCost for 0 quantity');

  // --- maxAffordable ---
  final budget = GameNumber.fromDouble(100);
  final affordable = CostCalculator.maxAffordable(baseCost, growthRate, 0, budget);
  expectTrue(affordable > 0, 'maxAffordable with budget 100 > 0');
  // Verify it's correct: total for affordable should be <= budget
  final affordCost = CostCalculator.calculateTotalCost(baseCost, growthRate, 0, affordable);
  expectTrue(affordCost <= budget, 'maxAffordable cost within budget');
  // And affordable+1 should exceed budget
  if (affordable > 0) {
    final overCost = CostCalculator.calculateTotalCost(baseCost, growthRate, 0, affordable + 1);
    expectTrue(overCost > budget, 'maxAffordable+1 exceeds budget');
  }

  print('\n$passed passed, $failed failed');
  if (failed > 0) throw Exception('Tests failed');
}
