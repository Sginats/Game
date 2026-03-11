import '../../core/math/game_number.dart';
import '../../core/time/time_provider.dart';
import '../../domain/models/game_state.dart';
import '../../domain/systems/generator_system.dart';
import '../../domain/systems/tap_system.dart';
import '../../domain/systems/upgrade_system.dart';
import '../../domain/mechanics/offline_progression.dart';
import '../services/config_service.dart';

/// Main game controller that orchestrates all game logic.
/// Pure Dart — no Flutter imports.
class GameController {
  final ConfigService _config;
  final TimeProvider _timeProvider;
  GameState _state;

  GameController({
    required ConfigService config,
    required TimeProvider timeProvider,
    GameState? initialState,
  })  : _config = config,
        _timeProvider = timeProvider,
        _state = initialState ?? GameState.initial();

  GameState get state => _state;
  ConfigService get config => _config;

  /// Process a tap event.
  void tap() {
    _state = TapSystem.processTap(_state, _config.baseTapValue);
  }

  /// Purchase a generator. Returns true if successful.
  bool purchaseGenerator(String generatorId, {int quantity = 1}) {
    if (quantity <= 0) return false;
    final definition = _config.generators[generatorId];
    if (definition == null) return false;

    final newState =
        GeneratorSystem.purchaseGenerator(_state, definition, quantity);
    if (identical(newState, _state)) return false;

    _state = newState;
    return true;
  }

  /// Purchase an upgrade. Returns true if successful.
  bool purchaseUpgrade(String upgradeId) {
    final definition = _config.upgrades[upgradeId];
    if (definition == null) return false;

    final newState = UpgradeSystem.purchaseUpgrade(_state, definition);
    if (identical(newState, _state)) return false;

    _state = newState;
    return true;
  }

  /// Advance the game by [deltaSeconds] (called periodically).
  void tick(double deltaSeconds) {
    final production = GeneratorSystem.calculateTotalProduction(
      _config.generators,
      _state.generators,
      _state.productionMultiplier,
    );

    final earned = production * GameNumber.fromDouble(deltaSeconds);
    if (!earned.isZero) {
      _state = _state.copyWith(
        coins: _state.coins + earned,
        totalCoinsEarned: _state.totalCoinsEarned + earned,
      );
    }
  }

  /// Current production per second across all generators.
  GameNumber get productionPerSecond {
    return GeneratorSystem.calculateTotalProduction(
      _config.generators,
      _state.generators,
      _state.productionMultiplier,
    );
  }

  /// Apply offline earnings when the player returns.
  void applyOfflineEarnings() {
    _state = OfflineProgression.applyOfflineEarnings(
      _state,
      _config.generators,
      _timeProvider.now(),
      _config.maxOfflineHours,
    );
  }

  /// Update the last-save timestamp.
  void updateSaveTime() {
    _state = _state.copyWith(lastSaveTime: _timeProvider.now());
  }

  /// Replace the current state (e.g. when loading a save).
  void setState(GameState state) {
    _state = state;
  }
}
