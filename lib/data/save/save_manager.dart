/// Interface for save/load operations.
abstract class SaveManager {
  Future<Map<String, dynamic>?> loadGameState();
  Future<void> saveGameState(Map<String, dynamic> state);
  Future<void> deleteSave();
}
