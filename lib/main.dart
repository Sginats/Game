import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/math/game_number.dart';
import 'core/time/time_provider.dart';
import 'application/controllers/game_controller.dart';
import 'application/services/config_service.dart';
import 'domain/models/generator.dart';
import 'domain/models/upgrade.dart';
import 'domain/models/era.dart';
import 'domain/mechanics/cost_calculator.dart';
import 'domain/systems/tap_system.dart';

void main() {
  runApp(const AIEvolutionApp());
}

/// Root widget for the AI Evolution game.
class AIEvolutionApp extends StatelessWidget {
  const AIEvolutionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Evolution',
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

/// Loads game configuration and then shows the game screen.
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

      final config = ConfigService(
        baseTapValue: GameNumber.fromDouble(
            double.parse(economyConfig['baseTapValue'].toString())),
        baseTapMultiplier: GameNumber.fromDouble(
            double.parse(economyConfig['baseTapMultiplier'].toString())),
        generators: {for (final g in generators) g.id: g},
        upgrades: {for (final u in upgrades) u.id: u},
        eras: eras,
        maxOfflineHours: gameConfig['maxOfflineHours'] as int,
        autoSaveIntervalSeconds:
            gameConfig['autoSaveIntervalSeconds'] as int,
        tickRateMs: gameConfig['tickRateMs'] as int,
      );

      final controller = GameController(
        config: config,
        timeProvider: SystemTimeProvider(),
      );

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
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_controller == null || _config == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI Evolution — Loading…'),
            ],
          ),
        ),
      );
    }

    return GameScreen(controller: _controller!, config: _config!);
  }
}

/// Main game screen with tap area, generators, and upgrades.
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

class _GameScreenState extends State<GameScreen> {
  Timer? _tickTimer;
  int _selectedTab = 0;

  GameController get _controller => widget.controller;
  ConfigService get _config => widget.config;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(
      Duration(milliseconds: _config.tickRateMs),
      (_) {
        setState(() {
          _controller.tick(_config.tickRateMs / 1000.0);
        });
      },
    );
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _onTap() {
    setState(() {
      _controller.tap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Evolution'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Coin display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Text(
                  state.coins.toStringFormatted(),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_controller.productionPerSecond.toStringFormatted()}/sec',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          // Tap button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: GestureDetector(
              onTap: _onTap,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blueAccent,
                      Colors.purpleAccent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withAlpha(100),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app, size: 36, color: Colors.white),
                      const SizedBox(height: 4),
                      Text(
                        '+${TapSystem.calculateTapValue(_config.baseTapValue, state.tapMultiplier).toStringFormatted()}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Tab bar
          Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Generators',
                  selected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: 'Upgrades',
                  selected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ),
            ],
          ),
          // Tab content
          Expanded(
            child: _selectedTab == 0
                ? _GeneratorList(
                    controller: _controller,
                    config: _config,
                    onPurchase: () => setState(() {}),
                  )
                : _UpgradeList(
                    controller: _controller,
                    config: _config,
                    onPurchase: () => setState(() {}),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _GeneratorList extends StatelessWidget {
  final GameController controller;
  final ConfigService config;
  final VoidCallback onPurchase;

  const _GeneratorList({
    required this.controller,
    required this.config,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final generators = config.generators.values.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: generators.length,
      itemBuilder: (context, index) {
        final def = generators[index];
        final state = controller.state.generators[def.id];
        final level = state?.level ?? 0;
        final cost = CostCalculator.calculateCost(
          def.baseCost,
          def.costGrowthRate,
          level,
        );
        final canAfford = controller.state.coins >= cost;

        return Card(
          child: ListTile(
            title: Text(def.name),
            subtitle: Text(
              'Level $level • ${def.baseProduction.toStringFormatted()}/sec base\n'
              'Cost: ${cost.toStringFormatted()}',
            ),
            isThreeLine: true,
            trailing: ElevatedButton(
              onPressed: canAfford
                  ? () {
                      controller.purchaseGenerator(def.id);
                      onPurchase();
                    }
                  : null,
              child: const Text('Buy'),
            ),
          ),
        );
      },
    );
  }
}

class _UpgradeList extends StatelessWidget {
  final GameController controller;
  final ConfigService config;
  final VoidCallback onPurchase;

  const _UpgradeList({
    required this.controller,
    required this.config,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final upgrades = config.upgrades.values.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: upgrades.length,
      itemBuilder: (context, index) {
        final def = upgrades[index];
        final state = controller.state.upgrades[def.id];
        final level = state?.level ?? 0;
        final atMax = level >= def.maxLevel;
        final cost = CostCalculator.calculateCost(
          def.baseCost,
          def.costGrowthRate,
          level,
        );
        final canAfford = controller.state.coins >= cost && !atMax;

        return Card(
          child: ListTile(
            title: Text(def.name),
            subtitle: Text(
              '${def.description}\n'
              'Level $level/${def.maxLevel} • Cost: ${atMax ? "MAX" : cost.toStringFormatted()}',
            ),
            isThreeLine: true,
            trailing: ElevatedButton(
              onPressed: canAfford
                  ? () {
                      controller.purchaseUpgrade(def.id);
                      onPurchase();
                    }
                  : null,
              child: Text(atMax ? 'MAX' : 'Buy'),
            ),
          ),
        );
      },
    );
  }
}
