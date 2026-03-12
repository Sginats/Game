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

  // --- calculateTapValueWithCombo ---
  final comboVal = TapSystem.calculateTapValueWithCombo(
    baseTap,
    GameNumber.fromDouble(1),
    5,
    GameNumber.fromDouble(1),
  );
  // 1 * 1 * (1 + 5*0.1) * 1 = 1.5
  expectTrue((comboVal.toDouble() - 1.5).abs() < 0.01, 'tap value with combo 5');

  final prestigeVal = TapSystem.calculateTapValueWithCombo(
    baseTap,
    GameNumber.fromDouble(2),
    10,
    GameNumber.fromDouble(1.5),
  );
  // 1 * 2 * (1 + 10*0.1) * 1.5 = 2 * 2 * 1.5 = 6.0
  expectTrue((prestigeVal.toDouble() - 6.0).abs() < 0.01, 'tap value with combo+prestige');

  // --- processTap ---
  final state = GameState.initial();
  final tapped = TapSystem.processTap(state, baseTap);
  // First tap: combo=0 (lastTapTime is null), value = 1*1*1*1 = 1
  expectTrue((tapped.coins.toDouble() - 1).abs() < 0.01, 'processTap adds 1 coin');
  expectTrue(
    (tapped.totalCoinsEarned.toDouble() - 1).abs() < 0.01,
    'processTap updates totalCoinsEarned',
  );
  expectTrue(tapped.totalTaps == 1, 'processTap increments totalTaps');

  // Multiple taps — combo builds up in rapid succession
  // Tap i has combo=i, value = 1*(1+i*0.1). Sum for i=0..9 = 14.5
  var multiTap = state;
  for (int i = 0; i < 10; i++) {
    multiTap = TapSystem.processTap(multiTap, baseTap);
  }
  expectTrue(multiTap.totalTaps == 10, '10 taps = totalTaps 10');
  // With combo: total ≈ 14.5 (each successive tap earns +10% more)
  expectTrue(multiTap.coins.toDouble() > 10, '10 rapid taps earn more than 10 coins (combo bonus)');

  print('\n$passed passed, $failed failed');
  if (failed > 0) throw Exception('Tests failed');
}
