import '../../../lib/core/math/game_number.dart';
import '../../../lib/domain/models/game_state.dart';
import '../../../lib/domain/systems/tap_system.dart';

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

  final baseTap = GameNumber.fromDouble(1);

  // --- calculateTapValue ---
  final tapVal = TapSystem.calculateTapValue(baseTap, GameNumber.fromDouble(1));
  expectTrue((tapVal.toDouble() - 1).abs() < 0.01, 'tap value with 1x multiplier');

  final tapVal2x = TapSystem.calculateTapValue(baseTap, GameNumber.fromDouble(2));
  expectTrue((tapVal2x.toDouble() - 2).abs() < 0.01, 'tap value with 2x multiplier');

  // --- processTap ---
  final state = GameState.initial();
  final tapped = TapSystem.processTap(state, baseTap);
  expectTrue((tapped.coins.toDouble() - 1).abs() < 0.01, 'processTap adds 1 coin');
  expectTrue(
    (tapped.totalCoinsEarned.toDouble() - 1).abs() < 0.01,
    'processTap updates totalCoinsEarned',
  );

  // Multiple taps
  var multiTap = state;
  for (int i = 0; i < 10; i++) {
    multiTap = TapSystem.processTap(multiTap, baseTap);
  }
  expectTrue((multiTap.coins.toDouble() - 10).abs() < 0.1, '10 taps = 10 coins');

  print('\n$passed passed, $failed failed');
  if (failed > 0) throw Exception('Tests failed');
}
