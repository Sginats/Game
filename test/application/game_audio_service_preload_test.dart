/// Tests for pass-3 performance improvements:
/// - GameAudioService.preloadEssentials asset name generation
import 'package:ai_evolution/application/services/game_audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameAudioService preload asset names', () {
    late GameAudioService svc;

    setUp(() {
      svc = GameAudioService(enabled: true, musicVolume: 0.65, sfxVolume: 0.85);
    });

    test('returns 7 candidate names for a given roomId', () {
      final names = svc.preloadAssetNamesForRoom('salvage');
      expect(names.length, equals(7));
    });

    test('includes room-specific ambient, transition and guide assets', () {
      final names = svc.preloadAssetNamesForRoom('thermal');
      expect(names.contains('rooms/thermal_ambient.wav'), isTrue);
      expect(names.contains('rooms/thermal_transition.wav'), isTrue);
      expect(names.contains('rooms/thermal_guide.wav'), isTrue);
    });

    test('includes rare event cue for the room', () {
      final names = svc.preloadAssetNamesForRoom('orbital');
      expect(names.contains('rooms/orbital_event_rare.wav'), isTrue);
    });

    test('always includes global fallback assets', () {
      final names = svc.preloadAssetNamesForRoom('any_room');
      expect(names.contains('tap.wav'), isTrue);
      expect(names.contains('unlock.wav'), isTrue);
      expect(names.contains('alert.wav'), isTrue);
    });

    test('room-specific names come before fallbacks', () {
      final names = svc.preloadAssetNamesForRoom('salvage');
      final firstRoomSpecific =
          names.indexWhere((n) => n.startsWith('rooms/'));
      final firstFallback =
          names.indexWhere((n) => !n.startsWith('rooms/'));
      expect(firstRoomSpecific, lessThan(firstFallback));
    });

    test('different roomIds produce different room-specific names', () {
      final names1 = svc.preloadAssetNamesForRoom('room_01');
      final names2 = svc.preloadAssetNamesForRoom('room_02');
      final roomSpecific1 = names1.where((n) => n.startsWith('rooms/')).toList();
      final roomSpecific2 = names2.where((n) => n.startsWith('rooms/')).toList();
      expect(roomSpecific1, isNot(equals(roomSpecific2)));
    });

    test('preloadEssentials completes without throwing when disabled', () async {
      final disabled =
          GameAudioService(enabled: false, musicVolume: 0.0, sfxVolume: 0.0);
      await expectLater(
        disabled.preloadEssentials(roomId: 'any'),
        completes,
      );
    });
  });
}
