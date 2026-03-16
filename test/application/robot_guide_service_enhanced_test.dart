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

  // ─── Wave 1: Rooms 2–5 ───────────────────────────────────────────────────

  group('Wave 1 — Room 2 (Budget Setup)', () {
    RobotGuideService _fresh() {
      final g = RobotGuideService();
      g.onRoomChanged('room_02');
      while (g.hasMessage) g.dismiss();
      return g;
    }

    test('onRoomChanged room_02 shows room_02_intro first', () {
      final g = RobotGuideService();
      g.onRoomChanged('room_02');
      expect(g.hasMessage, isTrue);
      expect(g.currentMessage!.id, 'room_02_intro');
      expect(g.currentMessage!.type, RobotGuideMessageType.roomIntro);
    });

    test('room_02 has all required message IDs', () {
      final lines = RobotGuideDialogue.roomSpecificLines['room_02']!;
      final ids = lines.map((m) => m.id).toSet();
      expect(ids.contains('room_02_intro'), isTrue);
      expect(ids.contains('room_02_first_law'), isTrue);
      expect(ids.contains('room_02_room_goal'), isTrue);
      expect(ids.contains('room_02_transformation_1'), isTrue);
      expect(ids.contains('room_02_secret_hint'), isTrue);
      expect(ids.contains('room_02_side_activity_hint'), isTrue);
      expect(ids.contains('room_02_on_first_interaction'), isTrue);
      expect(ids.contains('room_02_on_first_upgrade'), isTrue);
      expect(ids.contains('room_02_on_first_event'), isTrue);
    });

    test('room_02 trigger messages do not auto-queue on room entry', () {
      final g = RobotGuideService();
      g.onRoomChanged('room_02');
      final queued = <String>[];
      while (g.hasMessage) {
        queued.add(g.currentMessage!.id);
        g.dismiss();
      }
      expect(queued.any((id) => id.contains('_on_first_')), isFalse);
    });

    test('onFirstTap fires room_02_on_first_interaction', () {
      final g = _fresh();
      g.onFirstTap();
      expect(g.hasMessage, isTrue);
      expect(g.currentMessage!.id, 'room_02_on_first_interaction');
    });

    test('onRoomLawExplained room_02 fires room_02_first_law', () {
      final g = _fresh();
      g.onRoomLawExplained('room_02');
      expect(g.hasMessage, isTrue);
      expect(g.currentMessage!.id, 'room_02_first_law');
    });

    test('onTransformationStageAdvanced room_02 fires transformation_1', () {
      final g = _fresh();
      g.onTransformationStageAdvanced('room_02');
      expect(g.hasMessage, isTrue);
      expect(g.currentMessage!.id, 'room_02_transformation_1');
    });
  });

  group('Wave 1 — Room 3 (Creator Room)', () {
    RobotGuideService _fresh() {
      final g = RobotGuideService();
      g.onRoomChanged('room_03');
      while (g.hasMessage) g.dismiss();
      return g;
    }

    test('room_03 has all required message IDs', () {
      final lines = RobotGuideDialogue.roomSpecificLines['room_03']!;
      final ids = lines.map((m) => m.id).toSet();
      expect(ids.contains('room_03_intro'), isTrue);
      expect(ids.contains('room_03_first_law'), isTrue);
      expect(ids.contains('room_03_room_goal'), isTrue);
      expect(ids.contains('room_03_transformation_1'), isTrue);
      expect(ids.contains('room_03_secret_hint'), isTrue);
      expect(ids.contains('room_03_side_activity_hint'), isTrue);
      expect(ids.contains('room_03_on_first_interaction'), isTrue);
      expect(ids.contains('room_03_on_first_upgrade'), isTrue);
      expect(ids.contains('room_03_on_first_event'), isTrue);
    });

    test('room_03_first_law mentions Momentum', () {
      final lines = RobotGuideDialogue.roomSpecificLines['room_03']!;
      final law = lines.firstWhere((m) => m.id == 'room_03_first_law');
      expect(law.text.toLowerCase().contains('momentum'), isTrue);
    });

    test('onFirstEventAppeared fires room_03_on_first_event', () {
      final g = _fresh();
      g.onFirstEventAppeared();
      expect(g.hasMessage, isTrue);
      expect(g.currentMessage!.id, 'room_03_on_first_event');
    });
  });

  group('Wave 1 — Room 4 (Upgrade Cave)', () {
    RobotGuideService _fresh() {
      final g = RobotGuideService();
      g.onRoomChanged('room_04');
      while (g.hasMessage) g.dismiss();
      return g;
    }

    test('room_04 has all required message IDs', () {
      final lines = RobotGuideDialogue.roomSpecificLines['room_04']!;
      final ids = lines.map((m) => m.id).toSet();
      expect(ids.contains('room_04_intro'), isTrue);
      expect(ids.contains('room_04_first_law'), isTrue);
      expect(ids.contains('room_04_room_goal'), isTrue);
      expect(ids.contains('room_04_transformation_1'), isTrue);
      expect(ids.contains('room_04_secret_hint'), isTrue);
      expect(ids.contains('room_04_on_first_interaction'), isTrue);
    });

    test('room_04_first_law mentions Resonance', () {
      final lines = RobotGuideDialogue.roomSpecificLines['room_04']!;
      final law = lines.firstWhere((m) => m.id == 'room_04_first_law');
      expect(law.text.toLowerCase().contains('resonance'), isTrue);
    });

    test('onFirstUpgradePurchased fires room_04_on_first_upgrade', () {
      final g = _fresh();
      g.onFirstUpgradePurchased();
      expect(g.hasMessage, isTrue);
      expect(g.currentMessage!.id, 'room_04_on_first_upgrade');
    });
  });

  group('Wave 1 — Room 5 (Smart Lab Bedroom)', () {
    RobotGuideService _fresh() {
      final g = RobotGuideService();
      g.onRoomChanged('room_05');
      while (g.hasMessage) g.dismiss();
      return g;
    }

    test('room_05 has all required message IDs', () {
      final lines = RobotGuideDialogue.roomSpecificLines['room_05']!;
      final ids = lines.map((m) => m.id).toSet();
      expect(ids.contains('room_05_intro'), isTrue);
      expect(ids.contains('room_05_first_law'), isTrue);
      expect(ids.contains('room_05_room_goal'), isTrue);
      expect(ids.contains('room_05_transformation_1'), isTrue);
      expect(ids.contains('room_05_secret_hint'), isTrue);
      expect(ids.contains('room_05_side_activity_hint'), isTrue);
      expect(ids.contains('room_05_on_first_interaction'), isTrue);
      expect(ids.contains('room_05_on_first_upgrade'), isTrue);
      expect(ids.contains('room_05_on_first_event'), isTrue);
    });

    test('room_05_first_law mentions Dual Nature', () {
      final lines = RobotGuideDialogue.roomSpecificLines['room_05']!;
      final law = lines.firstWhere((m) => m.id == 'room_05_first_law');
      expect(law.text.toLowerCase().contains('dual nature'), isTrue);
    });

    test('onSideActivityDiscovered fires room_05_side_activity_hint', () {
      final g = _fresh();
      g.onSideActivityDiscovered('sa_scan_05');
      expect(g.hasMessage, isTrue);
      expect(g.currentMessage!.id, 'room_05_side_activity_hint');
    });
  });

  // ─── Wave 2: Rooms 6–10 ──────────────────────────────────────────────────

  group('Wave 2 — all rooms have required message IDs', () {
    for (final roomId in ['room_06', 'room_07', 'room_08', 'room_09', 'room_10']) {
      test('$roomId has all required message IDs', () {
        final lines = RobotGuideDialogue.roomSpecificLines[roomId];
        expect(lines, isNotNull, reason: 'Missing lines for $roomId');
        final ids = lines!.map((m) => m.id).toSet();
        expect(ids.contains('${roomId}_intro'), isTrue);
        expect(ids.contains('${roomId}_first_law'), isTrue);
        expect(ids.contains('${roomId}_room_goal'), isTrue);
        expect(ids.contains('${roomId}_transformation_1'), isTrue);
        expect(ids.contains('${roomId}_secret_hint'), isTrue);
        expect(ids.contains('${roomId}_on_first_interaction'), isTrue);
        expect(ids.contains('${roomId}_on_first_upgrade'), isTrue);
        expect(ids.contains('${roomId}_on_first_event'), isTrue);
      });
    }
  });

  // ─── Wave 3: Rooms 11–15 ─────────────────────────────────────────────────

  group('Wave 3 — all rooms have required message IDs', () {
    for (final roomId in ['room_11', 'room_12', 'room_13', 'room_14', 'room_15']) {
      test('$roomId has all required message IDs', () {
        final lines = RobotGuideDialogue.roomSpecificLines[roomId];
        expect(lines, isNotNull, reason: 'Missing lines for $roomId');
        final ids = lines!.map((m) => m.id).toSet();
        expect(ids.contains('${roomId}_intro'), isTrue);
        expect(ids.contains('${roomId}_first_law'), isTrue);
        expect(ids.contains('${roomId}_room_goal'), isTrue);
        expect(ids.contains('${roomId}_transformation_1'), isTrue);
        expect(ids.contains('${roomId}_secret_hint'), isTrue);
        expect(ids.contains('${roomId}_on_first_interaction'), isTrue);
        expect(ids.contains('${roomId}_on_first_upgrade'), isTrue);
        expect(ids.contains('${roomId}_on_first_event'), isTrue);
      });
    }
  });

  // ─── Wave 4: Rooms 16–20 ─────────────────────────────────────────────────

  group('Wave 4 — all rooms have required message IDs', () {
    for (final roomId in ['room_16', 'room_17', 'room_18', 'room_19', 'room_20']) {
      test('$roomId has all required message IDs', () {
        final lines = RobotGuideDialogue.roomSpecificLines[roomId];
        expect(lines, isNotNull, reason: 'Missing lines for $roomId');
        final ids = lines!.map((m) => m.id).toSet();
        expect(ids.contains('${roomId}_intro'), isTrue);
        expect(ids.contains('${roomId}_first_law'), isTrue);
        expect(ids.contains('${roomId}_room_goal'), isTrue);
        expect(ids.contains('${roomId}_transformation_1'), isTrue);
        expect(ids.contains('${roomId}_secret_hint'), isTrue);
        expect(ids.contains('${roomId}_on_first_interaction'), isTrue);
        expect(ids.contains('${roomId}_on_first_upgrade'), isTrue);
        expect(ids.contains('${roomId}_on_first_event'), isTrue);
      });
    }
  });

  // ─── onTransformationStageAdvanced ───────────────────────────────────────

  group('onTransformationStageAdvanced', () {
    test('fires room-specific transformation_1 for room_02', () {
      final g = RobotGuideService();
      g.onRoomChanged('room_02');
      while (g.hasMessage) g.dismiss();
      g.onTransformationStageAdvanced('room_02');
      expect(g.hasMessage, isTrue);
      expect(g.currentMessage!.id, 'room_02_transformation_1');
    });

    test('fires room-specific transformation_1 for room_10', () {
      final g = RobotGuideService();
      g.onRoomChanged('room_10');
      while (g.hasMessage) g.dismiss();
      g.onTransformationStageAdvanced('room_10');
      expect(g.hasMessage, isTrue);
      expect(g.currentMessage!.id, 'room_10_transformation_1');
    });

    test('does not repeat after already shown', () {
      final g = RobotGuideService();
      g.onRoomChanged('room_06');
      while (g.hasMessage) g.dismiss();
      g.onTransformationStageAdvanced('room_06');
      expect(g.hasMessage, isTrue);
      g.dismiss();
      g.onTransformationStageAdvanced('room_06');
      expect(g.hasMessage, isFalse);
    });
  });

  // ─── All 20 rooms coverage ────────────────────────────────────────────────

  group('Coverage: all 20 rooms defined in roomSpecificLines', () {
    test('all room IDs from room_01 to room_20 have entries', () {
      for (var i = 1; i <= 20; i++) {
        final roomId = 'room_${i.toString().padLeft(2, '0')}';
        final lines = RobotGuideDialogue.roomSpecificLines[roomId];
        expect(lines, isNotNull, reason: 'Missing roomSpecificLines entry for $roomId');
        expect(lines!.isNotEmpty, isTrue, reason: 'Empty lines for $roomId');
      }
    });

    test('no room has duplicate message IDs', () {
      for (final entry in RobotGuideDialogue.roomSpecificLines.entries) {
        final ids = entry.value.map((m) => m.id).toList();
        final unique = ids.toSet();
        expect(ids.length, equals(unique.length),
            reason: 'Duplicate IDs found in ${entry.key}: $ids');
      }
    });

    test('all trigger messages have correct suffix patterns', () {
      for (final entry in RobotGuideDialogue.roomSpecificLines.entries) {
        for (final msg in entry.value) {
          if (msg.id.contains('_on_first_')) {
            expect(
              msg.id.endsWith('_on_first_interaction') ||
                  msg.id.endsWith('_on_first_upgrade') ||
                  msg.id.endsWith('_on_first_event'),
              isTrue,
              reason: 'Unknown trigger suffix in ${msg.id}',
            );
          }
        }
      }
    });
  });
}
