import 'package:ai_evolution/core/math/game_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('constructors and arithmetic behave correctly', () {
    const zero = GameNumber.zero();
    expect(zero.isZero, isTrue);
    expect(zero.toDouble(), 0);

    final fromDouble = GameNumber.fromDouble(1234.5);
    expect(fromDouble.toDouble(), closeTo(1234.5, 0.1));

    final fromInt = GameNumber.fromInt(100);
    expect(fromInt.toDouble(), closeTo(100, 0.1));

    final a = GameNumber.fromDouble(100);
    final b = GameNumber.fromDouble(50);
    expect((a + b).toDouble(), closeTo(150, 0.1));
    expect((a - b).toDouble(), closeTo(50, 0.1));
    expect((a * b).toDouble(), closeTo(5000, 0.5));
    expect((a / b).toDouble(), closeTo(2, 0.01));
    expect(a > b, isTrue);
    expect(b < a, isTrue);
    expect(a >= a, isTrue);
    expect(a, GameNumber.fromDouble(100));
  });

  test('serialization and formatting work', () {
    final value = GameNumber.fromDouble(100);
    expect(GameNumber.fromJson(value.toJson()), value);
    expect(GameNumber.fromDouble(1500).toStringFormatted(), '1.50K');
    expect(GameNumber.fromDouble(2300000).toStringFormatted(), '2.30M');
  });

  test('negative and large numbers behave', () {
    final neg = GameNumber.fromDouble(-5);
    expect(neg.isNegative, isTrue);
    expect(neg.abs().isNegative, isFalse);

    final large1 = GameNumber(1.5, 100);
    final large2 = GameNumber(2.0, 100);
    final largeSum = large1 + large2;
    expect(largeSum.exponent, 100);
  });
}
