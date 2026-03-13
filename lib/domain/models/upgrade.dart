import '../../core/math/game_number.dart';

/// Helper to parse a GameNumber from JSON that may be a String, num, or map.
GameNumber _parseGameNumber(dynamic value) {
  if (value is Map<String, dynamic>) return GameNumber.fromJson(value);
  if (value is String) return GameNumber.fromDouble(double.parse(value));
  if (value is num) return GameNumber.fromDouble(value.toDouble());
  return const GameNumber.zero();
}

/// The type of effect an upgrade provides.
enum UpgradeType {
  tapMultiplier,
  productionMultiplier,
  generatorMultiplier,
}

/// The gameplay category an upgrade belongs to.
enum UpgradeCategory {
  tap,
  automation,
  room,
  ai,
  special,
}

/// Definition of an upgrade loaded from configuration.
class UpgradeDefinition {
  final String id;
  final String name;
  final String description;
  final UpgradeType type;
  final UpgradeCategory category;
  final String eraId;
  final GameNumber baseCost;
  final double costGrowthRate;
  final int maxLevel;
  final GameNumber effectPerLevel;
  final String? targetGeneratorId;
  final String? unlockRequirement;

  const UpgradeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.category = UpgradeCategory.room,
    required this.eraId,
    required this.baseCost,
    required this.costGrowthRate,
    required this.maxLevel,
    required this.effectPerLevel,
    this.targetGeneratorId,
    this.unlockRequirement,
  });

  factory UpgradeDefinition.fromJson(Map<String, dynamic> json) {
    return UpgradeDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: UpgradeType.values.firstWhere(
        (t) => t.name == json['type'] as String,
      ),
      category: json['category'] != null
          ? UpgradeCategory.values.firstWhere(
              (c) => c.name == json['category'] as String,
              orElse: () => UpgradeCategory.room,
            )
          : UpgradeCategory.room,
      eraId: json['eraId'] as String,
      baseCost: _parseGameNumber(json['baseCost']),
      costGrowthRate: double.parse(json['costGrowthRate'].toString()),
      maxLevel: json['maxLevel'] as int,
      effectPerLevel: _parseGameNumber(json['effectPerLevel']),
      targetGeneratorId: json['targetGeneratorId'] as String?,
      unlockRequirement: json['unlockRequirement'] as String?,
    );
  }
}

/// Runtime state of an upgrade owned by the player.
class UpgradeState {
  final String definitionId;
  final int level;

  const UpgradeState({
    required this.definitionId,
    this.level = 0,
  });

  UpgradeState copyWith({String? definitionId, int? level}) {
    return UpgradeState(
      definitionId: definitionId ?? this.definitionId,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toJson() => {
        'definitionId': definitionId,
        'level': level,
      };

  factory UpgradeState.fromJson(Map<String, dynamic> json) {
    return UpgradeState(
      definitionId: json['definitionId'] as String,
      level: json['level'] as int,
    );
  }
}
