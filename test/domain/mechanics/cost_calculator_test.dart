import 'dart:math' as math;

import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/domain/mechanics/cost_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculateCost and calculateTotalCost work', () {
    final baseCost = GameNumber.fromDouble(10);
    const growthRate = 1.15;

    expect(
      CostCalculator.calculateCost(baseCost, growthRate, 0).toDouble(),
      closeTo(10, 0.1),
    );
    expect(
      CostCalculator.calculateCost(baseCost, growthRate, 1).toDouble(),
      closeTo(11.5, 0.1),
    );
    expect(
      CostCalculator.calculateCost(baseCost, growthRate, 10).toDouble(),
      closeTo(10 * math.pow(1.15, 10), 0.5),
    );

    final totalCost =
        CostCalculator.calculateTotalCost(baseCost, growthRate, 0, 3);
    final expectedTotal = 10 * (math.pow(1.15, 3) - 1) / (1.15 - 1);
    expect(
      (totalCost.toDouble() - expectedTotal).abs() / expectedTotal,
      lessThan(0.01),
    );
    expect(
      CostCalculator.calculateTotalCost(baseCost, growthRate, 0, 0).isZero,
      isTrue,
    );
  });

  test('maxAffordable returns the highest affordable quantity', () {
    final baseCost = GameNumber.fromDouble(10);
    const growthRate = 1.15;
    final budget = GameNumber.fromDouble(100);
    final affordable =
        CostCalculator.maxAffordable(baseCost, growthRate, 0, budget);

    expect(affordable, greaterThan(0));
    expect(
      CostCalculator.calculateTotalCost(baseCost, growthRate, 0, affordable) <=
          budget,
      isTrue,
    );
    expect(
      CostCalculator.calculateTotalCost(
            baseCost,
            growthRate,
            0,
            affordable + 1,
          ) >
          budget,
      isTrue,
    );
  });
}
