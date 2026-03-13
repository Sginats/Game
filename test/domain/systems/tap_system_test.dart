import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/domain/models/game_state.dart';
import 'package:ai_evolution/domain/systems/tap_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tap value calculations are correct', () {
    final baseTap = GameNumber.fromDouble(1);
    expect(
      TapSystem.calculateTapValue(baseTap, GameNumber.fromDouble(1)).toDouble(),
      closeTo(1, 0.01),
    );
    expect(
      TapSystem.calculateTapValue(baseTap, GameNumber.fromDouble(2)).toDouble(),
      closeTo(2, 0.01),
    );
    expect(
      TapSystem.calculateTapValueWithCombo(
        baseTap,
        GameNumber.fromDouble(1),
        5,
        GameNumber.fromDouble(1),
      ).toDouble(),
      closeTo(1.5, 0.01),
    );
    expect(
      TapSystem.calculateTapValueWithCombo(
        baseTap,
        GameNumber.fromDouble(2),
        10,
        GameNumber.fromDouble(1.5),
      ).toDouble(),
      closeTo(6.0, 0.01),
    );
  });

  test('processTap updates totals and combo earnings', () {
    final baseTap = GameNumber.fromDouble(1);
    final state = GameState.initial();
    final start = DateTime(2026, 1, 1);
    final tapped = TapSystem.processTap(state, baseTap, now: start);
    expect(tapped.coins.toDouble(), closeTo(1, 0.01));
    expect(tapped.totalCoinsEarned.toDouble(), closeTo(1, 0.01));
    expect(tapped.totalTaps, 1);

    var multiTap = state;
    for (var i = 0; i < 10; i++) {
      multiTap = TapSystem.processTap(
        multiTap,
        baseTap,
        now: start.add(Duration(milliseconds: 200 * i)),
      );
    }
    expect(multiTap.totalTaps, 10);
    expect(multiTap.coins.toDouble(), greaterThan(10));
  });
}
