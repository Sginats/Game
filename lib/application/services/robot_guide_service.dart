import '../../domain/models/robot_guide.dart';

/// Service that provides contextual robot guide messages based on game state.
/// Pure Dart — no Flutter imports.
class RobotGuideService {
  final Set<String> _shownMessageIds = {};
  final List<RobotGuideMessage> _messageQueue = [];
  RobotGuideMessage? _currentMessage;
  String _lastEraId = '';
  String _lastRoomId = '';
  int _lastTrustTier = 0;
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

  /// Called when the player enters a new room.
  ///
  /// Messages whose IDs contain `_on_first_` are trigger-only and are not
  /// auto-queued on room entry — they fire through dedicated hooks such as
  /// [onFirstTap], [onFirstUpgradePurchased], and [onFirstEventAppeared].
  void onRoomChanged(String roomId, {int trustTier = 1}) {
    if (roomId == _lastRoomId) return;
    _lastRoomId = roomId;
    final roomLines =
        RobotGuideDialogue.roomSpecificLines[roomId] ?? const [];
    for (final msg in roomLines) {
      if (msg.id.contains('_on_first_')) continue;
      if (!_shownMessageIds.contains(msg.id) &&
          trustTier >= msg.minTrustTier) {
        _enqueue(msg);
      }
    }
  }

  /// Called when trust tier changes.
  void onTrustTierChanged(int trustTier) {
    if (trustTier == _lastTrustTier) return;
    final previousTier = _lastTrustTier;
    _lastTrustTier = trustTier;
    // Show trust unlock messages for any newly reached tiers
    for (var tier = previousTier + 1; tier <= trustTier; tier++) {
      final messages = RobotGuideDialogue.trustTierMessages[tier] ?? const [];
      for (final msg in messages) {
        if (!_shownMessageIds.contains(msg.id)) {
          _enqueue(msg);
        }
      }
    }
  }

  /// Called when the player takes a risky or unusual action.
  void onDisagreement({int trustTier = 1}) {
    for (final msg in RobotGuideDialogue.disagreementLines) {
      if (!_shownMessageIds.contains(msg.id) &&
          trustTier >= msg.minTrustTier) {
        _enqueue(msg);
        return; // Only one disagreement at a time
      }
    }
  }

  /// Called when a room twist activates.
  void onRoomTwist() {
    final tips = RobotGuideDialogue.contextualTips['room_twist'] ?? const [];
    for (final msg in tips) {
      if (!_shownMessageIds.contains(msg.id)) {
        _enqueue(msg);
        return;
      }
    }
  }

  /// Called when a secret is found.
  void onSecretFound() {
    final tips = RobotGuideDialogue.contextualTips['secret_found'] ?? const [];
    for (final msg in tips) {
      if (!_shownMessageIds.contains(msg.id)) {
        _enqueue(msg);
        return;
      }
    }
  }

  /// Called when a room transformation stage advances.
  void onTransformation() {
    final tips = RobotGuideDialogue.contextualTips['transformation'] ?? const [];
    for (final msg in tips) {
      if (!_shownMessageIds.contains(msg.id)) {
        _enqueue(msg);
        return;
      }
    }
  }

  /// Called when the current room advances a transformation stage.
  ///
  /// Shows the room-specific `_transformation_*` line if not yet shown,
  /// then falls back to the generic transformation tip.
  void onTransformationStageAdvanced(String roomId) {
    final roomLines =
        RobotGuideDialogue.roomSpecificLines[roomId] ?? const [];
    for (final msg in roomLines) {
      if (msg.id.contains('_transformation_')) {
        if (!_shownMessageIds.contains(msg.id)) {
          _enqueue(msg);
          return;
        }
      }
    }
    // Fallback to generic transformation tip
    onTransformation();
  }

  /// Called on the player's very first tap to show an onboarding message.
  void onFirstTap() {
    final roomLines =
        RobotGuideDialogue.roomSpecificLines[_lastRoomId] ?? const [];
    for (final msg in roomLines) {
      if (msg.id.endsWith('_on_first_interaction')) {
        if (!_shownMessageIds.contains(msg.id)) {
          _enqueue(msg);
          return;
        }
      }
    }
  }

  /// Called when the player purchases their first upgrade.
  void onFirstUpgradePurchased() {
    final roomLines =
        RobotGuideDialogue.roomSpecificLines[_lastRoomId] ?? const [];
    for (final msg in roomLines) {
      if (msg.id.endsWith('_on_first_upgrade')) {
        if (!_shownMessageIds.contains(msg.id)) {
          _enqueue(msg);
          return;
        }
      }
    }
  }

  /// Called when the first event appears in the current room.
  void onFirstEventAppeared() {
    final roomLines =
        RobotGuideDialogue.roomSpecificLines[_lastRoomId] ?? const [];
    for (final msg in roomLines) {
      if (msg.id.endsWith('_on_first_event')) {
        if (!_shownMessageIds.contains(msg.id)) {
          _enqueue(msg);
          return;
        }
      }
    }
    // Fallback to generic event tip
    final tips = RobotGuideDialogue.contextualTips['event_active'] ?? const [];
    for (final msg in tips) {
      if (!_shownMessageIds.contains(msg.id)) {
        _enqueue(msg);
        return;
      }
    }
  }

  /// Called to explain the room law for a given room.
  void onRoomLawExplained(String roomId) {
    final roomLines =
        RobotGuideDialogue.roomSpecificLines[roomId] ?? const [];
    for (final msg in roomLines) {
      if (msg.id.endsWith('_first_law') || msg.id.endsWith('_room_law')) {
        if (!_shownMessageIds.contains(msg.id)) {
          _enqueue(msg);
          return;
        }
      }
    }
  }

  /// Called when a side activity is first discovered.
  void onSideActivityDiscovered(String activityId) {
    final roomLines =
        RobotGuideDialogue.roomSpecificLines[_lastRoomId] ?? const [];
    for (final msg in roomLines) {
      if (msg.id.endsWith('_side_activity_hint')) {
        if (!_shownMessageIds.contains(msg.id)) {
          _enqueue(msg);
          return;
        }
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
    int trustTier = 1,
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

    // Trust-tier check
    onTrustTierChanged(trustTier);

    // Contextual tips
    if (_currentMessage == null && _tipTimer <= 0) {
      final tip = _selectContextualTip(
        totalTaps: totalTaps,
        tapCombo: tapCombo,
        eventActive: eventActive,
        prestigeCount: prestigeCount,
        coins: coins,
        highestEraOrder: highestEraOrder,
        trustTier: trustTier,
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
    // Prevent duplicate entries: skip if already in the queue or currently shown.
    if (_currentMessage?.id == message.id) return;
    if (_messageQueue.any((m) => m.id == message.id)) return;
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
    int trustTier = 1,
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
    // At higher trust, provide room-specific hints
    if (trustTier >= 3 && _lastRoomId.isNotEmpty) {
      final roomHints = RobotGuideDialogue.roomSpecificLines[_lastRoomId];
      if (roomHints != null) {
        final hint = _firstUnshownWithTrust(roomHints, trustTier);
        if (hint != null) return hint;
      }
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

  RobotGuideMessage? _firstUnshownWithTrust(
    List<RobotGuideMessage> messages,
    int trustTier,
  ) {
    for (final msg in messages) {
      if (!_shownMessageIds.contains(msg.id) &&
          trustTier >= msg.minTrustTier) {
        return msg;
      }
    }
    return null;
  }
}
