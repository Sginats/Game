import 'dart:ffi';
import 'dart:io';

import '../../domain/models/gameplay_extensions.dart';
import '../../domain/models/room_scene.dart';
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
  static const String _ambientAlias = 'room_zero_ambient';

  bool _enabled;
  double _musicVolume;
  double _sfxVolume;
  final DynamicLibrary? _winmm =
      Platform.isWindows ? DynamicLibrary.open('winmm.dll') : null;
  late final int Function(Pointer<Utf16>, int, int)? _playSound = _winmm
      ?.lookupFunction<
          Int32 Function(Pointer<Utf16>, IntPtr, Uint32),
          int Function(Pointer<Utf16>, int, int)>('PlaySoundW');
  late final int Function(Pointer<Utf16>, Pointer<Utf16>, int, int)?
      _mciSendString = _winmm?.lookupFunction<
          Int32 Function(Pointer<Utf16>, Pointer<Utf16>, Uint32, IntPtr),
          int Function(Pointer<Utf16>, Pointer<Utf16>, int, int)>(
        'mciSendStringW',
      );
  String? _activeAmbientPath;

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
    if (!_enabled) {
      stopAmbientLoop();
    }
  }

  void configureVolumes({
    double? musicVolume,
    double? sfxVolume,
  }) {
    _musicVolume = musicVolume ?? _musicVolume;
    _sfxVolume = sfxVolume ?? _sfxVolume;
    if (_musicVolume <= 0.05 || !_enabled) {
      stopAmbientLoop();
    }
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

  Future<void> _sendMci(String command) async {
    if (_mciSendString == null) return;
    final pointer = command.toNativeUtf16();
    try {
      _mciSendString!(pointer, nullptr, 0, 0);
    } finally {
      calloc.free(pointer);
    }
  }

  String? _resolveAmbientAssetPath(
    AmbientAudioLayer layer,
    String roomId,
    String fallbackSuffix,
  ) {
    final direct = layer.assetPath.replaceAll('assets/audio/', '');
    final directResolved = _resolveAssetPath(direct);
    if (directResolved != null) {
      return directResolved;
    }
    return _resolveAssetPath('rooms/$roomId$fallbackSuffix.wav');
  }

  String _roomScopedId(String? roomId) {
    final scoped = roomId ?? _currentRoomAudioProfile;
    return scoped.isEmpty ? 'default' : scoped;
  }

  Future<void> _playResolvedPath(String path) async {
    if (!_enabled || _sfxVolume <= 0.05 || _playSound == null) return;
    final pointer = path.toNativeUtf16();
    try {
      _playSound!(
        pointer,
        0,
        _sndAsync | _sndFilename | _sndNodefault,
      );
    } finally {
      calloc.free(pointer);
    }
  }

  Future<void> _playFirstAvailableAsset(List<String> assetNames) async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    for (final assetName in assetNames) {
      final path = _resolveAssetPath(assetName);
      if (path != null) {
        await _playResolvedPath(path);
        return;
      }
    }
  }

  Future<void> _playAsset(String assetName) async {
    await _playFirstAvailableAsset([assetName]);
  }

  bool _ambientLayerMatches(
    AmbientAudioLayer layer,
    RoomSceneState roomState,
  ) {
    final trigger = layer.triggerCondition.trim().toLowerCase();
    if (trigger.isEmpty || trigger == 'always') return true;
    if (trigger.contains('twist')) return roomState.twistActivated;

    final stageMatch = RegExp(r'stage\s*>=\s*(\d+)').firstMatch(trigger);
    if (stageMatch != null) {
      final required = int.tryParse(stageMatch.group(1) ?? '') ?? 0;
      return (roomState.currentTransformationStage + 1) >= required;
    }

    final upgradeMatch = RegExp(
      r'upgrades_purchased\s*>\s*(\d+)',
    ).firstMatch(trigger);
    if (upgradeMatch != null) {
      final required = int.tryParse(upgradeMatch.group(1) ?? '') ?? 0;
      return roomState.upgradesPurchased > required;
    }

    return false;
  }

  int _ambientLayerPriority(AmbientAudioLayer layer) {
    final trigger = layer.triggerCondition.trim().toLowerCase();
    if (trigger.contains('twist')) return 40;
    final stageMatch = RegExp(r'stage\s*>=\s*(\d+)').firstMatch(trigger);
    if (stageMatch != null) {
      return 20 + (int.tryParse(stageMatch.group(1) ?? '') ?? 0);
    }
    final upgradeMatch = RegExp(
      r'upgrades_purchased\s*>\s*(\d+)',
    ).firstMatch(trigger);
    if (upgradeMatch != null) {
      return 10 + ((int.tryParse(upgradeMatch.group(1) ?? '') ?? 0) ~/ 10);
    }
    return 0;
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
  Future<void> playRoomEnter({String? roomId}) async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    final scopedRoomId = _roomScopedId(roomId);
    await _playFirstAvailableAsset([
      'rooms/${scopedRoomId}_transition.wav',
      'unlock.wav',
    ]);
    await HapticFeedback.mediumImpact();
  }

  /// Completing a room/era — strong accomplishment.
  Future<void> playRoomComplete({String? roomId}) async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    final scopedRoomId = _roomScopedId(roomId);
    await _playFirstAvailableAsset([
      'rooms/${scopedRoomId}_complete.wav',
      'milestone.wav',
    ]);
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// Event spawned — attention-grabbing pulse.
  Future<void> playEventSpawn({
    String? roomId,
    EventRarity rarity = EventRarity.common,
  }) async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    final scopedRoomId = _roomScopedId(roomId);
    await _playFirstAvailableAsset([
      'rooms/${scopedRoomId}_event_${rarity.name}.wav',
      rarity.index >= EventRarity.rare.index ? 'alert.wav' : 'tap.wav',
    ]);
    if (rarity.index >= EventRarity.epic.index) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 70));
      await HapticFeedback.mediumImpact();
      return;
    }
    if (rarity.index >= EventRarity.rare.index) {
      await HapticFeedback.heavyImpact();
      return;
    }
    await HapticFeedback.mediumImpact();
  }

  /// Event resolved — resolution feedback.
  Future<void> playEventResolve({
    String? roomId,
    EventRarity rarity = EventRarity.common,
  }) async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    final scopedRoomId = _roomScopedId(roomId);
    await _playFirstAvailableAsset([
      'rooms/${scopedRoomId}_resolve.wav',
      'purchase.wav',
    ]);
    await HapticFeedback.mediumImpact();
    if (rarity.index >= EventRarity.epic.index) {
      await Future.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.lightImpact();
    }
  }

  /// Secret discovered — mysterious subtle pulse.
  Future<void> playSecretDiscovered({String? roomId}) async {
    if (!_enabled) return;
    final scopedRoomId = _roomScopedId(roomId);
    await _playFirstAvailableAsset([
      'rooms/${scopedRoomId}_secret.wav',
      'unlock.wav',
    ]);
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

  Future<void> syncAmbientForRoom(
    RoomScene? room,
    RoomSceneState? roomState,
  ) async {
    if (room == null || roomState == null) {
      await stopAmbientLoop();
      return;
    }
    if (!_enabled || _musicVolume <= 0.05 || room.ambientAudioLayers.isEmpty) {
      await stopAmbientLoop();
      return;
    }

    AmbientAudioLayer? selected;
    var selectedPriority = -1;
    for (final layer in room.ambientAudioLayers) {
      if (!_ambientLayerMatches(layer, roomState)) continue;
      final priority = _ambientLayerPriority(layer);
      if (priority >= selectedPriority) {
        selected = layer;
        selectedPriority = priority;
      }
    }
    selected ??= room.ambientAudioLayers.first;

    final suffix = selected.id.contains('twist')
        ? '_twist'
        : selected.id.contains('active')
            ? '_active'
            : '_ambient';
    final path = _resolveAmbientAssetPath(selected, room.id, suffix);
    if (path == null || path == _activeAmbientPath) return;

    await stopAmbientLoop();
    _activeAmbientPath = path;
    final escaped = path.replaceAll('"', '""');
    await _sendMci('open "$escaped" type waveaudio alias $_ambientAlias');
    await _sendMci('play $_ambientAlias repeat');
  }

  Future<void> stopAmbientLoop() async {
    if (_activeAmbientPath == null) return;
    await _sendMci('stop $_ambientAlias');
    await _sendMci('close $_ambientAlias');
    _activeAmbientPath = null;
  }

  /// Room transformation stage change — environment evolving.
  Future<void> playTransformationAdvance({String? roomId}) async {
    if (!_enabled) return;
    final scopedRoomId = _roomScopedId(roomId);
    await _playFirstAvailableAsset([
      'rooms/${scopedRoomId}_transform.wav',
      'unlock.wav',
    ]);
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.selectionClick();
  }

  /// Room mid-scene twist activation — dramatic shift.
  Future<void> playRoomTwist({String? roomId}) async {
    if (!_enabled) return;
    final scopedRoomId = _roomScopedId(roomId);
    await _playFirstAvailableAsset([
      'rooms/${scopedRoomId}_twist_cue.wav',
      'alert.wav',
    ]);
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Guide notification — subtle companion cue.
  Future<void> playGuideNotification({String? roomId}) async {
    if (!_enabled || _sfxVolume <= 0.05) return;
    final scopedRoomId = _roomScopedId(roomId);
    await _playFirstAvailableAsset([
      'rooms/${scopedRoomId}_guide.wav',
      'tap.wav',
    ]);
    await HapticFeedback.selectionClick();
  }

  /// Rare event spawn — distinctive attention pulse.
  Future<void> playRareEventSpawn({String? roomId}) async {
    await playEventSpawn(roomId: roomId, rarity: EventRarity.rare);
  }

  /// Room transition cue — smooth crossfade feel.
  Future<void> playRoomTransition({String? roomId}) async {
    if (!_enabled) return;
    final scopedRoomId = _roomScopedId(roomId);
    await _playFirstAvailableAsset([
      'rooms/${scopedRoomId}_transition.wav',
      'unlock.wav',
    ]);
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

  // ─── Preload / warm-start ─────────────────────────────────────────

  /// Warm-start the essential audio assets for [roomId] so that first
  /// playback does not hitch.
  ///
  /// The method resolves file paths for the most likely-needed sounds
  /// (ambient layer, transition cue, guide ping, rare-event cue, and
  /// the common interaction click) and opens-then-immediately-closes each
  /// WAV file via MCI. This forces the OS audio subsystem to map the
  /// file into its internal buffer so the first real `play` call returns
  /// near-instantly.
  ///
  /// The operation is intentionally non-blocking: the caller should fire
  /// it with `unawaited()` after a room transition so it does not delay
  /// the UI thread.
  Future<void> preloadEssentials({required String roomId}) async {
    if (!_enabled) return;
    final candidates = _preloadAssetNames(roomId);
    for (final name in candidates) {
      final path = _resolveAssetPath(name);
      if (path != null) {
        await _warmPath(path);
      }
    }
  }

  /// Returns the ordered list of asset file names to warm for [roomId].
  ///
  /// Exposed as a public method for testing. Production callers should use
  /// [preloadEssentials] which calls this internally.
  // ignore: invalid_use_of_visible_for_testing_member
  List<String> preloadAssetNamesForRoom(String roomId) =>
      _preloadAssetNames(roomId);

  List<String> _preloadAssetNames(String roomId) {
    return [
      // Current-room ambient layer
      'rooms/${roomId}_ambient.wav',
      // Room transition cue
      'rooms/${roomId}_transition.wav',
      // Guide notification ping
      'rooms/${roomId}_guide.wav',
      // Rare event cue (high-priority: audible gap on first trigger is jarring)
      'rooms/${roomId}_event_rare.wav',
      // Global fallbacks used when room-specific files are absent
      'tap.wav',
      'unlock.wav',
      'alert.wav',
    ];
  }

  /// Open and immediately close [path] via MCI to warm the audio buffer.
  Future<void> _warmPath(String path) async {
    if (_mciSendString == null) return;
    const warmAlias = 'preload_warm';
    final escaped = path.replaceAll('"', '""');
    await _sendMci('open "$escaped" type waveaudio alias $warmAlias');
    await _sendMci('close $warmAlias');
  }
}
