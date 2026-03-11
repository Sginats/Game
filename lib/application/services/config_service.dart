import '../../core/math/game_number.dart';
import '../../domain/models/era.dart';
import '../../domain/models/generator.dart';
import '../../domain/models/upgrade.dart';

/// Service that provides parsed configuration data to the game systems.
/// Pure Dart — no Flutter imports.
class ConfigService {
  final GameNumber baseTapValue;
  final GameNumber baseTapMultiplier;
  final Map<String, GeneratorDefinition> generators;
  final Map<String, UpgradeDefinition> upgrades;
  final List<Era> eras;
  final int maxOfflineHours;
  final int autoSaveIntervalSeconds;
  final int tickRateMs;

  ConfigService({
    required this.baseTapValue,
    required this.baseTapMultiplier,
    required this.generators,
    required this.upgrades,
    required this.eras,
    required this.maxOfflineHours,
    required this.autoSaveIntervalSeconds,
    required this.tickRateMs,
  });
}
