import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/math/game_number.dart';
import 'core/time/time_provider.dart';
import 'application/controllers/game_controller.dart';
import 'application/services/config_service.dart';
import 'data/save/shared_prefs_save_manager.dart';
import 'data/repositories/game_repository.dart';
import 'domain/models/achievement.dart';
import 'domain/models/generator.dart';
import 'domain/models/upgrade.dart';
import 'domain/models/era.dart';
import 'domain/mechanics/cost_calculator.dart';
import 'domain/systems/tap_system.dart';
import 'domain/systems/prestige_system.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AIEvolutionApp());
}

// ─────────────────────────── Era theming ────────────────────────────────

/// Returns gradient colors for a given era.
List<Color> _eraGradient(String eraId) {
  switch (eraId) {
    case 'era_1':
      return [const Color(0xFF1565C0), const Color(0xFF0D47A1)];
    case 'era_2':
      return [const Color(0xFF00897B), const Color(0xFF00695C)];
    case 'era_3':
      return [const Color(0xFF6A1B9A), const Color(0xFF4A148C)];
    case 'era_4':
      return [const Color(0xFFE65100), const Color(0xFFBF360C)];
    case 'era_5':
      return [const Color(0xFFAD1457), const Color(0xFF880E4F)];
    default:
      return [Colors.blueAccent, Colors.purpleAccent];
  }
}

Color _eraAccent(String eraId) {
  switch (eraId) {
    case 'era_1':
      return Colors.lightBlueAccent;
    case 'era_2':
      return Colors.tealAccent;
    case 'era_3':
      return Colors.purpleAccent;
    case 'era_4':
      return Colors.deepOrangeAccent;
    case 'era_5':
      return Colors.pinkAccent;
    default:
      return Colors.blueAccent;
  }
}

IconData _eraIcon(String eraId) {
  switch (eraId) {
    case 'era_1':
      return Icons.computer;
    case 'era_2':
      return Icons.psychology;
    case 'era_3':
      return Icons.hub;
    case 'era_4':
      return Icons.auto_awesome;
    case 'era_5':
      return Icons.all_inclusive;
    default:
      return Icons.memory;
  }
}

/// Determine the "current" era based on highest unlocked generators.
String _currentEra(GameController controller) {
  final gens = controller.config.generators.values.toList();
  String best = 'era_1';
  int bestOrder = 1;
  for (final g in gens) {
    final state = controller.state.generators[g.id];
    if (state != null && state.level > 0) {
      final era = controller.config.eras.firstWhere(
        (e) => e.id == g.eraId,
        orElse: () => controller.config.eras.first,
      );
      if (era.order > bestOrder) {
        bestOrder = era.order;
        best = era.id;
      }
    }
  }
  return best;
}

// ─────────────────────────── Root App ───────────────────────────────────

class AIEvolutionApp extends StatelessWidget {
  const AIEvolutionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Evolution',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameLoader(),
    );
  }
}

// ─────────────────────────── Game Loader ────────────────────────────────

class GameLoader extends StatefulWidget {
  const GameLoader({super.key});

  @override
  State<GameLoader> createState() => _GameLoaderState();
}

