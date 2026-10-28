import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/models/gameplay_extensions.dart';
import '../../domain/models/room_scene.dart';

class GameAudioService {
  bool _enabled;
  double _musicVolume;
  double _sfxVolume;
  String _currentRoomAudioProfile = 'default';

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

  String get currentMusicLayer {
    if (!_enabled || _musicVolume <= 0.05) return 'muted';
    if (_musicVolume < 0.4) return 'ambient';
    if (_musicVolume < 0.75) return 'drive';
    return 'intense';
  }

  String get currentRoomAudioProfile => _currentRoomAudioProfile;

  void setEnabled(bool value) {
    _enabled = value;
    if (!value) unawaited(stopAmbientLoop());
  }

  void configureVolumes({double? musicVolume, double? sfxVolume}) {
    _musicVolume = (musicVolume ?? _musicVolume).clamp(0.0, 1.0).toDouble();
    _sfxVolume = (sfxVolume ?? _sfxVolume).clamp(0.0, 1.0).toDouble();
    if (!_enabled || _musicVolume <= 0.05) unawaited(stopAmbientLoop());
  }

  void setRoomAudioProfile(String profile) {
    _currentRoomAudioProfile = profile;
  }

  Future<void> _safeFeedback(Future<void> Function() feedback) async {
    if (!_enabled) return;
    try {
      await feedback();
    } catch (_) {
      // Browser and device capabilities vary; feedback must never block play.
    }
  }

  Future<void> _tap() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _safeFeedback(() => SystemSound.play(SystemSoundType.click));
  }

  Future<void> _alert() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _safeFeedback(() => SystemSound.play(SystemSoundType.alert));
  }

  Future<void> _haptic(Future<void> Function() feedback) =>
      _safeFeedback(feedback);

  Future<void> playTap() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _tap();
    await _haptic(HapticFeedback.lightImpact);
  }

  Future<void> playNodeSelect() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _tap();
    await _haptic(HapticFeedback.selectionClick);
  }

  Future<void> playPurchase() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _tap();
    await _haptic(HapticFeedback.mediumImpact);
  }

  Future<void> playInsufficientFunds() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _alert();
    await _haptic(HapticFeedback.heavyImpact);
  }

  Future<void> playBranchUnlock() async {
    if (!_enabled) return;
    await _tap();
    await _haptic(HapticFeedback.mediumImpact);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await _haptic(HapticFeedback.lightImpact);
  }

  Future<void> playMilestone() async {
    if (!_enabled) return;
    await _alert();
    await _haptic(HapticFeedback.heavyImpact);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await _haptic(HapticFeedback.mediumImpact);
  }

  Future<void> playReward() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await playPurchase();
  }

  Future<void> playAchievement() async {
    if (!_enabled) return;
    await playMilestone();
    await _haptic(HapticFeedback.lightImpact);
  }

  Future<void> playUiInteraction() => playNodeSelect();

  Future<void> playRoomEnter({String? roomId}) async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await playBranchUnlock();
  }

  Future<void> playRoomComplete({String? roomId}) async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await playMilestone();
  }

  Future<void> playEventSpawn({
    String? roomId,
    EventRarity rarity = EventRarity.common,
  }) async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    if (rarity.index >= EventRarity.rare.index) {
      await _alert();
      await _haptic(HapticFeedback.heavyImpact);
    } else {
      await _tap();
      await _haptic(HapticFeedback.mediumImpact);
    }
  }

  Future<void> playEventResolve({
    String? roomId,
    EventRarity rarity = EventRarity.common,
  }) async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await playPurchase();
  }

  Future<void> playSecretDiscovered({String? roomId}) => playBranchUnlock();

  Future<void> playCriticalHit() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await playInsufficientFunds();
  }

  Future<void> playPrestige() => playMilestone();

  Future<void> playComboMilestone() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await playPurchase();
  }

  Future<void> syncAmbientForRoom(
    RoomScene? room,
    RoomSceneState? roomState,
  ) async {}

  Future<void> stopAmbientLoop() async {}

  Future<void> playTransformationAdvance({String? roomId}) => playBranchUnlock();

  Future<void> playRoomTwist({String? roomId}) => playCriticalHit();

  Future<void> playGuideNotification({String? roomId}) async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await playNodeSelect();
  }

  Future<void> playRareEventSpawn({String? roomId}) =>
      playEventSpawn(roomId: roomId, rarity: EventRarity.rare);

  Future<void> playRoomTransition({String? roomId}) => playRoomEnter(roomId: roomId);

  Future<void> playRelicAcquired() => playAchievement();

  Future<void> preloadEssentials({required String roomId}) async {}

  List<String> preloadAssetNamesForRoom(String roomId) => [
        'rooms/${roomId}_ambient.wav',
        'rooms/${roomId}_transition.wav',
        'rooms/${roomId}_guide.wav',
        'rooms/${roomId}_event_rare.wav',
        'tap.wav',
        'unlock.wav',
        'alert.wav',
      ];
}
