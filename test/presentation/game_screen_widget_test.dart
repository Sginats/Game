import 'package:ai_evolution/application/controllers/game_controller.dart';
import 'package:ai_evolution/application/services/app_settings_service.dart';
import 'package:ai_evolution/application/services/app_strings.dart';
import 'package:ai_evolution/application/services/config_service.dart';
import 'package:ai_evolution/application/services/game_audio_service.dart';
import 'package:ai_evolution/application/services/leaderboard_service.dart';
import 'package:ai_evolution/application/services/leaderboard_session_service.dart';
import 'package:ai_evolution/core/math/game_number.dart';
import 'package:ai_evolution/core/time/time_provider.dart';
import 'package:ai_evolution/domain/models/achievement.dart';
import 'package:ai_evolution/domain/models/era.dart';
import 'package:ai_evolution/domain/models/game_systems.dart';
import 'package:ai_evolution/domain/models/generator.dart';
import 'package:ai_evolution/domain/models/progression_content.dart';
import 'package:ai_evolution/domain/models/upgrade.dart';
import 'package:ai_evolution/presentation/game_screen.dart';
import 'package:ai_evolution/presentation/tech_tree/tech_tree_models.dart';
import 'package:ai_evolution/presentation/tech_tree/tech_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedTimeProvider implements TimeProvider {
  final DateTime _now;

  _FixedTimeProvider(this._now);

  @override
  DateTime now() => _now;
}

class _GameScreenHarness extends StatefulWidget {
  final GameController controller;
  final ConfigService config;
  final LeaderboardSessionService sessionService;

  const _GameScreenHarness({
    required this.controller,
    required this.config,
    required this.sessionService,
  });

  @override
  State<_GameScreenHarness> createState() => _GameScreenHarnessState();
}

class _GameScreenHarnessState extends State<_GameScreenHarness> {
  AppSettings _settings = const AppSettings();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GameScreen(
        controller: widget.controller,
        config: widget.config,
        settings: _settings,
        strings: AppStrings(_settings.language),
        audioService: GameAudioService(),
        leaderboardService: LeaderboardService(
          sessionProvider: widget.sessionService,
        ),
        leaderboardSessionService: widget.sessionService,
        onSettingsChanged: (settings) async {
          setState(() => _settings = settings);
        },
      ),
    );
  }
}

ConfigService _buildConfig() {
  final generator = GeneratorDefinition(
    id: 'gen_era_1',
    name: 'Starter Core',
    description: 'Test core',
    eraId: 'era_1',
    baseCost: GameNumber.fromDouble(10),
    costGrowthRate: 1.15,
    baseProduction: GameNumber.fromDouble(1),
  );
  final upgrade = UpgradeDefinition(
    id: 'upg_era1_1',
    name: 'Starter Tap',
    description: 'Test upgrade',
    type: UpgradeType.tapMultiplier,
    category: UpgradeCategory.tap,
    eraId: 'era_1',
    baseCost: GameNumber.fromDouble(50),
    costGrowthRate: 1.5,
    maxLevel: 5,
    effectPerLevel: GameNumber.fromDouble(2),
  );
  return ConfigService(
    baseTapValue: GameNumber.fromDouble(1),
    baseTapMultiplier: GameNumber.fromDouble(1),
    generators: {generator.id: generator},
    upgrades: {upgrade.id: upgrade},
    eras: const [
      Era(
        id: 'era_1',
        name: 'Test Era',
        description: 'Test era',
        order: 1,
      ),
    ],
    achievements: const <AchievementDefinition>[],
    purchaseModes: const [PurchaseMode.x1],
    maxOfflineHours: 8,
    autoSaveIntervalSeconds: 30,
    tickRateMs: 1000,
    progression: const ProgressionContent(
      branches: [
        BranchDefinition(
          id: 'tap',
          title: 'Tap Route',
          description: 'Manual route',
        ),
      ],
      secrets: [
        SecretDefinition(
          id: 'secret_test',
          title: 'Secret Test',
          description: 'Hidden node for testing.',
          metric: ProgressMetric.strongestCombo,
          target: 1,
          eraId: 'era_1',
          parentId: 'upg_era1_1',
          offsetX: 180,
          offsetY: -120,
          icon: '✶',
          effectLabel: 'Hidden branch',
          requiredBranchId: 'tap',
        ),
      ],
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('loadout sheet opens from node card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final config = _buildConfig();
    final controller = GameController(
      config: config,
      timeProvider: _FixedTimeProvider(DateTime(2026, 1, 1)),
    );
    controller.setState(
      controller.state.copyWith(
        chosenBranches: const {'tap'},
        generators: {
          'gen_era_1': GeneratorState(
            definitionId: 'gen_era_1',
            level: 1,
          ),
        },
      ),
    );
    final sessionService = LeaderboardSessionService();
    await sessionService.load();

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          controller: controller,
          config: config,
          settings: const AppSettings(),
          strings: const AppStrings(AppLanguage.english),
          audioService: GameAudioService(),
          leaderboardService:
              LeaderboardService(sessionProvider: sessionService),
          leaderboardSessionService: sessionService,
          onSettingsChanged: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tree-node-gen_era_1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Loadout'));
    await tester.tap(find.text('Loadout'));
    await tester.pumpAndSettle();

    expect(find.text('Loadouts'), findsOneWidget);
    expect(find.text('Save preset'), findsOneWidget);
  });

  testWidgets('secret nodes expose bespoke visuals and tap interaction',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    TechTreeNodeData? tappedNode;
    const graph = TechTreeGraph(
      nodes: [
        TechTreeNodeData(
          id: 'secret_test',
          kind: TechTreeNodeKind.secret,
          scale: TechTreeNodeScale.minor,
          position: Offset(120, 120),
          title: 'Hidden Signal',
          subtitle: 'unknown branch',
          description: 'A concealed route is resonating near this branch.',
          eraId: 'era_1',
          icon: '?',
          cost: GameNumber.zero(),
          costLabel: 'Undiscovered',
          effectLabel: 'Find the right playstyle',
          requirementLabel: 'Requires tap route',
          dependencyLabel: 'upg_era1_1',
          progressLabel: 'Hidden',
          locked: true,
          affordable: false,
          purchased: false,
          highlighted: false,
        ),
      ],
      connections: [],
      worldSize: Size(300, 300),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechTreeView(
            graph: graph,
            selectedNodeId: null,
            hoveredNodeId: null,
            transformationController: TransformationController(),
            onNodeTap: (node) => tappedNode = node,
            onHoverChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('secret-orbit-secret_test')), findsOneWidget);
    expect(find.text('SECRET'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tree-node-secret_test')));
    await tester.pumpAndSettle();

    expect(tappedNode?.id, 'secret_test');
  });

  testWidgets('settings language switch updates visible labels', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final config = _buildConfig();
    final controller = GameController(
      config: config,
      timeProvider: _FixedTimeProvider(DateTime(2026, 1, 1)),
    );
    final sessionService = LeaderboardSessionService();
    await sessionService.load();

    await tester.pumpWidget(
      _GameScreenHarness(
        controller: controller,
        config: config,
        sessionService: sessionService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Choose the interface language'), findsOneWidget);

    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Russian').last);
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Язык'), findsOneWidget);
    expect(find.text('Выберите язык интерфейса'), findsOneWidget);
    expect(find.text('Language'), findsNothing);
  });
}
