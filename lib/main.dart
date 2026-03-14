import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'application/controllers/game_controller.dart';
import 'application/services/app_settings_service.dart';
import 'application/services/app_strings.dart';
import 'application/services/app_update_service.dart';
import 'application/services/config_service.dart';
import 'application/services/game_audio_service.dart';
import 'application/services/leaderboard_service.dart';
import 'application/services/era_content_manager.dart';
import 'application/services/room_content_generator.dart';
import 'application/services/leaderboard_session_service.dart';
import 'application/services/room_scene_asset_loader.dart';
import 'application/services/room_scene_service.dart';
import 'core/math/game_number.dart';
import 'core/time/time_provider.dart';
import 'data/repositories/game_repository.dart';
import 'data/save/shared_prefs_save_manager.dart';
import 'domain/models/achievement.dart';
import 'domain/models/era.dart';
import 'domain/models/generator.dart';
import 'domain/models/game_systems.dart';
import 'domain/models/progression_content.dart';
import 'domain/models/upgrade.dart';
import 'presentation/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Defer Supabase initialization to avoid blocking startup
  _initSupabase();

  runApp(const RoomZeroApp());
}

/// Initialize Supabase in the background without blocking the main UI.
Future<void> _initSupabase() async {
  try {
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://uqixesqvozizevjuzjjn.supabase.co',
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVxaXhlc3F2b3ppemV2anV6ampuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MTMxMTMsImV4cCI6MjA4ODk4OTExM30.dTlIqXh4Z7sBSVijYfyHz-NDBgZk9R2Olj2HvXfdG1s',
    );

    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    }
  } catch (e) {
    // Supabase init failure should not prevent game from loading.
    // Log for debugging but continue gracefully.
    debugPrint('Supabase initialization failed: $e');
  }
}

class RoomZeroApp extends StatelessWidget {
  const RoomZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Zero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B657A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF071018),
        useMaterial3: true,
      ),
      home: const GameLoader(),
    );
  }
}

class GameLoader extends StatefulWidget {
  const GameLoader({super.key});

  @override
  State<GameLoader> createState() => _GameLoaderState();
}

class _GameLoaderState extends State<GameLoader> {
  GameController? _controller;
  ConfigService? _config;
  AppSettings _settings = const AppSettings();
  late final AppSettingsService _settingsService;
  late AppUpdateService _updateService;
  late final GameAudioService _audioService;
  late final LeaderboardSessionService _leaderboardSessionService;
  LeaderboardService? _leaderboardService;
  String? _error;

  @override
  void initState() {
    super.initState();
    _settingsService = AppSettingsService();
    _updateService = AppUpdateService(config: const AppUpdateConfig());
    _audioService = GameAudioService();
    _leaderboardSessionService = LeaderboardSessionService();
    _loadGame();
  }

