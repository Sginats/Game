import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

/// Audio and haptic feedback service for Room Zero.
///
/// Uses varied haptic patterns to provide satisfying, non-repetitive
/// feedback. Each interaction type has a distinct feel.
class GameAudioService {
  static const int _sndAsync = 0x0001;
  static const int _sndFilename = 0x00020000;
  static const int _sndNodefault = 0x0002;

  bool _enabled;
  double _musicVolume;
  double _sfxVolume;
  final _playSound = Platform.isWindows
      ? DynamicLibrary.open('winmm.dll').lookupFunction<
            Int32 Function(Pointer<Utf16>, IntPtr, Uint32),
            int Function(Pointer<Utf16>, int, int)
          >('PlaySoundW')
      : null;

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

  String? _resolveAssetPath(String assetName) {
    final candidates = <String>[
      '${Directory.current.path}${Platform.pathSeparator}assets${Platform.pathSeparator}audio${Platform.pathSeparator}$assetName',
      '${File(Platform.resolvedExecutable).parent.path}${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}assets${Platform.pathSeparator}audio${Platform.pathSeparator}$assetName',
    ];
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  Future<void> _playAsset(String assetName) async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    final path = _resolveAssetPath(assetName);
    if (path != null && _playSound != null) {
      final pointer = path.toNativeUtf16();
      try {
        _playSound!(
          pointer,
          0,
          _sndAsync | _sndFilename | _sndNodefault,
        );
        return;
      } finally {
        calloc.free(pointer);
      }
    }
  }

  Future<void> _playClick() async {
    await _playAsset('tap.wav');
    if (!Platform.isWindows) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _playAlert() async {
    await _playAsset('alert.wav');
    if (!Platform.isWindows) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Soft tap feedback — light and quick.
  Future<void> playTap() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playClick();
    await HapticFeedback.lightImpact();
  }

  /// Node selection — subtle selection click.
  Future<void> playNodeSelect() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playClick();
    await HapticFeedback.selectionClick();
  }

  /// Purchase success — satisfying medium impact.
  Future<void> playPurchase() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playAsset('purchase.wav');
    await HapticFeedback.mediumImpact();
  }

  /// Insufficient funds — warning heavy buzz.
  Future<void> playInsufficientFunds() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playAlert();
    await HapticFeedback.heavyImpact();
  }

  /// Branch/milestone unlock — celebratory double pulse.
  Future<void> playBranchUnlock() async {
    if (!_enabled) return;
    await _playAsset('unlock.wav');
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// Milestone reached — strong vibration.
  Future<void> playMilestone() async {
    if (!_enabled) return;
    await _playAsset('milestone.wav');
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Reward claimed — light celebratory pulse.
  Future<void> playReward() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playAsset('purchase.wav');
    await HapticFeedback.mediumImpact();
  }

  /// Achievement unlocked — distinct triple pulse.
  Future<void> playAchievement() async {
    if (!_enabled) return;
    await _playAsset('milestone.wav');
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.heavyImpact();
  }

  /// UI button interactions — selection click.
  Future<void> playUiInteraction() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playClick();
    await HapticFeedback.selectionClick();
  }

  /// Entering a new room/era — medium transition feel.
  Future<void> playRoomEnter() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playAsset('unlock.wav');
    await HapticFeedback.mediumImpact();
  }

  /// Completing a room/era — strong accomplishment.
  Future<void> playRoomComplete() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playAsset('milestone.wav');
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// Event spawned — attention-grabbing pulse.
  Future<void> playEventSpawn() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playAsset('alert.wav');
    await HapticFeedback.heavyImpact();
  }

  /// Event resolved — resolution feedback.
  Future<void> playEventResolve() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playAsset('purchase.wav');
    await HapticFeedback.mediumImpact();
  }

  /// Secret discovered — mysterious subtle pulse.
  Future<void> playSecretDiscovered() async {
    if (!_enabled) return;
    await _playAsset('unlock.wav');
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.lightImpact();
  }

  /// Critical hit — sharp impact.
  Future<void> playCriticalHit() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playAsset('alert.wav');
    await HapticFeedback.heavyImpact();
  }

  /// Prestige — dramatic reset feel.
  Future<void> playPrestige() async {
    if (!_enabled) return;
    await _playAsset('milestone.wav');
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Combo milestone (every 10 combo) — rhythmic pulse.
  Future<void> playComboMilestone() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playAsset('tap.wav');
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  // ─── Room-specific audio layer ────────────────────────────────────

  /// Current ambient audio profile for room-based layering.
  String _currentRoomAudioProfile = 'default';

  /// The active room's audio profile (e.g., 'salvage', 'thermal', 'orbital').
  String get currentRoomAudioProfile => _currentRoomAudioProfile;

  /// Set the room audio profile when transitioning rooms.
  void setRoomAudioProfile(String profile) {
    _currentRoomAudioProfile = profile;
  }

  /// Room transformation stage change — environment evolving.
  Future<void> playTransformationAdvance() async {
    if (!_enabled) return;
    await _playAsset('unlock.wav');
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.selectionClick();
  }

  /// Room mid-scene twist activation — dramatic shift.
  Future<void> playRoomTwist() async {
    if (!_enabled) return;
    await _playAsset('alert.wav');
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Guide notification — subtle companion cue.
  Future<void> playGuideNotification() async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    await _playAsset('tap.wav');
    await HapticFeedback.selectionClick();
  }

  /// Rare event spawn — distinctive attention pulse.
  Future<void> playRareEventSpawn() async {
    if (!_enabled) return;
    await _playAsset('alert.wav');
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }

  /// Room transition cue — smooth crossfade feel.
  Future<void> playRoomTransition() async {
    if (!_enabled) return;
    await _playAsset('unlock.wav');
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.mediumImpact();
  }

  /// Relic acquired — meta-progression reward.
  Future<void> playRelicAcquired() async {
    if (!_enabled) return;
    await _playAsset('milestone.wav');
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