class _GameLoaderState extends State<GameLoader> {
  GameController? _controller;
  ConfigService? _config;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    try {
      final gameConfigStr =
          await rootBundle.loadString('assets/config/game_config.json');
      final gameConfig =
          json.decode(gameConfigStr) as Map<String, dynamic>;

      final economyConfigStr =
          await rootBundle.loadString('assets/config/economy_config.json');
      final economyConfig =
          json.decode(economyConfigStr) as Map<String, dynamic>;

      final generators = (economyConfig['generators'] as List<dynamic>)
          .map((g) =>
              GeneratorDefinition.fromJson(g as Map<String, dynamic>))
          .toList();

      final upgrades = (economyConfig['upgrades'] as List<dynamic>)
          .map((u) =>
              UpgradeDefinition.fromJson(u as Map<String, dynamic>))
          .toList();

      final eras = (economyConfig['eras'] as List<dynamic>)
          .map((e) => Era.fromJson(e as Map<String, dynamic>))
          .toList();

      final achievements = (economyConfig['achievements'] as List<dynamic>?)
              ?.map((a) =>
                  AchievementDefinition.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [];

      final config = ConfigService(
        baseTapValue: GameNumber.fromDouble(
            double.parse(economyConfig['baseTapValue'].toString())),
        baseTapMultiplier: GameNumber.fromDouble(
            double.parse(economyConfig['baseTapMultiplier'].toString())),
        generators: {for (final g in generators) g.id: g},
        upgrades: {for (final u in upgrades) u.id: u},
        eras: eras,
        achievements: achievements,
        maxOfflineHours: gameConfig['maxOfflineHours'] as int,
        autoSaveIntervalSeconds:
            gameConfig['autoSaveIntervalSeconds'] as int,
        tickRateMs: gameConfig['tickRateMs'] as int,
      );

      final saveManager = SharedPrefsSaveManager();
      final repository = GameRepository(saveManager);

      final controller = GameController(
        config: config,
        timeProvider: SystemTimeProvider(),
        repository: repository,
      );

      // Try loading saved game
      await controller.loadGame();

      setState(() {
        _config = config;
        _controller = controller;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $_error',
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ),
      );
    }

    if (_controller == null || _config == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D47A1), Color(0xFF000000)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.memory, size: 64, color: Colors.lightBlueAccent),
                SizedBox(height: 16),
                CircularProgressIndicator(color: Colors.lightBlueAccent),
                SizedBox(height: 16),
                Text(
                  'AI Evolution',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Loading…',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show start screen if this is a fresh save
    if (!_controller!.state.tutorialComplete) {
      return StartScreen(
        onStart: () {
          setState(() {
            _controller!.completeTutorial();
            _controller!.saveGame();
          });
        },
      );
    }

    return GameScreen(controller: _controller!, config: _config!);
  }
}

// ─────────────────────────── Start Screen (Req 7) ──────────────────────

