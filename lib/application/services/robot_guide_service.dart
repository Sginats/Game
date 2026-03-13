import '../../domain/models/robot_guide.dart';

/// Service that provides contextual robot guide messages based on game state.
/// Pure Dart — no Flutter imports.
class RobotGuideService {
  final Set<String> _shownMessageIds = {};
  final List<RobotGuideMessage> _messageQueue = [];
  RobotGuideMessage? _currentMessage;
  String _lastEraId = '';
  int _tutorialIndex = 0;
  double _messageTimer = 0;

  static const double _messageDuration = 12.0;
  static const double _tipCooldown = 30.0;
  static const int _prestigeHintMinTaps = 200;
  static const double _prestigeHintMinCoins = 500000;
  static const int _highComboThreshold = 50;
  double _tipTimer = 0;

  RobotGuideMessage? get currentMessage => _currentMessage;
  bool get hasMessage => _currentMessage != null;

  /// Called when the player enters a new era.
  void onEraChanged(String eraId) {
    if (eraId == _lastEraId) return;
    _lastEraId = eraId;
    final introMessages =
        RobotGuideDialogue.eraIntroductions[eraId] ?? const [];
    for (final msg in introMessages) {
      if (!_shownMessageIds.contains(msg.id)) {
        _enqueue(msg);
      }
    }
  }

  /// Called each game tick to update timers and advance tutorials.
  void tick(double deltaSeconds, {
    required int totalTaps,
    required int tapCombo,
    required bool eventActive,
    required int prestigeCount,
    required double coins,
    required int highestEraOrder,
  }) {
    _messageTimer -= deltaSeconds;
    _tipTimer -= deltaSeconds;

    if (_messageTimer <= 0 && _currentMessage != null) {
      _shownMessageIds.add(_currentMessage!.id);
      _currentMessage = null;
    }

    if (_currentMessage == null && _messageQueue.isNotEmpty) {
      _currentMessage = _messageQueue.removeAt(0);
      _messageTimer = _messageDuration;
      return;
    }

    // Advance tutorials for new players
    if (_tutorialIndex < RobotGuideDialogue.tutorials.length &&
        _currentMessage == null &&
        _tipTimer <= 0) {
      final tutorial = RobotGuideDialogue.tutorials[_tutorialIndex];
      if (_shouldShowTutorial(tutorial, totalTaps: totalTaps, prestigeCount: prestigeCount)) {
        _enqueue(tutorial);
        _tutorialIndex++;
        _tipTimer = _tipCooldown;
        return;
      }
    }

    // Contextual tips
    if (_currentMessage == null && _tipTimer <= 0) {
      final tip = _selectContextualTip(
        totalTaps: totalTaps,
        tapCombo: tapCombo,
        eventActive: eventActive,
        prestigeCount: prestigeCount,
        coins: coins,
        highestEraOrder: highestEraOrder,
      );
      if (tip != null) {
        _enqueue(tip);
        _tipTimer = _tipCooldown;
      }
    }
  }

  /// Dismiss the current message immediately.
  void dismiss() {
    if (_currentMessage != null) {
      _shownMessageIds.add(_currentMessage!.id);
      _currentMessage = null;
      _messageTimer = 0;
    }
  }

  void _enqueue(RobotGuideMessage message) {
    if (_shownMessageIds.contains(message.id)) return;
    // Insert by priority (higher first)
    var inserted = false;
    for (var i = 0; i < _messageQueue.length; i++) {
      if (message.priority > _messageQueue[i].priority) {
        _messageQueue.insert(i, message);
        inserted = true;
        break;
      }
    }
    if (!inserted) _messageQueue.add(message);

    // Show immediately if nothing is displayed
    if (_currentMessage == null) {
      _currentMessage = _messageQueue.removeAt(0);
      _messageTimer = _messageDuration;
    }
  }

  bool _shouldShowTutorial(RobotGuideMessage tutorial, {
    required int totalTaps,
    required int prestigeCount,
  }) {
    switch (tutorial.id) {
      case 'tut_tap':
        return totalTaps == 0;
      case 'tut_upgrade':
        return totalTaps >= 3;
      case 'tut_generator':
        return totalTaps >= 10;
      case 'tut_event':
        return totalTaps >= 30;
      case 'tut_prestige':
        return prestigeCount == 0 && totalTaps >= 100;
      default:
        return true;
    }
  }

  RobotGuideMessage? _selectContextualTip({
    required int totalTaps,
    required int tapCombo,
    required bool eventActive,
    required int prestigeCount,
    required double coins,
    required int highestEraOrder,
  }) {
    if (eventActive) {
      return _firstUnshown(RobotGuideDialogue.contextualTips['event_active']);
    }
    if (tapCombo > _highComboThreshold) {
      return _firstUnshown(RobotGuideDialogue.contextualTips['high_combo']);
    }
    if (prestigeCount == 0 && totalTaps > _prestigeHintMinTaps && coins > _prestigeHintMinCoins) {
      return _firstUnshown(RobotGuideDialogue.contextualTips['first_prestige']);
    }
    return null;
  }

  RobotGuideMessage? _firstUnshown(List<RobotGuideMessage>? messages) {
    if (messages == null) return null;
    for (final msg in messages) {
      if (!_shownMessageIds.contains(msg.id)) return msg;
    }
    return null;
  }
}
