import '../../core/math/game_number.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/era.dart';
import '../../domain/models/game_systems.dart';
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
  final List<AchievementDefinition> achievements;
  final int maxOfflineHours;
  final int autoSaveIntervalSeconds;
  final int tickRateMs;
  final List<PurchaseMode> purchaseModes;
  final List<AITrait> aiTraits;
  final List<Ending> endings;

  ConfigService({
    required this.baseTapValue,
    required this.baseTapMultiplier,
    required this.generators,
    required this.upgrades,
    required this.eras,
    this.achievements = const [],
    required this.maxOfflineHours,
    required this.autoSaveIntervalSeconds,
    required this.tickRateMs,
    this.purchaseModes = const [
      PurchaseMode.x1,
      PurchaseMode.x10,
      PurchaseMode.x100,
      PurchaseMode.max,
    ],
    this.aiTraits = const [
      AITrait.helpful,
      AITrait.obsessive,
      AITrait.chaotic,
      AITrait.transcendent,
    ],
    this.endings = const [],
  });
}

