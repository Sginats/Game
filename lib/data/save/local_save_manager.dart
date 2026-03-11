import 'save_manager.dart';

/// In-memory save manager for testing and initial development.
/// Will be replaced with SharedPreferences or file-based storage.
class InMemorySaveManager implements SaveManager {
  Map<String, dynamic>? _savedState;

  @override
  Future<Map<String, dynamic>?> loadGameState() async {
    return _savedState != null
        ? Map<String, dynamic>.from(_savedState!)
        : null;
  }

  @override
  Future<void> saveGameState(Map<String, dynamic> state) async {
    _savedState = Map<String, dynamic>.from(state);
  }

  @override
  Future<void> deleteSave() async {
    _savedState = null;
  }
}
