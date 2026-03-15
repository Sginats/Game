import 'package:ai_evolution/application/services/robot_guide_service.dart';
import 'package:ai_evolution/domain/models/robot_guide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RobotGuideService enhanced methods', () {
    // Helper: creates a guide with _lastRoomId set, drains all non-trigger
    // messages so the trigger-only messages ('_on_first_*') remain unshown.
    RobotGuideService _freshGuide({String roomId = 'room_01'}) {
      final guide = RobotGuideService();
      guide.onRoomChanged(roomId);
      while (guide.hasMessage) {
        guide.dismiss();
      }
      return guide;
    }

    // ─── onRoomChanged auto-queueing ─────────────────────────────────────

    test('onRoomChanged room_01 shows room intro message first', () {
      final guide = RobotGuideService();
      guide.onRoomChanged('room_01');
      expect(guide.hasMessage, isTrue);
      // room_01_intro has priority 9 — the highest among non-trigger messages
      expect(guide.currentMessage!.id, 'room_01_intro');
      expect(guide.currentMessage!.type, RobotGuideMessageType.roomIntro);
    });

    test('onRoomChanged does not auto-queue _on_first_ trigger messages', () {
      final guide = RobotGuideService();
      guide.onRoomChanged('room_01');
      final queued = <String>[];
      while (guide.hasMessage) {
        queued.add(guide.currentMessage!.id);
        guide.dismiss();
      }
      expect(queued.any((id) => id.contains('_on_first_')), isFalse);
    });

    // ─── onFirstTap ─────────────────────────────────────────────────────

    test('onFirstTap() shows room_01_on_first_interaction after entering room', () {
      // _freshGuide drains non-trigger messages; on_first_interaction is still unseen
      final guide = _freshGuide();
      guide.onFirstTap();
      expect(guide.hasMessage, isTrue);
      expect(guide.currentMessage!.id, 'room_01_on_first_interaction');
      expect(guide.currentMessage!.type, RobotGuideMessageType.tutorial);
    });

    test('onFirstTap() does not repeat after dismissal', () {
      final guide = _freshGuide();
      guide.onFirstTap();
      expect(guide.hasMessage, isTrue);
      guide.dismiss();

      guide.onFirstTap();
      expect(guide.hasMessage, isFalse);
    });

    test('onFirstTap() shows nothing for a room with no first-interaction message', () {
      final guide = _freshGuide(roomId: 'room_05');
      guide.onFirstTap();
      expect(guide.hasMessage, isFalse);
    });

    // ─── onFirstUpgradePurchased ─────────────────────────────────────────

    test('onFirstUpgradePurchased() shows the room_01 first upgrade message', () {
      final guide = _freshGuide();
      guide.onFirstUpgradePurchased();
      expect(guide.hasMessage, isTrue);
      expect(guide.currentMessage!.id, 'room_01_on_first_upgrade');
      expect(guide.currentMessage!.type, RobotGuideMessageType.milestone);
    });

    test('onFirstUpgradePurchased() does not repeat after dismissal', () {
      final guide = _freshGuide();
      guide.onFirstUpgradePurchased();
      expect(guide.hasMessage, isTrue);
      guide.dismiss();

      guide.onFirstUpgradePurchased();
      expect(guide.hasMessage, isFalse);
    });

    // ─── onFirstEventAppeared ────────────────────────────────────────────

    test('onFirstEventAppeared() shows the room_01_on_first_event message', () {
      final guide = _freshGuide();
      guide.onFirstEventAppeared();
      expect(guide.hasMessage, isTrue);
      expect(guide.currentMessage!.id, 'room_01_on_first_event');
      expect(guide.currentMessage!.type, RobotGuideMessageType.warning);
    });

    test('onFirstEventAppeared() falls back to generic tip after room msg shown', () {
      final guide = _freshGuide();
      guide.onFirstEventAppeared();
      guide.dismiss(); // marks room_01_on_first_event as shown

      guide.onFirstEventAppeared();
      // Falls back to the generic event_active tip
      expect(guide.hasMessage, isTrue);
      expect(guide.currentMessage!.id, 'tip_event');
    });

    // ─── onRoomLawExplained ──────────────────────────────────────────────

    test('onRoomLawExplained(room_01) shows the room_01_first_law message', () {
      final guide = _freshGuide();
      guide.onRoomLawExplained('room_01');
      expect(guide.hasMessage, isTrue);
      expect(guide.currentMessage!.id, 'room_01_first_law');
      expect(guide.currentMessage!.type, RobotGuideMessageType.tutorial);
    });

    test('onRoomLawExplained(room_01) does not repeat after dismissal', () {
      final guide = _freshGuide();
      guide.onRoomLawExplained('room_01');
      expect(guide.hasMessage, isTrue);
      guide.dismiss();

      guide.onRoomLawExplained('room_01');
      expect(guide.hasMessage, isFalse);
    });

    test('onRoomLawExplained for unknown room does nothing', () {
      final guide = _freshGuide();
      guide.onRoomLawExplained('room_99');
      expect(guide.hasMessage, isFalse);
    });

    // ─── onSideActivityDiscovered ────────────────────────────────────────

    test('onSideActivityDiscovered() shows the side activity hint for room_01', () {
      final guide = _freshGuide();
      guide.onSideActivityDiscovered('scrap_pile');
      expect(guide.hasMessage, isTrue);
      expect(guide.currentMessage!.id, 'room_01_side_activity_hint');
    });

    test('onSideActivityDiscovered() does not repeat after dismissal', () {
      final guide = _freshGuide();
      guide.onSideActivityDiscovered('scrap_pile');
      guide.dismiss();

      guide.onSideActivityDiscovered('scrap_pile');
      expect(guide.hasMessage, isFalse);
    });

    // ─── Dialogue content checks ─────────────────────────────────────────

    test('room_01 specific lines include all required message IDs', () {
      final lines = RobotGuideDialogue.roomSpecificLines['room_01'];
      expect(lines, isNotNull);
      expect(lines!.length, greaterThan(1));

      final ids = lines.map((m) => m.id).toSet();
      expect(ids.contains('room_01_intro'), isTrue);
      expect(ids.contains('room_01_first_law'), isTrue);
      expect(ids.contains('room_01_secret_hint'), isTrue);
      expect(ids.contains('room_01_side_activity_hint'), isTrue);
      expect(ids.contains('room_01_transformation_1'), isTrue);
      expect(ids.contains('room_01_on_first_interaction'), isTrue);
      expect(ids.contains('room_01_on_first_event'), isTrue);
      expect(ids.contains('room_01_on_first_upgrade'), isTrue);
      expect(ids.contains('room_01_room_goal'), isTrue);
    });

    test('room_01_on_first_interaction has the highest priority in room_01 lines', () {
      final lines = RobotGuideDialogue.roomSpecificLines['room_01']!;
      final firstInteraction =
          lines.firstWhere((m) => m.id == 'room_01_on_first_interaction');
      final maxPriority = lines.map((m) => m.priority).reduce(
            (a, b) => a > b ? a : b,
          );
      expect(firstInteraction.priority, equals(maxPriority));
    });

    test('room_01_first_law text mentions SALVAGE MODE', () {
      final lines = RobotGuideDialogue.roomSpecificLines['room_01']!;
      final law = lines.firstWhere((m) => m.id == 'room_01_first_law');
      expect(law.text.contains('SALVAGE MODE'), isTrue);
    });

    test('room_01_intro text mentions Junk Corner', () {
      final lines = RobotGuideDialogue.roomSpecificLines['room_01']!;
      final intro = lines.firstWhere((m) => m.id == 'room_01_intro');
      expect(intro.text.contains('Junk Corner'), isTrue);
    });
  });
}