  Future<void> _loadGame() async {
    try {
      final settings = await _settingsService.load();
      await _leaderboardSessionService.load();
      final gameConfigStr =
          await rootBundle.loadString('assets/config/game_config.json');
      final gameConfig = json.decode(gameConfigStr) as Map<String, dynamic>;

      final economyConfigStr =
          await rootBundle.loadString('assets/config/economy_config.json');
      final economyConfig =
          json.decode(economyConfigStr) as Map<String, dynamic>;
      final progressionConfigStr =
          await rootBundle.loadString('assets/config/progression_config.json');
      final progressionConfig =
          json.decode(progressionConfigStr) as Map<String, dynamic>;
      AppUpdateConfig updateConfig = const AppUpdateConfig();
      try {
        final updateConfigStr =
            await rootBundle.loadString('assets/config/update_config.json');
        updateConfig = AppUpdateConfig.fromJson(
          json.decode(updateConfigStr) as Map<String, dynamic>,
        );
      } catch (_) {
        updateConfig = const AppUpdateConfig();
      }
      final roomSceneService = RoomSceneService(
        roomJsonList: await const RoomSceneAssetLoader().loadAll(),
      );

      final baseGenerators = (economyConfig['generators'] as List<dynamic>)
          .map((item) => GeneratorDefinition.fromJson(item as Map<String, dynamic>))
          .toList();
      final baseUpgrades = (economyConfig['upgrades'] as List<dynamic>)
          .map((item) => UpgradeDefinition.fromJson(item as Map<String, dynamic>))
          .toList();
      final eras = (economyConfig['eras'] as List<dynamic>)
          .map((item) => Era.fromJson(item as Map<String, dynamic>))
          .toList();
      final achievements = (economyConfig['achievements'] as List<dynamic>? ?? [])
          .map((item) => AchievementDefinition.fromJson(item as Map<String, dynamic>))
          .toList();
      final purchaseModes =
          (economyConfig['purchaseModes'] as List<dynamic>? ?? const [])
              .map(
                (item) => PurchaseMode.values.firstWhere(
                  (value) => value.label == item,
                ),
              )
              .toList();
      final aiTraits = (economyConfig['aiTraits'] as List<dynamic>? ?? const [])
          .map(
            (item) => AITrait.values.firstWhere(
              (value) => value.label == item,
            ),
          )
          .toList();
      final endings = (economyConfig['endings'] as List<dynamic>? ?? const [])
          .map((item) => Ending.fromJson(item as Map<String, dynamic>))
          .toList();
      final progression = ProgressionContent.fromJson(progressionConfig);

      // Use lazy era content manager instead of loading all 2000+ upgrades at once
      final contentManager = EraContentManager(
        generator: const RoomContentGenerator(),
        eras: eras,
        baseGenerators: baseGenerators,
        baseUpgrades: baseUpgrades,
      );

      // Only load the first era at startup for fast loading.
      contentManager.ensureEraLoaded('era_1');

      final generators = contentManager.generators;
      final upgrades = contentManager.upgrades;

      final config = ConfigService(
        baseTapValue: GameNumber.fromDouble(
          double.parse(economyConfig['baseTapValue'].toString()),
        ),
        baseTapMultiplier: GameNumber.fromDouble(
          double.parse(economyConfig['baseTapMultiplier'].toString()),
        ),
        generators: Map<String, GeneratorDefinition>.from(generators),
        upgrades: Map<String, UpgradeDefinition>.from(upgrades),
        eras: eras,
        achievements: achievements,
        purchaseModes: purchaseModes.isEmpty
            ? const [
                PurchaseMode.x1,
                PurchaseMode.x10,
                PurchaseMode.x100,
                PurchaseMode.max,
              ]
            : purchaseModes,
        aiTraits: aiTraits.isEmpty
            ? const [
                AITrait.helpful,
                AITrait.obsessive,
                AITrait.chaotic,
                AITrait.transcendent,
              ]
            : aiTraits,
        endings: endings,
        progression: progression,
        maxOfflineHours: gameConfig['maxOfflineHours'] as int,
        autoSaveIntervalSeconds: gameConfig['autoSaveIntervalSeconds'] as int,
        tickRateMs: gameConfig['tickRateMs'] as int,
        contentManager: contentManager,
      );

      final controller = GameController(
        config: config,
        timeProvider: SystemTimeProvider(),
        repository: GameRepository(SharedPrefsSaveManager()),
        roomSceneService: roomSceneService,
      );
      final leaderboardService = LeaderboardService(
        sessionProvider: _leaderboardSessionService,
      );

      await controller.loadGame();

      // After loading save data, load only the current room window and owned eras.
      for (final eraId in controller.loadedEraWindow) {
        contentManager.ensureEraLoaded(eraId);
      }
      config.refreshContent(contentManager);

      // Preload the next room window in the background to smooth transitions.
      Future<void>.microtask(() {
        final ordered = eras.toList()..sort((a, b) => a.order.compareTo(b.order));
        final currentIndex = ordered.indexWhere((era) => era.id == controller.currentEraId);
        if (currentIndex >= 0 && currentIndex < ordered.length - 1) {
          contentManager.ensureEraLoaded(ordered[currentIndex + 1].id);
          config.refreshContent(contentManager);
        }
      });

      _audioService.setEnabled(settings.soundEnabled);
      _audioService.configureVolumes(
        musicVolume: settings.musicVolume,
        sfxVolume: settings.sfxVolume,
      );
      final currentRoom = controller.currentRoom;
      if (currentRoom != null) {
        _audioService.setRoomAudioProfile(currentRoom.id);
      }
      _updateService = AppUpdateService(config: updateConfig);
      await _updateService.initialize(
        autoCheckEnabled: settings.autoCheckUpdates,
      );
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _config = config;
        _controller = controller;
        _leaderboardService = leaderboardService;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    }
  }

