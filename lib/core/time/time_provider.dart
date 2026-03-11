/// Abstraction over system time to allow deterministic testing.
///
/// Architecture Rule 6: Game state must be deterministic and reproducible.
abstract class TimeProvider {
  DateTime now();
}

/// Production implementation that returns the real system time.
class SystemTimeProvider implements TimeProvider {
  @override
  DateTime now() => DateTime.now();
}
