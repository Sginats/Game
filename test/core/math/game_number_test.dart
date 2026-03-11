import '../../../lib/core/math/game_number.dart';

// Minimal test runner (no flutter_test dependency needed)
void main() {
  var passed = 0;
  var failed = 0;

  void expect(dynamic actual, dynamic expected, String name) {
    if (actual == expected) {
      passed++;
    } else {
      print('FAIL: $name — expected $expected, got $actual');
      failed++;
    }
  }

  void expectTrue(bool condition, String name) {
    if (condition) {
      passed++;
    } else {
      print('FAIL: $name');
      failed++;
    }
  }

  // --- Constructors ---
  final zero = const GameNumber.zero();
  expect(zero.isZero, true, 'zero.isZero');
  expect(zero.toDouble(), 0, 'zero.toDouble');

  final fromDouble = GameNumber.fromDouble(1234.5);
  expectTrue((fromDouble.toDouble() - 1234.5).abs() < 0.1, 'fromDouble(1234.5)');

  final fromInt = GameNumber.fromInt(100);
  expectTrue((fromInt.toDouble() - 100).abs() < 0.1, 'fromInt(100)');

  // --- Arithmetic ---
  final a = GameNumber.fromDouble(100);
  final b = GameNumber.fromDouble(50);

  final sum = a + b;
  expectTrue((sum.toDouble() - 150).abs() < 0.1, 'addition: 100 + 50');

  final diff = a - b;
  expectTrue((diff.toDouble() - 50).abs() < 0.1, 'subtraction: 100 - 50');

  final product = a * b;
  expectTrue((product.toDouble() - 5000).abs() < 0.5, 'multiplication: 100 × 50');

  final quotient = a / b;
  expectTrue((quotient.toDouble() - 2.0).abs() < 0.01, 'division: 100 / 50');

  // --- Comparison ---
  expectTrue(a > b, 'comparison: 100 > 50');
  expectTrue(b < a, 'comparison: 50 < 100');
  expectTrue(a >= a, 'comparison: 100 >= 100');
  expectTrue(a == GameNumber.fromDouble(100), 'equality: 100 == 100');

  // --- Serialization ---
  final json = a.toJson();
  final deserialized = GameNumber.fromJson(json);
  expect(deserialized, a, 'JSON round-trip');

  // --- Formatting ---
  final thousand = GameNumber.fromDouble(1500);
  expect(thousand.toStringFormatted(), '1.50K', 'format 1500 as 1.50K');

  final million = GameNumber.fromDouble(2300000);
  expect(million.toStringFormatted(), '2.30M', 'format 2300000 as 2.30M');

  // --- Negative ---
  final neg = GameNumber.fromDouble(-5);
  expectTrue(neg.isNegative, 'isNegative for -5');
  expectTrue(!neg.abs().isNegative, 'abs of -5 is positive');

  // --- Large numbers ---
  final large1 = GameNumber(1.5, 100);
  final large2 = GameNumber(2.0, 100);
  final largeSum = large1 + large2;
  expect(largeSum.exponent, 100, 'large number addition preserves exponent');

  print('\n$passed passed, $failed failed');
  if (failed > 0) throw Exception('Tests failed');
}
