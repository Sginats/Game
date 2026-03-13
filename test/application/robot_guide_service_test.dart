import 'package:ai_evolution/application/services/robot_guide_service.dart';
import 'package:ai_evolution/domain/models/robot_guide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('robot guide shows era intro on era change', () {
    final guide = RobotGuideService();
    expect(guide.hasMessage, isFalse);

    guide.onEraChanged('era_1');
    expect(guide.hasMessage, isTrue);
    expect(guide.currentMessage!.id, 'intro_era1');
    expect(guide.currentMessage!.type, RobotGuideMessageType.eraIntro);
  });

  test('robot guide does not repeat messages', () {
    final guide = RobotGuideService();
    guide.onEraChanged('era_1');
    expect(guide.hasMessage, isTrue);

    guide.dismiss();
    expect(guide.hasMessage, isFalse);

    // Changing to the same era should not show the message again
    guide.onEraChanged('era_1');
    expect(guide.hasMessage, isFalse);
  });

  test('robot guide shows different intros for different eras', () {
    final guide = RobotGuideService();

    guide.onEraChanged('era_1');
    expect(guide.currentMessage!.id, 'intro_era1');
    guide.dismiss();

    guide.onEraChanged('era_5');
    expect(guide.currentMessage!.id, 'intro_era5');
  });

  test('robot guide dismiss works', () {
    final guide = RobotGuideService();
    guide.onEraChanged('era_1');
    expect(guide.hasMessage, isTrue);

    guide.dismiss();
    expect(guide.hasMessage, isFalse);
    expect(guide.currentMessage, isNull);
  });

  test('robot guide message expiry advances to next eligible guide message', () {
    final guide = RobotGuideService();
    guide.onEraChanged('era_1');
    expect(guide.hasMessage, isTrue);
    expect(guide.currentMessage!.id, 'intro_era1');

    // Tick past the message duration (12 seconds)
    guide.tick(
      13.0,
      totalTaps: 0,
      tapCombo: 0,
      eventActive: false,
      prestigeCount: 0,
      coins: 0,
      highestEraOrder: 1,
    );
    expect(guide.hasMessage, isTrue);
    expect(guide.currentMessage!.id, 'tut_tap');
  });

  test('robot guide queues multiple messages by priority', () {
    final guide = RobotGuideService();
    guide.onEraChanged('era_2');
    expect(guide.hasMessage, isTrue);
    // Should show era intro first (priority 10)
    expect(guide.currentMessage!.id, 'intro_era2');
  });

  test('robot guide dialogue has entries for all 20 eras', () {
    for (var i = 1; i <= 20; i++) {
      final messages = RobotGuideDialogue.eraIntroductions['era_$i'];
      expect(messages, isNotNull, reason: 'Missing intro for era_$i');
      expect(messages!.isNotEmpty, isTrue, reason: 'Empty intro for era_$i');
    }
  });

  test('robot guide tutorials list is not empty', () {
    expect(RobotGuideDialogue.tutorials.isNotEmpty, isTrue);
    expect(RobotGuideDialogue.tutorials.length, 5);
  });
}
