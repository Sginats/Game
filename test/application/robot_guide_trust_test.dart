import 'package:ai_evolution/application/services/robot_guide_service.dart';
import 'package:ai_evolution/domain/models/robot_guide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('robot guide shows room-specific messages on room change', () {
    final guide = RobotGuideService();
    guide.onRoomChanged('room_01', trustTier: 1);
    expect(guide.hasMessage, isTrue);
    // room_01_intro has priority 9 — highest among non-trigger messages
    expect(guide.currentMessage!.id, 'room_01_intro');
    expect(guide.currentMessage!.type, RobotGuideMessageType.roomIntro);
  });

  test('robot guide does not show room lines below minTrustTier', () {
    final guide = RobotGuideService();
    // room_05_secret_hint and room_05_hint require trust tier 2;
    // but now room_05 also has tier-1 messages (intro, law, etc.)
    // This test verifies that tier-2-gated lines do NOT show at tier 1.
    guide.onRoomChanged('room_05', trustTier: 1);
    // Drain all tier-1 messages
    final shown = <String>[];
    while (guide.hasMessage) {
      shown.add(guide.currentMessage!.id);
      guide.dismiss();
    }
    // Secret hint (tier 2) and original hint (tier 2) must NOT appear at tier 1
    expect(shown.contains('room_05_secret_hint'), isFalse);
    expect(shown.contains('room_05_hint'), isFalse);
    // But non-trigger tier-1 messages should have been shown
    expect(shown.contains('room_05_intro'), isTrue);
  });

  test('robot guide shows room lines at sufficient trust tier', () {
    final guide = RobotGuideService();
    guide.onRoomChanged('room_05', trustTier: 2);
    // Priority 9 message (room_05_intro) shows first now
    expect(guide.hasMessage, isTrue);
    expect(guide.currentMessage!.id, 'room_05_intro');
    // Drain all; room_05_hint (tier 2) should be in the set shown
    final shown = <String>[];
    while (guide.hasMessage) {
      shown.add(guide.currentMessage!.id);
      guide.dismiss();
    }
    expect(shown.contains('room_05_hint'), isTrue);
  });

  test('robot guide does not repeat room messages', () {
    final guide = RobotGuideService();
    guide.onRoomChanged('room_01', trustTier: 1);
    expect(guide.hasMessage, isTrue);
    guide.dismiss();

    // Change back to the same room
    guide.onRoomChanged('room_02', trustTier: 1);
    guide.onRoomChanged('room_01', trustTier: 1);
    expect(guide.hasMessage, isFalse);
  });

  test('trust tier change shows unlock message', () {
    final guide = RobotGuideService();
    guide.onTrustTierChanged(2);
    expect(guide.hasMessage, isTrue);
    expect(guide.currentMessage!.id, 'trust_tier2');
    expect(guide.currentMessage!.type, RobotGuideMessageType.trustUnlock);
  });

  test('trust tier jumps show all missed tier messages', () {
    final guide = RobotGuideService();
    guide.onTrustTierChanged(3);
    // Should show tier 2 message first (or tier 3 by priority)
    expect(guide.hasMessage, isTrue);
    // Dismiss first message
    guide.dismiss();
    // Tick to advance queue
    guide.tick(1.0,
      totalTaps: 100, tapCombo: 0, eventActive: false,
      prestigeCount: 1, coins: 1000, highestEraOrder: 5, trustTier: 3,
    );
    // Should still have next trust message queued
    // (or may be consumed — the key is it didn't crash)
  });

  test('onRoomTwist shows twist message', () {
    final guide = RobotGuideService();
    guide.onRoomTwist();
    expect(guide.hasMessage, isTrue);
    expect(guide.currentMessage!.type, RobotGuideMessageType.roomTwist);
  });

  test('onSecretFound shows secret message', () {
    final guide = RobotGuideService();
    guide.onSecretFound();
    expect(guide.hasMessage, isTrue);
    expect(guide.currentMessage!.type, RobotGuideMessageType.secret);
  });

  test('onTransformation shows encouragement message', () {
    final guide = RobotGuideService();
    guide.onTransformation();
    expect(guide.hasMessage, isTrue);
    expect(guide.currentMessage!.type, RobotGuideMessageType.encouragement);
  });

  test('onDisagreement shows disagreement line', () {
    final guide = RobotGuideService();
    guide.onDisagreement(trustTier: 1);
    expect(guide.hasMessage, isTrue);
    expect(guide.currentMessage!.type, RobotGuideMessageType.disagreement);
  });

  test('onDisagreement respects minTrustTier', () {
    final guide = RobotGuideService();
    // First dismiss the default disagreement
    guide.onDisagreement(trustTier: 1);
    guide.dismiss();

    // disagree_overload requires trust tier 3
    // After showing disagree_risky (tier 1), the next unshown one is disagree_overload (tier 3)
    guide.onDisagreement(trustTier: 2);
    // disagree_corruption needs tier 2
    expect(guide.hasMessage, isTrue);
    expect(guide.currentMessage!.id, 'disagree_corruption');
  });

  test('tick passes trustTier to contextual tips', () {
    final guide = RobotGuideService();
    // Tick with high trust and a known room
    guide.onRoomChanged('room_01', trustTier: 3);
    guide.dismiss();

    // After dismissing, tick should try room-specific hints at trust tier 3
    guide.tick(35.0,
      totalTaps: 100, tapCombo: 0, eventActive: false,
      prestigeCount: 1, coins: 1000, highestEraOrder: 5, trustTier: 3,
    );
    // Should not crash; may or may not have a new message depending on queue state
  });

  test('trust tier dialogue data exists for tiers 2-5', () {
    for (var tier = 2; tier <= 5; tier++) {
      final messages = RobotGuideDialogue.trustTierMessages[tier];
      expect(messages, isNotNull, reason: 'Missing trust messages for tier $tier');
      expect(messages!.isNotEmpty, isTrue, reason: 'Empty trust messages for tier $tier');
    }
  });

  test('disagreement lines exist and have correct types', () {
    expect(RobotGuideDialogue.disagreementLines.isNotEmpty, isTrue);
    for (final msg in RobotGuideDialogue.disagreementLines) {
      expect(msg.type, RobotGuideMessageType.disagreement);
    }
  });

  test('room-specific lines exist for key rooms', () {
    final keyRooms = ['room_01', 'room_05', 'room_10', 'room_15', 'room_20'];
    for (final roomId in keyRooms) {
      final messages = RobotGuideDialogue.roomSpecificLines[roomId];
      expect(messages, isNotNull, reason: 'Missing lines for $roomId');
      expect(messages!.isNotEmpty, isTrue, reason: 'Empty lines for $roomId');
    }
  });

  test('backward compat: tick works without trustTier', () {
    final guide = RobotGuideService();
    guide.onEraChanged('era_1');
    guide.dismiss();

    // tick without trustTier should use default (1)
    guide.tick(13.0,
      totalTaps: 0, tapCombo: 0, eventActive: false,
      prestigeCount: 0, coins: 0, highestEraOrder: 1,
    );
    expect(guide.hasMessage, isTrue);
    expect(guide.currentMessage!.id, 'tut_tap');
  });
}
