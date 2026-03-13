import '../../domain/models/game_state.dart';
import '../save/save_manager.dart';

/// Repository that orchestrates save/load with domain models.
class GameRepository {
  final SaveManager _saveManager;

  GameRepository(this._saveManager);

  Future<GameState?> loadGame() async {
    final data = await _saveManager.loadGameState();
    if (data == null) return null;
    final revision = data['economyRevision'] as int? ?? 0;
    if (revision != GameState.currentEconomyRevision) {
      return GameState.initial().copyWith(
        tutorialComplete: data['tutorialComplete'] as bool? ?? false,
      );
    }
    return GameState.fromJson(data);
  }

  Future<void> saveGame(GameState state) async {
    await _saveManager.saveGameState(state.toJson());
  }

  Future<void> deleteSave() async {
    await _saveManager.deleteSave();
  }
}
