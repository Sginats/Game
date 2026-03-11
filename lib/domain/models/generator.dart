import '../../core/math/game_number.dart';

/// Helper to parse a GameNumber from JSON that may be a String, num, or map.
GameNumber _parseGameNumber(dynamic value) {
  if (value is Map<String, dynamic>) return GameNumber.fromJson(value);
  if (value is String) return GameNumber.fromDouble(double.parse(value));
  if (value is num) return GameNumber.fromDouble(value.toDouble());
  return const GameNumber.zero();
}

/// Definition of a generator loaded from configuration.
class GeneratorDefinition {
  final String id;
  final String name;
  final String description;
  final String eraId;
  final GameNumber baseCost;
  final double costGrowthRate;
  final GameNumber baseProduction;
  final String? unlockRequirement;

  const GeneratorDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.eraId,
    required this.baseCost,
    required this.costGrowthRate,
    required this.baseProduction,
    this.unlockRequirement,
  });

  factory GeneratorDefinition.fromJson(Map<String, dynamic> json) {
    return GeneratorDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      eraId: json['eraId'] as String,
      baseCost: _parseGameNumber(json['baseCost']),
      costGrowthRate: double.parse(json['costGrowthRate'].toString()),
      baseProduction: _parseGameNumber(json['baseProduction']),
      unlockRequirement: json['unlockRequirement'] as String?,
    );
  }
}

/// Runtime state of a generator owned by the player.
class GeneratorState {
  final String definitionId;
  final int level;
  final GameNumber multiplier;

  GeneratorState({
    required this.definitionId,
    this.level = 0,
    GameNumber? multiplier,
  }) : multiplier = multiplier ?? GameNumber.fromDouble(1);

  GeneratorState copyWith({
    String? definitionId,
    int? level,
    GameNumber? multiplier,
  }) {
    return GeneratorState(
      definitionId: definitionId ?? this.definitionId,
      level: level ?? this.level,
      multiplier: multiplier ?? this.multiplier,
    );
  }

  Map<String, dynamic> toJson() => {
        'definitionId': definitionId,
        'level': level,
        'multiplier': multiplier.toJson(),
      };

  factory GeneratorState.fromJson(Map<String, dynamic> json) {
    return GeneratorState(
      definitionId: json['definitionId'] as String,
      level: json['level'] as int,
      multiplier: GameNumber.fromJson(json['multiplier'] as Map<String, dynamic>),
    );
  }
}
