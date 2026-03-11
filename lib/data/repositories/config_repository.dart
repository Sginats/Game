import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/era.dart';
import '../../domain/models/generator.dart';
import '../../domain/models/upgrade.dart';

/// Repository for loading configuration from JSON assets.
class ConfigRepository {
  Map<String, dynamic>? _gameConfig;
  Map<String, dynamic>? _economyConfig;

  Future<void> loadConfigs() async {
    final gameConfigStr =
        await rootBundle.loadString('assets/config/game_config.json');
    _gameConfig = json.decode(gameConfigStr) as Map<String, dynamic>;

    final economyConfigStr =
        await rootBundle.loadString('assets/config/economy_config.json');
    _economyConfig = json.decode(economyConfigStr) as Map<String, dynamic>;
  }

  Map<String, dynamic> get gameConfig {
    if (_gameConfig == null) {
      throw StateError('Configs not loaded. Call loadConfigs() first.');
    }
    return _gameConfig!;
  }

  Map<String, dynamic> get economyConfig {
    if (_economyConfig == null) {
      throw StateError('Configs not loaded. Call loadConfigs() first.');
    }
    return _economyConfig!;
  }

  int get maxOfflineHours => gameConfig['maxOfflineHours'] as int;
  int get autoSaveIntervalSeconds =>
      gameConfig['autoSaveIntervalSeconds'] as int;
  int get tickRateMs => gameConfig['tickRateMs'] as int;

  List<GeneratorDefinition> getGeneratorDefinitions() {
    final generators = economyConfig['generators'] as List<dynamic>;
    return generators
        .map((g) => GeneratorDefinition.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  List<UpgradeDefinition> getUpgradeDefinitions() {
    final upgrades = economyConfig['upgrades'] as List<dynamic>;
    return upgrades
        .map((u) => UpgradeDefinition.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  List<Era> getEras() {
    final eras = economyConfig['eras'] as List<dynamic>;
    return eras
        .map((e) => Era.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
