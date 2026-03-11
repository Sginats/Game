/// A pure Dart class for representing and manipulating very large (or very
/// small) numbers commonly found in idle / incremental games.
///
/// Internally the value is stored as `mantissa × 10^exponent` where
/// [mantissa] is normalised to the half-open range **[1.0, 10.0)** (or is
/// exactly 0 for the zero value).
class GameNumber implements Comparable<GameNumber> {
  final double mantissa;
  final int exponent;

  // ──────────────────────────── constructors ────────────────────────────

  /// Creates a [GameNumber] from a raw [mantissa] and [exponent].
  /// The result is automatically normalised.
  GameNumber(double mantissa, int exponent)
      : mantissa = _normalisedMantissa(mantissa, exponent),
        exponent = _normalisedExponent(mantissa, exponent);

  /// The additive identity.
  const GameNumber.zero()
      : mantissa = 0,
        exponent = 0;

  /// Creates a [GameNumber] from a standard [double].
  factory GameNumber.fromDouble(double value) {
    if (value == 0) return const GameNumber.zero();
    if (value.isNaN || value.isInfinite) return const GameNumber.zero();

    final bool negative = value < 0;
    double abs = negative ? -value : value;
    int exp = 0;

    if (abs >= 10) {
      while (abs >= 10) {
        abs /= 10;
        exp++;
      }
    } else if (abs < 1) {
      while (abs < 1 && exp > -300) {
        abs *= 10;
        exp--;
      }
    }

    return GameNumber(negative ? -abs : abs, exp);
  }

  /// Creates a [GameNumber] from an [int].
  factory GameNumber.fromInt(int value) => GameNumber.fromDouble(value.toDouble());

  /// Deserialises from a JSON map produced by [toJson].
  factory GameNumber.fromJson(Map<String, dynamic> json) {
    final m = (json['mantissa'] as num).toDouble();
    final e = (json['exponent'] as num).toInt();
    return GameNumber(m, e);
  }

  // ──────────────────────────── serialisation ───────────────────────────

  Map<String, dynamic> toJson() => {'mantissa': mantissa, 'exponent': exponent};

  // ──────────────────────────── arithmetic ──────────────────────────────

  GameNumber operator +(GameNumber other) {
    if (isZero) return other;
    if (other.isZero) return this;

    // If one is negligibly small compared to the other, skip the add.
    final diff = exponent - other.exponent;
    if (diff > 15) return this;
    if (diff < -15) return other;

    // Pick the larger exponent as base
    if (exponent >= other.exponent) {
      final shifted = other.mantissa * _pow10(other.exponent - exponent);
      return GameNumber(mantissa + shifted, exponent);
    } else {
      final shifted = mantissa * _pow10(exponent - other.exponent);
      return GameNumber(other.mantissa + shifted, other.exponent);
    }
  }

  GameNumber operator -(GameNumber other) {
    if (other.isZero) return this;
    if (isZero) return GameNumber(-other.mantissa, other.exponent);

    final diff = exponent - other.exponent;
    if (diff > 15) return this;
    if (diff < -15) return GameNumber(-other.mantissa, other.exponent);

    if (exponent >= other.exponent) {
      final shifted = other.mantissa * _pow10(other.exponent - exponent);
      return GameNumber(mantissa - shifted, exponent);
    } else {
      final shifted = mantissa * _pow10(exponent - other.exponent);
      return GameNumber(shifted - other.mantissa, other.exponent);
    }
  }

  GameNumber operator *(GameNumber other) {
    if (isZero || other.isZero) return const GameNumber.zero();
    return GameNumber(mantissa * other.mantissa, exponent + other.exponent);
  }

  GameNumber operator /(GameNumber other) {
    if (other.isZero) return const GameNumber.zero(); // game-safe
    if (isZero) return const GameNumber.zero();
    return GameNumber(mantissa / other.mantissa, exponent - other.exponent);
  }

  // ──────────────────────────── comparison ──────────────────────────────

