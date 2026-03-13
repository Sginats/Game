import 'package:flutter/services.dart';

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

  Future<void> playTap() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playNodeSelect() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playPurchase() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    HapticFeedback.selectionClick();
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playInsufficientFunds() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    HapticFeedback.heavyImpact();
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> playBranchUnlock() async {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> playMilestone() async {
    if (!_enabled) return;
    HapticFeedback.vibrate();
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> playReward() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> playUiInteraction() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playRoomEnter() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    HapticFeedback.lightImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playRoomComplete() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> playEventSpawn() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await SystemSound.play(SystemSoundType.alert);
  }
}
