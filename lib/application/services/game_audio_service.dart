import 'package:flutter/services.dart';

/// Audio and haptic feedback service for Room Zero.
///
/// Uses varied haptic patterns to provide satisfying, non-repetitive
/// feedback. Each interaction type has a distinct feel.
class GameAudioService {
  bool _enabled;
  double _musicVolume;
  double _sfxVolume;

  GameAudioService({
    bool enabled = true,
    double musicVolume = 0.65,
    double sfxVolume = 0.85,
  })  : _enabled = enabled,
        _musicVolume = musicVolume,
        _sfxVolume = sfxVolume;

  bool get enabled => _enabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  void setEnabled(bool value) {
    _enabled = value;
  }

  void configureVolumes({
    double? musicVolume,
    double? sfxVolume,
  }) {
    _musicVolume = musicVolume ?? _musicVolume;
    _sfxVolume = sfxVolume ?? _sfxVolume;
  }

  String get currentMusicLayer {
    if (_musicVolume <= 0.05 || !_enabled) return 'muted';
    if (_musicVolume < 0.4) return 'ambient';
    if (_musicVolume < 0.75) return 'drive';
    return 'intense';
  }

  /// Soft tap feedback — light and quick.
  Future<void> playTap() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await HapticFeedback.lightImpact();
  }

  /// Node selection — subtle selection click.
  Future<void> playNodeSelect() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await HapticFeedback.selectionClick();
  }

  /// Purchase success — satisfying medium impact.
  Future<void> playPurchase() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await HapticFeedback.mediumImpact();
  }

  /// Insufficient funds — warning heavy buzz.
  Future<void> playInsufficientFunds() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await HapticFeedback.heavyImpact();
  }

  /// Branch/milestone unlock — celebratory double pulse.
  Future<void> playBranchUnlock() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// Milestone reached — strong vibration.
  Future<void> playMilestone() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Reward claimed — light celebratory pulse.
  Future<void> playReward() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await HapticFeedback.mediumImpact();
  }

  /// Achievement unlocked — distinct triple pulse.
  Future<void> playAchievement() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.heavyImpact();
  }

  /// UI button interactions — selection click.
  Future<void> playUiInteraction() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await HapticFeedback.selectionClick();
  }

  /// Entering a new room/era — medium transition feel.
  Future<void> playRoomEnter() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await HapticFeedback.mediumImpact();
  }

  /// Completing a room/era — strong accomplishment.
  Future<void> playRoomComplete() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// Event spawned — attention-grabbing pulse.
  Future<void> playEventSpawn() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await HapticFeedback.heavyImpact();
  }

  /// Event resolved — resolution feedback.
  Future<void> playEventResolve() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await HapticFeedback.mediumImpact();
  }

  /// Secret discovered — mysterious subtle pulse.
  Future<void> playSecretDiscovered() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.lightImpact();
  }

  /// Critical hit — sharp impact.
  Future<void> playCriticalHit() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await HapticFeedback.heavyImpact();
  }

  /// Prestige — dramatic reset feel.
  Future<void> playPrestige() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Combo milestone (every 10 combo) — rhythmic pulse.
  Future<void> playComboMilestone() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }
}