class StartScreen extends StatelessWidget {
  final VoidCallback onStart;
  const StartScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFF1A237E), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.memory, size: 80, color: Colors.lightBlueAccent),
                const SizedBox(height: 24),
                const Text(
                  'AI Evolution',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Evolve an artificial intelligence from the dawn\nof computing to the singularity and beyond.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withAlpha(180),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                // Tutorial cards
                _TutorialCard(
                  icon: Icons.touch_app,
                  title: 'Tap to Earn',
                  text: 'Tap the core to generate coins. Rapid tapping builds a combo for bonus coins!',
                ),
                const SizedBox(height: 12),
                _TutorialCard(
                  icon: Icons.settings,
                  title: 'Buy Generators',
                  text: 'Invest in processors and AI systems to earn coins automatically.',
                ),
                const SizedBox(height: 12),
                _TutorialCard(
                  icon: Icons.upgrade,
                  title: 'Upgrade & Prestige',
                  text: 'Upgrade for multipliers. Prestige to reset with permanent bonuses!',
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Start Evolution'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _TutorialCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.lightBlueAccent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(text,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(160),
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Main Game Screen ──────────────────────────

class GameScreen extends StatefulWidget {
  final GameController controller;
  final ConfigService config;

  const GameScreen({
    super.key,
    required this.controller,
    required this.config,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  Timer? _tickTimer;
  int _selectedTab = 0;
  late AnimationController _tapAnimController;
  late Animation<double> _tapScale;
  bool _offlinePopupShown = false;

  GameController get _controller => widget.controller;
  ConfigService get _config => widget.config;

  @override
  void initState() {
    super.initState();

    _tapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _tapAnimController, curve: Curves.easeInOut),
    );

    _tickTimer = Timer.periodic(
      Duration(milliseconds: _config.tickRateMs),
      (_) {
        setState(() {
          _controller.tick(_config.tickRateMs / 1000.0);
        });
        // Check for new achievements to show toast
        if (_controller.lastUnlockedAchievements.isNotEmpty) {
          for (final ach in _controller.lastUnlockedAchievements) {
            _showAchievementToast(ach);
          }
        }
      },
    );

    // Show offline earnings popup after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOfflineEarningsIfAny();
    });
  }

  void _showOfflineEarningsIfAny() {
    if (_offlinePopupShown) return;
    _offlinePopupShown = true;
    final earnings = _controller.pendingOfflineEarnings;
    if (earnings != null && !earnings.isZero) {
      _controller.pendingOfflineEarnings = null;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.nightlight_round, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text('Welcome Back!',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'While you were away, your AI kept working.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Text(
                '+${earnings.toStringFormatted()} coins',
                style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Collect',
                  style: TextStyle(color: Colors.lightBlueAccent)),
            ),
          ],
        ),
      );
    }
  }

  void _showAchievementToast(AchievementDefinition ach) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(ach.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Achievement Unlocked!',
                      style: TextStyle(
                          color: Colors.amberAccent.shade100,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(ach.name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E2E4E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _tapAnimController.dispose();
    _controller.saveGame();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    _tapAnimController.forward().then((_) => _tapAnimController.reverse());
    setState(() {
      _controller.tap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final eraId = _currentEra(_controller);
    final gradient = _eraGradient(eraId);
    final accent = _eraAccent(eraId);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradient[0], Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(_eraIcon(eraId), color: accent, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI Evolution',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                    if (state.prestigeCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⭐ ×${state.prestigeMultiplier.toStringFormatted()}',
                          style: const TextStyle(
                              color: Colors.amberAccent, fontSize: 12),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.bar_chart, color: Colors.white70),
                      tooltip: 'Stats',
                      onPressed: () => _showStatsSheet(context),
                    ),
                  ],
                ),
              ),

              // ── Coin display ──
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withAlpha(60)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on,
                            color: Colors.amberAccent, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          state.coins.toStringFormatted(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.trending_up,
                            color: Colors.white54, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_controller.productionPerSecond.toStringFormatted()}/sec',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 14),
                        ),
                        if (state.tapCombo > 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withAlpha(40),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '🔥 Combo ×${state.tapCombo}',
                              style: const TextStyle(
                                  color: Colors.orangeAccent, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Tap button ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
                  onTap: _onTap,
                  child: AnimatedBuilder(
                    animation: _tapScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _tapScale.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent, gradient[1]],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withAlpha(80),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_eraIcon(eraId),
                                size: 40, color: Colors.white),
                            const SizedBox(height: 4),
                            Text(
                              '+${TapSystem.calculateTapValueWithCombo(
                                _config.baseTapValue,
                                state.tapMultiplier,
                                state.tapCombo,
                                state.prestigeMultiplier,
                              ).toStringFormatted()}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // ── Tab bar ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTab(Icons.precision_manufacturing, 'Generators', 0,
                        accent),
                    _buildTab(Icons.upgrade, 'Upgrades', 1, accent),
                    _buildTab(Icons.emoji_events, 'Achievements', 2, accent),
                    _buildTab(Icons.stars, 'Prestige', 3, accent),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Tab content ──
              Expanded(
                child: _buildTabContent(accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, int index, Color accent) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent.withAlpha(30) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? accent : Colors.white38),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? accent : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(Color accent) {
    switch (_selectedTab) {
      case 0:
        return _GeneratorList(
            controller: _controller,
            config: _config,
            accent: accent,
            onPurchase: () => setState(() {}));
      case 1:
        return _UpgradeList(
            controller: _controller,
            config: _config,
            accent: accent,
            onPurchase: () => setState(() {}));
      case 2:
        return _AchievementList(controller: _controller, config: _config);
      case 3:
        return _PrestigePanel(
            controller: _controller,
            onPrestige: () => setState(() {}));
      default:
        return const SizedBox.shrink();
    }
  }

  void _showStatsSheet(BuildContext context) {
    final state = _controller.state;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('📊 Statistics',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            _StatRow('Total Coins Earned',
                state.totalCoinsEarned.toStringFormatted()),
            _StatRow('Current Coins', state.coins.toStringFormatted()),
            _StatRow('Production/sec',
                _controller.productionPerSecond.toStringFormatted()),
            _StatRow('Total Taps', '${state.totalTaps}'),
            _StatRow(
                'Tap Multiplier', state.tapMultiplier.toStringFormatted()),
            _StatRow('Production Multiplier',
                state.productionMultiplier.toStringFormatted()),
            _StatRow('Prestige Count', '${state.prestigeCount}'),
            _StatRow('Prestige Multiplier',
                state.prestigeMultiplier.toStringFormatted()),
            _StatRow('Achievements',
                '${state.unlockedAchievements.length}/${_config.achievements.length}'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─────────────────────────── Generator List ────────────────────────────

class _GeneratorList extends StatelessWidget {
  final GameController controller;
  final ConfigService config;
  final Color accent;
  final VoidCallback onPurchase;

  const _GeneratorList({
    required this.controller,
    required this.config,
    required this.accent,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final generators = config.generators.values.toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: generators.length,
      itemBuilder: (context, index) {
        final def = generators[index];
        final state = controller.state.generators[def.id];
        final level = state?.level ?? 0;
        final cost = CostCalculator.calculateCost(
            def.baseCost, def.costGrowthRate, level);
        final canAfford = controller.state.coins >= cost;
        final eraColors = _eraGradient(def.eraId);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withAlpha(8),
            border: Border.all(
              color: canAfford ? accent.withAlpha(80) : Colors.white.withAlpha(15),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: eraColors),
              ),
              child: Center(
                child: Icon(_eraIcon(def.eraId),
                    size: 22, color: Colors.white),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                    child: Text(def.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14))),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Lv $level',
                      style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(def.description,
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withAlpha(120))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.speed, size: 14, color: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text(
                      '${def.baseProduction.toStringFormatted()}/sec base',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.greenAccent),
                    ),
                    const Spacer(),
                    const Icon(Icons.monetization_on,
                        size: 14, color: Colors.amberAccent),
                    const SizedBox(width: 4),
                    Text(cost.toStringFormatted(),
                        style: TextStyle(
                          fontSize: 12,
                          color: canAfford
                              ? Colors.amberAccent
                              : Colors.redAccent.shade100,
                        )),
                  ],
                ),
              ],
            ),
            trailing: SizedBox(
              width: 56,
              height: 36,
              child: ElevatedButton(
                onPressed: canAfford
                    ? () {
                        HapticFeedback.selectionClick();
                        controller.purchaseGenerator(def.id);
                        onPurchase();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: accent.withAlpha(canAfford ? 200 : 40),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Buy', style: TextStyle(fontSize: 13)),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Upgrade List ──────────────────────────────

class _UpgradeList extends StatelessWidget {
  final GameController controller;
  final ConfigService config;
  final Color accent;
  final VoidCallback onPurchase;

  const _UpgradeList({
    required this.controller,
    required this.config,
    required this.accent,
    required this.onPurchase,
  });

  IconData _upgradeIcon(UpgradeType type) {
    switch (type) {
      case UpgradeType.tapMultiplier:
        return Icons.touch_app;
      case UpgradeType.productionMultiplier:
        return Icons.trending_up;
      case UpgradeType.generatorMultiplier:
        return Icons.settings_suggest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final upgrades = config.upgrades.values.toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: upgrades.length,
      itemBuilder: (context, index) {
        final def = upgrades[index];
        final state = controller.state.upgrades[def.id];
        final level = state?.level ?? 0;
        final atMax = level >= def.maxLevel;
        final cost = CostCalculator.calculateCost(
            def.baseCost, def.costGrowthRate, level);
        final canAfford = controller.state.coins >= cost && !atMax;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withAlpha(8),
            border: Border.all(
              color: atMax
                  ? Colors.greenAccent.withAlpha(60)
                  : canAfford
                      ? accent.withAlpha(80)
                      : Colors.white.withAlpha(15),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: atMax
                    ? Colors.greenAccent.withAlpha(30)
                    : accent.withAlpha(30),
              ),
              child: Center(
                child: Icon(
                  _upgradeIcon(def.type),
                  size: 22,
                  color: atMax ? Colors.greenAccent : accent,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                    child: Text(def.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14))),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (atMax ? Colors.greenAccent : accent).withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$level/${def.maxLevel}',
                    style: TextStyle(
                      color: atMax ? Colors.greenAccent : accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(def.description,
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withAlpha(120))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Effect: ×${def.effectPerLevel.toStringFormatted()}/lvl',
                      style: TextStyle(
                          fontSize: 12, color: Colors.white.withAlpha(160)),
                    ),
                    const Spacer(),
                    if (!atMax) ...[
                      const Icon(Icons.monetization_on,
                          size: 14, color: Colors.amberAccent),
                      const SizedBox(width: 4),
                      Text(cost.toStringFormatted(),
                          style: TextStyle(
                            fontSize: 12,
                            color: canAfford
                                ? Colors.amberAccent
                                : Colors.redAccent.shade100,
                          )),
                    ] else
                      const Text('✅ MAXED',
                          style: TextStyle(
                              color: Colors.greenAccent, fontSize: 12)),
                  ],
                ),
              ],
            ),
            trailing: SizedBox(
              width: 56,
              height: 36,
              child: ElevatedButton(
                onPressed: canAfford
                    ? () {
                        HapticFeedback.selectionClick();
                        controller.purchaseUpgrade(def.id);
                        onPurchase();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: atMax
                      ? Colors.greenAccent.withAlpha(40)
                      : accent.withAlpha(canAfford ? 200 : 40),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(atMax ? 'MAX' : 'Buy',
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Achievement List ──────────────────────────

class _AchievementList extends StatelessWidget {
  final GameController controller;
  final ConfigService config;

  const _AchievementList({
    required this.controller,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final achievements = config.achievements;
    if (achievements.isEmpty) {
      return const Center(
        child: Text('No achievements configured.',
            style: TextStyle(color: Colors.white38)),
      );
    }

    final unlocked = controller.state.unlockedAchievements;
    final total = achievements.length;
    final count = unlocked.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amberAccent),
              const SizedBox(width: 8),
              Text('$count / $total',
                  style: const TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const Spacer(),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? count / total : 0,
                    backgroundColor: Colors.white.withAlpha(15),
                    valueColor: const AlwaysStoppedAnimation(Colors.amberAccent),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final ach = achievements[index];
              final isUnlocked = unlocked.contains(ach.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isUnlocked
                      ? Colors.amberAccent.withAlpha(15)
                      : Colors.white.withAlpha(5),
                  border: Border.all(
                    color: isUnlocked
                        ? Colors.amberAccent.withAlpha(60)
                        : Colors.white.withAlpha(10),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      isUnlocked ? ach.icon : '🔒',
                      style: TextStyle(
                          fontSize: 24,
                          color: isUnlocked ? null : Colors.white38),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ach.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isUnlocked
                                  ? Colors.amberAccent
                                  : Colors.white54,
                            ),
                          ),
                          Text(
                            ach.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isUnlocked
                                  ? Colors.white70
                                  : Colors.white30,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUnlocked)
                      const Icon(Icons.check_circle,
                          color: Colors.greenAccent, size: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Prestige Panel ────────────────────────────

class _PrestigePanel extends StatelessWidget {
  final GameController controller;
  final VoidCallback onPrestige;

  const _PrestigePanel({
    required this.controller,
    required this.onPrestige,
  });

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final canPrestige = controller.canPrestige;
    final nextMult = controller.nextPrestigeMultiplier;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.stars, size: 64, color: Colors.amberAccent),
          const SizedBox(height: 16),
          const Text(
            'Prestige',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Reset your progress in exchange for a permanent\nproduction & tap multiplier.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withAlpha(160), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          // Current stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amberAccent.withAlpha(40)),
            ),
            child: Column(
              children: [
                _StatRow(
                    'Current Prestige Level', '${state.prestigeCount}'),
                _StatRow('Current Multiplier',
                    '×${state.prestigeMultiplier.toStringFormatted()}'),
                const Divider(color: Colors.white24),
                _StatRow(
                  'Next Prestige Bonus',
                  canPrestige ? '×${nextMult.toStringFormatted()}' : '—',
                ),
                _StatRow(
                  'Requirement',
                  '${PrestigeSystem.prestigeThreshold.toStringFormatted()} total coins',
                ),
                _StatRow(
                  'Your Total',
                  state.totalCoinsEarned.toStringFormatted(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: canPrestige
                  ? () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1E2E),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: const Text('Confirm Prestige',
                              style: TextStyle(color: Colors.white)),
                          content: Text(
                            'This will reset your coins, generators, and upgrades.\n\n'
                            'You will gain a ×${nextMult.toStringFormatted()} permanent multiplier.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel',
                                  style:
                                      TextStyle(color: Colors.white54)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                controller.prestige();
                                Navigator.pop(ctx);
                                onPrestige();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amberAccent,
                                foregroundColor: Colors.black87,
                              ),
                              child: const Text('Prestige!'),
                            ),
                          ],
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.stars),
              label: Text(canPrestige
                  ? 'Prestige Now!'
                  : 'Earn ${PrestigeSystem.prestigeThreshold.toStringFormatted()} coins to prestige'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canPrestige ? Colors.amberAccent : Colors.grey.shade800,
                foregroundColor: canPrestige ? Colors.black87 : Colors.white38,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (!canPrestige) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progressToPrestige(state),
                backgroundColor: Colors.white.withAlpha(15),
                valueColor:
                    const AlwaysStoppedAnimation(Colors.amberAccent),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _progressToPrestige(state) {
    if (state.totalCoinsEarned.isZero) return 0;
    final threshold = PrestigeSystem.prestigeThreshold.toDouble();
    final current = state.totalCoinsEarned.toDouble();
    if (threshold <= 0) return 0;
    return (current / threshold).clamp(0.0, 1.0);
  }
}

