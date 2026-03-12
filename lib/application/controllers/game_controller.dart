import '../../core/math/game_number.dart';
import '../../core/time/time_provider.dart';
import '../../data/repositories/game_repository.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/game_state.dart';
import '../../domain/systems/achievement_system.dart';
import '../../domain/systems/generator_system.dart';
import '../../domain/systems/prestige_system.dart';
import '../../domain/systems/tap_system.dart';
import '../../domain/systems/upgrade_system.dart';
import '../../domain/mechanics/offline_progression.dart';
import '../services/config_service.dart';

/// Main game controller that orchestrates all game logic.
/// Pure Dart — no Flutter imports.
class GameController {
  final ConfigService _config;
  final TimeProvider _timeProvider;
  final GameRepository? _repository;
  GameState _state;
  double _autoSaveAccumulator = 0;

  /// Achievements whose unlock was detected on the last tick / action.
  List<AchievementDefinition> lastUnlockedAchievements = [];

  /// Offline earnings that were applied when loading (shown in popup).
  GameNumber? pendingOfflineEarnings;

  GameController({
    required ConfigService config,
    required TimeProvider timeProvider,
    GameState? initialState,
    GameRepository? repository,
  })  : _config = config,
        _timeProvider = timeProvider,
        _repository = repository,
        _state = initialState ?? GameState.initial();

  GameState get state => _state;
  ConfigService get config => _config;

  // ─── Tap ─────────────────────────────────────────────────────────────

  /// Process a tap event.
  void tap() {
    _state = TapSystem.processTap(_state, _config.baseTapValue);
    _checkAchievements();
  }

  // ─── Purchases ───────────────────────────────────────────────────────

  /// Purchase a generator. Returns true if successful.
  bool purchaseGenerator(String generatorId, {int quantity = 1}) {
    if (quantity <= 0) return false;
    final definition = _config.generators[generatorId];
    if (definition == null) return false;

    final newState =
        GeneratorSystem.purchaseGenerator(_state, definition, quantity);
    if (identical(newState, _state)) return false;

    _state = newState;
    _checkAchievements();
    return true;
  }

  /// Purchase an upgrade. Returns true if successful.
  bool purchaseUpgrade(String upgradeId) {
    final definition = _config.upgrades[upgradeId];
    if (definition == null) return false;

    final newState = UpgradeSystem.purchaseUpgrade(_state, definition);
    if (identical(newState, _state)) return false;

    _state = newState;
    _checkAchievements();
    return true;
  }

  // ─── Tick / production ───────────────────────────────────────────────

  /// Advance the game by [deltaSeconds] (called periodically).
  void tick(double deltaSeconds) {
    final production = GeneratorSystem.calculateTotalProduction(
      _config.generators,
      _state.generators,
      _state.productionMultiplier,
    );

    final earned = production *
        GameNumber.fromDouble(deltaSeconds) *
        _state.prestigeMultiplier;
    if (!earned.isZero) {
      _state = _state.copyWith(
        coins: _state.coins + earned,
        totalCoinsEarned: _state.totalCoinsEarned + earned,
      );
    }

    // Auto-save
    _autoSaveAccumulator += deltaSeconds;
    if (_autoSaveAccumulator >= _config.autoSaveIntervalSeconds) {
      _autoSaveAccumulator = 0;
      saveGame();
    }

    _checkAchievements();
  }

  /// Current production per second across all generators.
  GameNumber get productionPerSecond {
    return GeneratorSystem.calculateTotalProduction(
      _config.generators,
      _state.generators,
      _state.productionMultiplier,
    ) * _state.prestigeMultiplier;
  }

  // ─── Offline earnings ────────────────────────────────────────────────

  /// Apply offline earnings when the player returns.
  void applyOfflineEarnings() {
    final before = _state.coins;
    _state = OfflineProgression.applyOfflineEarnings(
      _state,
      _config.generators,
      _timeProvider.now(),
      _config.maxOfflineHours,
    );
    final earned = _state.coins - before;
    if (!earned.isZero) {
      pendingOfflineEarnings = earned;
    }
  }

  // ─── Save / load ────────────────────────────────────────────────────

  /// Update the last-save timestamp.
  void updateSaveTime() {
    _state = _state.copyWith(lastSaveTime: _timeProvider.now());
  }

  /// Replace the current state (e.g. when loading a save).
  void setState(GameState state) {
    _state = state;
  }

  /// Persist current state via the repository.
  Future<void> saveGame() async {
    updateSaveTime();
    await _repository?.saveGame(_state);
  }

  /// Load saved state from repository. Returns true if a save was loaded.
  Future<bool> loadGame() async {
    if (_repository == null) return false;
    final saved = await _repository!.loadGame();
    if (saved == null) return false;
    _state = saved;
    applyOfflineEarnings();
    return true;
  }

  // ─── Prestige ────────────────────────────────────────────────────────

  bool get canPrestige => PrestigeSystem.canPrestige(_state);

  GameNumber get nextPrestigeMultiplier =>
      PrestigeSystem.calculatePrestigeMultiplier(_state.totalCoinsEarned);

  /// Perform a prestige reset.
  bool prestige() {
    if (!canPrestige) return false;
    _state = PrestigeSystem.performPrestige(_state);
    saveGame();
    return true;
  }

  // ─── Tutorial ────────────────────────────────────────────────────────

  void completeTutorial() {
    _state = _state.copyWith(tutorialComplete: true);
  }

  // ─── Achievements ───────────────────────────────────────────────────

  void _checkAchievements() {
    if (_config.achievements.isEmpty) return;
    final newIds = AchievementSystem.checkAchievements(
      _state,
      _config.achievements,
      productionPerSecond,
    );
    if (newIds.isNotEmpty) {
      _state = AchievementSystem.applyAchievements(_state, newIds);
      lastUnlockedAchievements = _config.achievements
          .where((a) => newIds.contains(a.id))
          .toList();
    } else {
      lastUnlockedAchievements = [];
    }
  }
}