  @override
  int compareTo(GameNumber other) {
    if (isZero && other.isZero) return 0;
    if (isZero) return other.isNegative ? 1 : -1;
    if (other.isZero) return isNegative ? -1 : 1;

    final thisNeg = isNegative;
    final otherNeg = other.isNegative;
    if (thisNeg && !otherNeg) return -1;
    if (!thisNeg && otherNeg) return 1;

    // Same sign
    final expCmp = exponent.compareTo(other.exponent);
    if (expCmp != 0) return thisNeg ? -expCmp : expCmp;
    return thisNeg
        ? other.mantissa.compareTo(mantissa)
        : mantissa.compareTo(other.mantissa);
  }

  bool operator <(GameNumber other) => compareTo(other) < 0;
  bool operator >(GameNumber other) => compareTo(other) > 0;
  bool operator <=(GameNumber other) => compareTo(other) <= 0;
  bool operator >=(GameNumber other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GameNumber) return false;
    if (isZero && other.isZero) return true;
    return mantissa == other.mantissa && exponent == other.exponent;
  }

  @override
  int get hashCode => isZero ? 0 : Object.hash(mantissa, exponent);

  // ──────────────────────────── getters / helpers ───────────────────────

  bool get isZero => mantissa == 0;
  bool get isNegative => mantissa < 0;

  GameNumber abs() =>
      isNegative ? GameNumber(-mantissa, exponent) : this;

  GameNumber floor() {
    if (exponent < 0) return const GameNumber.zero();
    final value = toDouble();
    if (value.isInfinite) return this;
    return GameNumber.fromDouble(value.floorToDouble());
  }

  GameNumber copyWith({double? mantissa, int? exponent}) =>
      GameNumber(mantissa ?? this.mantissa, exponent ?? this.exponent);

  double toDouble() {
    if (isZero) return 0;
    if (exponent > 308) return mantissa > 0 ? double.infinity : double.negativeInfinity;
    if (exponent < -308) return 0;
    return mantissa * _pow10(exponent);
  }

  // ──────────────────────────── formatting ──────────────────────────────

  static const _suffixes = [
    '', 'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc',
    'UDc', 'DDc', 'TDc', 'QaDc', 'QiDc', 'SxDc', 'SpDc', 'OcDc', 'NoDc',
    'Vg',
  ];

  /// Human-readable format: "1.50K", "2.30M", etc.
  String toStringFormatted() {
    if (isZero) return '0';
    if (isNegative) return '-${abs().toStringFormatted()}';

    final totalExponent = exponent;
    final suffixIndex = totalExponent ~/ 3;

    if (suffixIndex < 0) {
      return toDouble().toStringAsFixed(2);
    }

    if (suffixIndex >= _suffixes.length) {
      return '${mantissa.toStringAsFixed(2)}e$exponent';
    }

    final remainder = totalExponent % 3;
    final displayValue = mantissa * _pow10(remainder);
    return '${displayValue.toStringAsFixed(2)}${_suffixes[suffixIndex]}';
  }

  @override
  String toString() {
    if (isZero) return '0';
    return '${mantissa.toStringAsFixed(2)}e$exponent';
  }

  // ──────────────────────────── normalisation ───────────────────────────

  static double _normalisedMantissa(double m, int e) {
    if (m == 0) return 0;
    double abs = m < 0 ? -m : m;
    while (abs >= 10) {
      abs /= 10;
    }
    while (abs < 1 && abs > 0) {
      abs *= 10;
    }
    return m < 0 ? -abs : abs;
  }

  static int _normalisedExponent(double m, int e) {
    if (m == 0) return 0;
    double abs = m < 0 ? -m : m;
    int exp = e;
    while (abs >= 10) {
      abs /= 10;
      exp++;
    }
    while (abs < 1 && abs > 0) {
      abs *= 10;
      exp--;
    }
    return exp;
  }

  static double _pow10(int n) {
    if (n == 0) return 1;
    if (n > 0 && n < _positivePow10.length) return _positivePow10[n];
    if (n < 0 && -n < _positivePow10.length) return 1.0 / _positivePow10[-n];
    // Fallback for very large/small exponents
    double result = 1;
    int absN = n < 0 ? -n : n;
    for (int i = 0; i < absN; i++) {
      result *= 10;
    }
    return n < 0 ? 1.0 / result : result;
  }

  static final List<double> _positivePow10 = List.generate(
    20,
    (i) {
      double v = 1;
      for (int j = 0; j < i; j++) {
        v *= 10;
      }
      return v;
    },
  );
}
