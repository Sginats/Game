/// Tests for the isolated panel widgets introduced in pass 4:
/// - RoomOverviewCard renders correctly from room data
/// - RoomOverviewCard reflects transformation progress
import 'package:ai_evolution/application/services/app_strings.dart';
import 'package:ai_evolution/domain/models/room_scene.dart';
import 'package:ai_evolution/presentation/widgets/room_overview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final strings = AppStrings('en');

  RoomScene _makeRoom({
    int stages = 3,
    bool hasTwistLine = false,
  }) {
    final transformationStages = List.generate(
      stages,
      (i) => TransformationStage(
        id: 'stage_$i',
        name: 'Stage ${i + 1}',
        description: 'Stage ${i + 1} description',
        requiredUpgrades: (i + 1) * 10,
        environmentChanges: ['env_change_${i + 1}'],
      ),
    );
    return RoomScene(
      id: 'room_test',
      name: 'Test Room',
      subtitle: 'A test subtitle',
      order: 1,
      introText: 'Welcome.',
      completionText: 'Well done.',
      guideTone: 'neutral',
      guideIntroLine: 'Hello traveller.',
      currency: 'Coins',
      eventPoolId: 'pool_test',
      themeColors: const RoomThemeColor(
        primary: '#00ccff',
        accent: '#ff9900',
        background: '#0a0f16',
      ),
      transformationStages: transformationStages,
      midSceneTwist: hasTwistLine
          ? const MidSceneTwist(
              id: 'tw1',
              title: 'Twist!',
              description: 'Something changed.',
              effectDescription: 'Effect active.',
              activated: false,
            )
          : null,
    );
  }

  Widget _wrap(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: child,
        ),
      ),
    );
  }

  testWidgets('renders room guide intro line', (tester) async {
    final room = _makeRoom();
    final state = RoomSceneState(roomId: room.id);
    await tester.pumpWidget(_wrap(
      RoomOverviewCard(room: room, roomState: state, strings: strings),
    ));
    expect(find.text(strings.translateContent(room.guideIntroLine)),
        findsOneWidget);
  });

  testWidgets('shows twist dormant label when twist not activated', (tester) async {
    final room = _makeRoom(hasTwistLine: true);
    final state = RoomSceneState(roomId: room.id, twistActivated: false);
    await tester.pumpWidget(_wrap(
      RoomOverviewCard(room: room, roomState: state, strings: strings),
    ));
    expect(find.textContaining(strings.transformationDormant), findsOneWidget);
  });

  testWidgets('shows twist ready label when twist activated', (tester) async {
    final room = _makeRoom(hasTwistLine: true);
    final state = RoomSceneState(roomId: room.id, twistActivated: true);
    await tester.pumpWidget(_wrap(
      RoomOverviewCard(room: room, roomState: state, strings: strings),
    ));
    expect(find.textContaining(strings.transformationReady), findsOneWidget);
  });

  testWidgets('shows next transformation stage description', (tester) async {
    final room = _makeRoom(stages: 3);
    // currentTransformationStage=0 → nextStage is stage index 1 (name: "Stage 2")
    final state = RoomSceneState(roomId: room.id);
    await tester.pumpWidget(_wrap(
      RoomOverviewCard(room: room, roomState: state, strings: strings),
    ));
    expect(find.textContaining('Stage 2'), findsOneWidget);
  });

  testWidgets('shows completion text when all stages passed', (tester) async {
    final room = _makeRoom(stages: 2);
    // currentTransformationStage beyond last stage → show completionText
    final state = RoomSceneState(
      roomId: room.id,
      currentTransformationStage: 5, // beyond last stage
    );
    await tester.pumpWidget(_wrap(
      RoomOverviewCard(room: room, roomState: state, strings: strings),
    ));
    expect(find.textContaining(strings.translateContent(room.completionText)),
        findsOneWidget);
  });

  testWidgets('shows environment changes for current stage', (tester) async {
    final room = _makeRoom(stages: 3);
    // stage 0 has environmentChanges: ['env_change_1']
    final state = RoomSceneState(roomId: room.id);
    await tester.pumpWidget(_wrap(
      RoomOverviewCard(room: room, roomState: state, strings: strings),
    ));
    // The _chip for env change uses formatEnvironmentChange which replaces _ with space
    expect(find.textContaining('env change 1'), findsOneWidget);
  });

  testWidgets('shows room with no transformation stages gracefully', (tester) async {
    final room = _makeRoom(stages: 0);
    final state = RoomSceneState(roomId: room.id);
    await tester.pumpWidget(_wrap(
      RoomOverviewCard(room: room, roomState: state, strings: strings),
    ));
    // Should not throw; completion text shown
    expect(find.textContaining(strings.translateContent(room.completionText)),
        findsOneWidget);
  });
}
