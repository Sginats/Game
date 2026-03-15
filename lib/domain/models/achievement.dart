import '../../core/math/game_number.dart';

/// Types of achievement requirements.
enum AchievementType {
  totalCoins,
  totalTaps,
  generatorLevel,
  upgradeLevel,
  productionRate,
  strongestCombo,
  totalUpgradesPurchased,
  totalGeneratorsPurchased,
  totalEventsClicked,
  totalPlaySeconds,
  prestigeCount,
  discoveredSecrets,
  riskyChoicesTaken,
  totalCriticalClicks,
  roomsCompleted,
  companionsOwned,
  companionEvolutions,
  sideActivitiesCompleted,
  questsCompleted,
  codexCompletion,
  routeTiersReached,
  bestEventChain,
  roomMasteryRank,
  totalTokensGenerated,
  collectionBonusesFulfilled,
  relicsAcquired,
  guideTrustLevel,
  roomLawsMastered,
  landmarksEvolved,
  challengesCompleted,
  hiddenAchievement,
}

/// Definition of an achievement loaded from configuration.
class AchievementDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementType type;
  final GameNumber threshold;
  final String? targetId;

  const AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.threshold,
    this.targetId,
  });

  factory AchievementDefinition.fromJson(Map<String, dynamic> json) {
    return AchievementDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String? ?? '🏆',
      type: AchievementType.values.firstWhere(
        (t) => t.name == json['type'] as String,
      ),
      threshold: _parseGameNumber(json['threshold']),
      targetId: json['targetId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'type': type.name,
        'threshold': threshold.toJson(),
        'targetId': targetId,
      };
}

GameNumber _parseGameNumber(dynamic value) {
  if (value is Map<String, dynamic>) return GameNumber.fromJson(value);
  if (value is String) return GameNumber.fromDouble(double.parse(value));
  if (value is num) return GameNumber.fromDouble(value.toDouble());
  return const GameNumber.zero();
}