  Future<void> _updateSettings(AppSettings settings) async {
    await _settingsService.save(settings);
    _audioService.setEnabled(settings.soundEnabled);
    _audioService.configureVolumes(
      musicVolume: settings.musicVolume,
      sfxVolume: settings.sfxVolume,
    );
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_settings.language);

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      );
    }

    if (_controller == null || _config == null || _leaderboardService == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hub_rounded, size: 56, color: Colors.white70),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(strings.loading, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    if (!_controller!.state.tutorialComplete) {
      return StartScreen(
        settings: _settings,
        strings: strings,
        onLanguageChanged: (language) => _updateSettings(
          _settings.copyWith(
            language: language,
            languageConfirmed: true,
          ),
        ),
        onStart: () {
          if (!_settings.languageConfirmed) {
            return;
          }
          setState(() {
            _controller!.completeTutorial();
            unawaited(_controller!.saveGame());
          });
        },
      );
    }

    return GameScreen(
      controller: _controller!,
      config: _config!,
      settings: _settings,
      strings: strings,
      audioService: _audioService,
      updateService: _updateService,
      leaderboardService: _leaderboardService!,
      leaderboardSessionService: _leaderboardSessionService,
      onSettingsChanged: _updateSettings,
    );
  }
}

class StartScreen extends StatelessWidget {
  final AppSettings settings;
  final AppStrings strings;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final VoidCallback onStart;

  const StartScreen({
    super.key,
    required this.settings,
    required this.strings,
    required this.onLanguageChanged,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1A24), Color(0xFF05090E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BBD8), Color(0xFF0F5F74)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.lightBlueAccent.withAlpha(60),
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.account_tree_rounded,
                          color: Colors.white, size: 50),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Room Zero',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      strings.startIntro,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withAlpha(14)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.language,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.chooseStartLanguage,
                            style: const TextStyle(
                              color: Colors.white54,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _LanguageChip(
                                label: strings.english,
                                selected:
                                    settings.language == AppLanguage.english,
                                onTap: () => onLanguageChanged(
                                  AppLanguage.english,
                                ),
                              ),
                              _LanguageChip(
                                label: strings.russian,
                                selected:
                                    settings.language == AppLanguage.russian,
                                onTap: () => onLanguageChanged(
                                  AppLanguage.russian,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _StartChip(icon: Icons.ads_click, label: strings.comboTaps),
                        _StartChip(
                          icon: Icons.account_tree,
                          label: strings.branchingTree,
                        ),
                        _StartChip(
                          icon: Icons.bolt,
                          label: strings.activeAbilities,
                        ),
                        _StartChip(
                          icon: Icons.auto_awesome,
                          label: strings.eventsAndMilestones,
                        ),
                      ],
                    ),
                    if (!settings.languageConfirmed) ...[
                      const SizedBox(height: 16),
                      Text(
                        strings.languageRequired,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: settings.languageConfirmed ? onStart : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: Text(strings.enterRoomZero),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StartChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.cyanAccent.withAlpha(30)
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.cyanAccent.withAlpha(140)
                : Colors.white.withAlpha(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: selected ? Colors.cyanAccent : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
