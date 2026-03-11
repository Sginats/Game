import '../../core/math/game_number.dart';
import 'generator.dart';
import 'upgrade.dart';

/// Complete game state — immutable, updated via [copyWith].
class GameState {
  final GameNumber coins;
  final GameNumber totalCoinsEarned;
  final GameNumber tapMultiplier;
  final GameNumber productionMultiplier;
  final Map<String, GeneratorState> generators;
  final Map<String, UpgradeState> upgrades;
  final Set<String> unlockedEras;
  final DateTime lastSaveTime;

  GameState({
    required this.coins,
    required this.totalCoinsEarned,
    required this.tapMultiplier,
    required this.productionMultiplier,
    required this.generators,
    required this.upgrades,
    required this.unlockedEras,
    required this.lastSaveTime,
  });

  /// Factory for a fresh new-game state.
  factory GameState.initial() {
    return GameState(
      coins: const GameNumber.zero(),
      totalCoinsEarned: const GameNumber.zero(),
      tapMultiplier: GameNumber.fromDouble(1),
      productionMultiplier: GameNumber.fromDouble(1),
      generators: const {},
      upgrades: const {},
      unlockedEras: const {'era_1'},
      lastSaveTime: DateTime.now(),
    );
  }

  GameState copyWith({
    GameNumber? coins,
    GameNumber? totalCoinsEarned,
    GameNumber? tapMultiplier,
    GameNumber? productionMultiplier,
    Map<String, GeneratorState>? generators,
    Map<String, UpgradeState>? upgrades,
    Set<String>? unlockedEras,
    DateTime? lastSaveTime,
  }) {
    return GameState(
      coins: coins ?? this.coins,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      tapMultiplier: tapMultiplier ?? this.tapMultiplier,
      productionMultiplier: productionMultiplier ?? this.productionMultiplier,
      generators: generators ?? this.generators,
      upgrades: upgrades ?? this.upgrades,
      unlockedEras: unlockedEras ?? this.unlockedEras,
      lastSaveTime: lastSaveTime ?? this.lastSaveTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'coins': coins.toJson(),
        'totalCoinsEarned': totalCoinsEarned.toJson(),
        'tapMultiplier': tapMultiplier.toJson(),
        'productionMultiplier': productionMultiplier.toJson(),
        'generators': generators.map((k, v) => MapEntry(k, v.toJson())),
        'upgrades': upgrades.map((k, v) => MapEntry(k, v.toJson())),
        'unlockedEras': unlockedEras.toList(),
        'lastSaveTime': lastSaveTime.toIso8601String(),
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      coins: GameNumber.fromJson(json['coins'] as Map<String, dynamic>),
      totalCoinsEarned:
          GameNumber.fromJson(json['totalCoinsEarned'] as Map<String, dynamic>),
      tapMultiplier:
          GameNumber.fromJson(json['tapMultiplier'] as Map<String, dynamic>),
      productionMultiplier: GameNumber.fromJson(
          json['productionMultiplier'] as Map<String, dynamic>),
      generators: (json['generators'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, GeneratorState.fromJson(v as Map<String, dynamic>)),
      ),
      upgrades: (json['upgrades'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, UpgradeState.fromJson(v as Map<String, dynamic>)),
      ),
      unlockedEras:
          (json['unlockedEras'] as List<dynamic>).map((e) => e as String).toSet(),
      lastSaveTime: DateTime.parse(json['lastSaveTime'] as String),
    );
  }
}
