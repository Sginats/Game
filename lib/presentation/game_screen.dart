import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/controllers/game_controller.dart';
import '../application/services/app_settings_service.dart';
import '../application/services/app_strings.dart';
import '../application/services/app_update_service.dart';
import '../application/services/config_service.dart';
import '../application/services/game_audio_service.dart';
import '../application/services/leaderboard_service.dart';
import '../application/services/leaderboard_session_service.dart';
import '../application/services/robot_guide_service.dart';
import '../application/services/room_content_generator.dart';
import '../core/math/game_number.dart';
import '../domain/mechanics/cost_calculator.dart';
import '../domain/models/era.dart';
import '../domain/models/game_systems.dart';
import '../domain/models/gameplay_extensions.dart';
import '../domain/models/generator.dart';
import '../domain/models/codex.dart';
import '../domain/models/room_scene.dart';
import '../domain/systems/prestige_system.dart';
import '../domain/systems/tap_system.dart';
import 'tech_tree/tech_tree_builder.dart';
import 'tech_tree/tech_tree_models.dart';
import 'tech_tree/tech_tree_view.dart';
import 'widgets/room_scene_backdrop.dart';
import 'widgets/room_status_panel.dart';
import 'widgets/guide_card.dart';

class GameScreen extends StatefulWidget {
  final GameController controller;
  final ConfigService config;
  final AppSettings settings;
  final AppStrings strings;
  final GameAudioService audioService;
  final AppUpdateService updateService;
  final LeaderboardService leaderboardService;
  final LeaderboardSessionService leaderboardSessionService;
  final Future<void> Function(AppSettings settings) onSettingsChanged;

  const GameScreen({
    super.key,
    required this.controller,
    required this.config,
    required this.settings,
    required this.strings,
    required this.audioService,
    required this.updateService,
    required this.leaderboardService,
    required this.leaderboardSessionService,
    required this.onSettingsChanged,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver {
  final TransformationController _camera = TransformationController();
  final List<_GainToast> _gainToasts = [];
  final RobotGuideService _robotGuide = RobotGuideService();
  Timer? _tickTimer;
  String? _selectedNodeId;
  String? _hoveredNodeId;
  PurchaseMode _purchaseMode = PurchaseMode.x1;
  bool _offlineShown = false;
  Size _viewportSize = const Size(1200, 700);
  int _toastId = 0;
  late final int _frameTickMs;
  final Set<String> _queuedEraPreloads = {};
  String? _lastEventId;
  int _lastRoomStage = -1;
  bool _lastRoomTwist = false;
  int _lastSecretCount = 0;
  int _lastCompletedRooms = 0;
  int _lastGuideMemoryCount = 0;
  String? _lastPromptedUpdateVersion;
  String? _lastRestartPromptVersion;
  // Cached ambient-sync room ID — avoids calling syncAmbientForRoom every build
  String _lastAmbientRoomId = '';

  // Cached tech tree graph — rebuilt only when stateVersion changes
  TechTreeGraph? _cachedGraph;
  String _lastEraId = '';
  // Using _kInvalidVersion as the initial / "force rebuild" sentinel so the
  // tree is always rebuilt on the first build and any time we explicitly
  // invalidate the cache (era switch, purchase-mode change, node selection).
  static const int _kInvalidVersion = -1;
  int _lastStateVersion = _kInvalidVersion;
  // Cached era definition — O(1) lookup after first build
  Era? _cachedEraDef;

  GameController get _controller => widget.controller;
  LeaderboardService get _leaderboardService => widget.leaderboardService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _frameTickMs = math.max(widget.config.tickRateMs, 250);
    _tickTimer = Timer.periodic(
      Duration(milliseconds: _frameTickMs),
      (_) {
        setState(() {
          _controller.tick(_frameTickMs / 1000.0);
          // Tick robot guide with current game state context
          _robotGuide.tick(
            _frameTickMs / 1000.0,
            totalTaps: _controller.state.totalTaps,
            tapCombo: _controller.state.tapCombo,
            eventActive: _controller.activeEvent != null,
            prestigeCount: _controller.state.prestigeCount,
            coins: _controller.state.coins.toDouble(),
            highestEraOrder: _highestEraOrder(),
            trustTier: _controller.guideTier,
          );
          // Notify guide of room changes
          _robotGuide.onRoomChanged(
            _controller.currentRoomId,
            trustTier: _controller.guideTier,
          );
          // Ensure current era content is loaded lazily
          final eraId = _currentEra(_controller);
          if (eraId != _lastEraId) {
            _lastEraId = eraId;
            _syncEraWindow(eraId);
            _robotGuide.onEraChanged(eraId);
            _cachedGraph = null; // Invalidate cache on era change
            _cachedEraDef = null; // Invalidate cached era def
            _selectedNodeId = null;
            _lastStateVersion = _kInvalidVersion; // Force tree rebuild
          }
          // Sync ambient audio once per room change (not every build)
          final roomId = _controller.currentRoomId;
          if (roomId != _lastAmbientRoomId) {
            _lastAmbientRoomId = roomId;
            unawaited(
              widget.audioService.syncAmbientForRoom(
                _controller.currentRoom,
                _controller.currentRoomState,
              ),
            );
          }
        });
        _handleFeedback();
      },
    );
    widget.updateService.addListener(_handleUpdateServiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOffline();
      _syncEraWindow(_currentEra(_controller));
      _focusCurrentEra();
      widget.audioService.setRoomAudioProfile(_controller.currentRoomId);
      // Warm-start the initial room's audio assets so there is no hitch
      // on the first ambient start, guide ping, or event sound.
      unawaited(
        widget.audioService.preloadEssentials(roomId: _controller.currentRoomId),
      );
      // Initialize robot guide with current era
      final eraId = _currentEra(_controller);
      _robotGuide.onEraChanged(eraId);
      _handleUpdateServiceChanged();
    });
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.updateService != widget.updateService) {
      oldWidget.updateService.removeListener(_handleUpdateServiceChanged);
      widget.updateService.addListener(_handleUpdateServiceChanged);
      _handleUpdateServiceChanged();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_controller.saveGame());
    }
  }

  @override
  void dispose() {
    widget.updateService.removeListener(_handleUpdateServiceChanged);
    WidgetsBinding.instance.removeObserver(this);
    _tickTimer?.cancel();
    _camera.dispose();
    unawaited(_controller.saveGame());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eraId = _currentEra(_controller);
    final currentRoom = _controller.currentRoom;
    final accent = _sceneAccent(currentRoom, eraId);
    final gradient = _sceneGradient(currentRoom, eraId);

    // Cache the era definition — only search when the era changes.
    if (_cachedEraDef == null || _cachedEraDef!.id != eraId) {
      _cachedEraDef = widget.config.eras.firstWhere(
        (item) => item.id == eraId,
        orElse: () => widget.config.eras.first,
      );
    }
    final eraDef = _cachedEraDef!;

    // Cache the tech tree graph — rebuild only when stateVersion changes or
    // purchase-mode / selection changes (both mutate _lastStateVersion via
    // invalidation calls in the relevant handlers).
    final stateVersion = _controller.stateVersion;
    if (_cachedGraph == null || stateVersion != _lastStateVersion) {
      _lastStateVersion = stateVersion;
      _cachedGraph = TechTreeBuilder.build(
        config: widget.config,
        controller: _controller,
        strings: widget.strings,
        purchaseMode: _purchaseMode,
        eraId: eraId,
        selectedNodeId: _selectedNodeId,
      );
    }
    final graph = _cachedGraph!;
    final node = graph.nodeById(_hoveredNodeId ?? _selectedNodeId ?? '');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradient.first.withAlpha(220),
              const Color(0xFF071018),
              gradient.last.withAlpha(120),
            ],
          ),
        ),
        child: SafeArea(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(widget.settings.uiScale),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                    child: Column(
                      children: [
                        _buildHud(accent),
                        const SizedBox(height: 6),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              _viewportSize = Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              );
                              final compact = constraints.maxWidth < 900 ||
                                  constraints.maxHeight < 600;
                              if (compact) {
                                return Column(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: _buildTreeArea(
                                              graph,
                                              accent,
                                              eraDef,
                                            ),
                                          ),
                                          if (node != null)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              bottom: 0,
                                              width: math.min(
                                                280,
                                                constraints.maxWidth * 0.42,
                                              ),
                                              child: _buildContextPanel(node),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildBottomDock(accent),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildTreeArea(graph, accent, eraDef),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: math.min(
                                      300,
                                      constraints.maxWidth * 0.26,
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: _buildContextPanel(node),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildSideControls(accent),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHud(Color accent) {
    final state = _controller.state;
    final currentEra = _currentEra(_controller);
    final currentEraDef = widget.config.eras.firstWhere(
      (item) => item.id == currentEra,
      orElse: () => widget.config.eras.first,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _glassBox(radius: 16),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    state.coins.toStringFormatted(),
                    key: ValueKey(state.coins.toStringFormatted()),
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _hudChip(
                  Icons.trending_up,
                  widget.strings.perSecond(
                    _controller.productionPerSecond.toStringFormatted(),
                  ),
                ),
                const SizedBox(width: 8),
                _hudChip(
                  Icons.local_fire_department,
                  widget.strings.combo(state.tapCombo),
                ),
                const SizedBox(width: 8),
                _hudChip(
                  Icons.meeting_room_rounded,
                  widget.strings.roomProgress(
                    currentEraDef.order,
                    widget.config.eras.length,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _hudIconButton(Icons.save_rounded, () {
                unawaited(_controller.saveGame());
                _showToast(widget.strings.gameSaved, Colors.green.shade700);
              }),
              _hudIconButton(Icons.bar_chart_rounded, _showStatsSheet),
              _hudIconButton(Icons.emoji_events_rounded, _showAchievementsSheet),
              _hudIconButton(Icons.menu_book_rounded, _showCodexSheet),
              _hudIconButton(Icons.auto_awesome, _showPrestigeSheet),
              _hudIconButton(Icons.settings_rounded, _showSettingsSheet),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hudChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white60),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _hudIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildTreeArea(TechTreeGraph graph, Color accent, Era eraDef) {
    final currentRoom = _controller.currentRoom;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: TechTreeView(
              graph: graph,
              selectedNodeId: _selectedNodeId,
              transformationController: _camera,
              viewportSize: _viewportSize,
              backgroundLayer: currentRoom == null
                  ? null
                  : RoomSceneBackdrop(
                      room: currentRoom,
                      roomState: _controller.currentRoomState,
                      reducedMotion: widget.settings.reducedMotion,
                    ),
              onNodeTap: (value) {
                unawaited(widget.audioService.playNodeSelect());
                setState(() {
                  _selectedNodeId = value.id;
                  _lastStateVersion = _kInvalidVersion; // Rebuild tree to show selection
                });
                _focusNode(value.position);
              },
              onHoverChanged: (value) {
                // Record without setState — TechTreeView handles hover visuals
                // internally. Context panel picks up the new value on the next
                // timer-driven rebuild (≤250 ms later), which is acceptable.
                _hoveredNodeId = value;
              },
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: _buildSceneHeader(eraDef, accent),
        ),
      ],
    );
  }

  Widget _buildSceneHeader(Era era, Color accent) {
    final ordered = widget.config.eras.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final index = ordered.indexWhere((item) => item.id == era.id);
    final previous = index > 0 ? ordered[index - 1] : null;
    final next = index >= 0 && index < ordered.length - 1 ? ordered[index + 1] : null;
    final bought = _roomUpgradeCount(era.id);
    final total = _roomUpgradeTotal(era.id);
    final stage = _roomStageLabel(era.id);
    final nextLoaded = next != null &&
        (widget.config.generators.values.any((item) => item.eraId == next.id) ||
            widget.config.upgrades.values.any((item) => item.eraId == next.id));

    return IgnorePointer(
      ignoring: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _glassBox(radius: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.strings.roomProgress(era.order, widget.config.eras.length)} • ${widget.strings.localizedEraName(era.name)}',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.strings.localizedEraDescription(era),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  if (_robotGuide.hasMessage) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${widget.strings.roomGuide}: ${_robotGuide.currentMessage!.text}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent.withAlpha(220),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _hudChip(Icons.auto_awesome, widget.strings.roomEvolutionStage(stage)),
                      _hudChip(Icons.account_tree_rounded,
                          widget.strings.roomUpgradeProgress(bought, total)),
                      _hudChip(Icons.rule_folder_outlined, widget.strings.localizedEraRule(era)),
                      ..._controller.state.activeMutators.take(2).map(
                        (mutator) => _hudChip(
                          Icons.bolt_rounded,
                          widget.strings.translateContent(mutator.title),
                        ),
                      ),
                      if (next != null && !nextLoaded)
                        _hudChip(Icons.hourglass_bottom_rounded,
                            widget.strings.preloadingNextRoom),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: widget.strings.previousRoom,
                  onPressed: previous != null && _controller.state.unlockedEras.contains(previous.id)
                      ? () => _switchEra(previous.id)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                FilledButton.tonalIcon(
                  onPressed: _showRoomMapSheet,
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: Text(widget.strings.roomMap),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: widget.strings.nextRoom,
                  onPressed: next != null && _controller.state.unlockedEras.contains(next.id)
                      ? () => _switchEra(next.id)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseMode(Color accent) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: widget.config.purchaseModes.map((mode) {
          final selected = mode == _purchaseMode;
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() {
              _purchaseMode = mode;
              _lastStateVersion = _kInvalidVersion; // Force tree rebuild on mode change
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected ? accent.withAlpha(70) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                mode.label,
                style: TextStyle(
                  color: selected ? accent : Colors.white.withAlpha(120),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAbilityBar() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _controller.abilities.values.map((ability) {
        final icon = switch (ability.type) {
          ActiveAbilityType.overclock => Icons.bolt,
          ActiveAbilityType.focus => Icons.ads_click,
          ActiveAbilityType.surge => Icons.flash_on,
          ActiveAbilityType.sync => Icons.sync,
        };
        return Opacity(
          opacity: ability.unlocked ? 1 : 0.3,
          child: Tooltip(
            message:
                '${widget.strings.formatAbilityLabel(ability.type)}\n${widget.strings.formatAbilityDescription(ability.type)}',
            child: InkWell(
              onTap: ability.unlocked
                  ? () => _activateAbility(ability.type)
                  : null,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(12)),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(height: 2),
                    Text(
                      ability.isReady
                          ? widget.strings.ready
                          : ability.isActive
                              ? widget.strings.secondsShort(
                                  ability.activeRemaining.ceil(),
                                )
                              : widget.strings.secondsShort(
                                  ability.cooldownRemaining.ceil(),
                                ),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomDock(Color accent) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _glassBox(radius: 16),
      child: Row(
        children: [
          _buildPurchaseMode(accent),
          const SizedBox(width: 8),
          Expanded(child: _buildAbilityBar()),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _buildTapOrb(accent),
              ..._gainToasts.map((toast) {
                return Positioned(
                  top: -8 - (toast.id % 3) * 14,
                  child: _AnimatedGainToast(
                    key: ValueKey(toast.id),
                    label: toast.label,
                    critical: toast.critical,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideControls(Color accent) {
    final currentEra = _currentEra(_controller);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _glassBox(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPurchaseMode(accent),
          const SizedBox(height: 8),
          _buildAbilityBar(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    _buildTapOrb(accent),
                    ..._gainToasts.map((toast) {
                      return Positioned(
                        top: -8 - (toast.id % 3) * 14,
                        child: _AnimatedGainToast(
                          key: ValueKey(toast.id),
                          label: toast.label,
                          critical: toast.critical,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _upgradeAll(currentEra),
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                  label: Text(
                    widget.strings.upgradeAll,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _hudIconButton(
                Icons.military_tech_rounded,
                _showChallengesSheet,
              ),
              _hudIconButton(
                Icons.leaderboard_rounded,
                _showLeaderboardSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContextPanel(TechTreeNodeData? node) {
    final currentEra = _currentEra(_controller);
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildGuideCard(),
          const SizedBox(height: 8),
          _buildRoomOverviewCard(),
          const SizedBox(height: 8),
          _buildRoomStatusPanel(),
          const SizedBox(height: 8),
          if (_controller.activeEvent != null) ...[
            _buildActiveEventCard(_controller.activeEvent!),
            const SizedBox(height: 8),
          ],
          if (currentEra == 'era_1') ...[
            _buildFirstRoomChecklist(),
            const SizedBox(height: 8),
          ],
          if (_controller.activeNarrativeBeat != null) ...[
            _buildNarrativeBeatCard(_controller.activeNarrativeBeat!),
            const SizedBox(height: 8),
          ],
          node == null
              ? Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _glassBox(radius: 18),
                  child: Row(
                    children: [
	                      const Icon(
	                        Icons.touch_app_rounded,
	                        color: Colors.white38,
	                        size: 20,
	                      ),
	                      const SizedBox(width: 10),
	                      Expanded(
	                        child: Text(
	                          widget.strings.selectNodeHint,
	                          style: const TextStyle(
	                            color: Colors.white54,
	                            fontSize: 13,
	                          ),
	                        ),
	                      ),
	                    ],
	                  ),
                )
              : _buildNodeCard(node),
          const SizedBox(height: 8),
          _buildNextRoomCard(currentEra),
          const SizedBox(height: 8),
          _buildRoomIdentityCard(currentEra),
          const SizedBox(height: 8),
          _buildSecretHintsCard(currentEra),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
    return RepaintBoundary(
      child: GuideCard(
        guideService: _robotGuide,
        strings: widget.strings,
        recommendation: _controller.lastRecommendation,
        aiLine: _controller.lastAiLine,
        recentMemories: _controller.codexState.guideMemories.reversed
            .take(2)
            .toList(growable: false),
        onFocusSuggestedNode: _focusSuggestedNode,
      ),
    );
  }

  Widget _buildRoomOverviewCard() {
    final room = _controller.currentRoom;
    final roomState = _controller.currentRoomState;
    if (room == null) {
      return const SizedBox.shrink();
    }

    final nextStageIndex = roomState.currentTransformationStage + 1;
    final nextStage = nextStageIndex < room.transformationStages.length
        ? room.transformationStages[nextStageIndex]
        : null;
    final currentStageIndex = room.transformationStages.isEmpty
        ? 0
        : roomState.currentTransformationStage.clamp(
            0,
            room.transformationStages.length - 1,
          );
    final currentStage = room.transformationStages.isEmpty
        ? null
        : room.transformationStages[currentStageIndex];
    final stageProgress = room.transformationStages.isEmpty
        ? 0.0
        : ((roomState.currentTransformationStage + 1) /
                room.transformationStages.length)
            .clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.strings.roomOverview,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.strings.translateContent(room.guideIntroLine),
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _hudChip(
                Icons.psychology_alt_rounded,
                '${widget.strings.guideToneLabel}: ${widget.strings.translateContent(room.guideTone)}',
              ),
              _hudChip(
                Icons.graphic_eq_rounded,
                '${widget.strings.ambientLayersLabel}: ${room.ambientAudioLayers.length}',
              ),
              _hudChip(
                Icons.auto_awesome_motion_rounded,
                '${widget.strings.secretsTrackedLabel}: ${room.secrets.length}',
              ),
              _hudChip(
                Icons.bolt_rounded,
                '${widget.strings.twistStatusLabel}: ${roomState.twistActivated ? widget.strings.transformationReady : widget.strings.transformationDormant}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.strings.transformationTrack,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: stageProgress,
            minHeight: 6,
            backgroundColor: Colors.white.withAlpha(12),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 6),
          Text(
            nextStage == null
                ? widget.strings.translateContent(room.completionText)
                : '${widget.strings.translateContent(nextStage.name)}\n${widget.strings.translateContent(nextStage.description)}',
            style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.35),
          ),
          if (currentStage != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.strings.environmentChanges,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: currentStage.environmentChanges
                  .map(
                    (change) => _hudChip(
                      Icons.blur_on_rounded,
                      widget.strings.formatEnvironmentChange(change),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomStatusPanel() {
    final room = _controller.currentRoom;
    final roomState = _controller.currentRoomState;
    if (room == null) return const SizedBox.shrink();
    return RoomStatusPanel(
      room: room,
      roomState: roomState,
      upgradesPurchased: roomState.upgradesPurchased,
    );
  }

  Widget _buildNarrativeBeatCard(NarrativeBeat beat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.strings.storyBeat,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final dismissed = _controller.dismissNarrativeBeat(beat.id);
                  if (!dismissed) return;
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                splashRadius: 18,
                color: Colors.white54,
                tooltip: widget.strings.close,
              ),
            ],
          ),
          Text(
            widget.strings.translateContent(beat.title),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.strings.translateContent(beat.body),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEventCard(GameEventState event) {
    final chainValue = math.max(1, _controller.state.currentEventChain + 1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.strings.activeEventTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                widget.strings.eventRarityLabel(event.rarity).toUpperCase(),
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.strings.translateContent(event.title),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.strings.translateContent(event.description),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _nodeStatChip(
                  widget.strings.eventChain,
                  'x$chainValue',
                  Colors.cyanAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _nodeStatChip(
                  widget.strings.timeRemaining,
                  widget.strings.secondsShort(event.remainingSeconds.ceil()),
                  Colors.amberAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final ok = _controller.dismissActiveEvent();
                    if (!ok) return;
                    setState(() {});
                  },
                  child: Text(widget.strings.close),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
        final ok = _controller.resolveActiveEvent(
          aggressiveChoice: event.risky && !event.clickOnly,
        );
        if (!ok) return;
        unawaited(
          widget.audioService.playEventResolve(
            roomId: _controller.currentRoomId,
            rarity: event.rarity,
          ),
        );
        _handleFeedback();
        setState(() {});
      },
                  child: Text(
                    event.clickOnly
                        ? widget.strings.takeChoice
                        : (event.risky
                            ? widget.strings.pushChoice
                            : widget.strings.safeChoice),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomIdentityCard(String eraId) {
    final identity = RoomContentGenerator.identityForEra(eraId);
    final branchLabels = identity.branchFocus
        .map(widget.strings.roomBranchLabel)
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.strings.roomIdentity,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.strings.formatRoomFlavor(identity.flavorKey),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.strings.roomFocusSummary(branchLabels),
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: branchLabels
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withAlpha(14)),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCard(TechTreeNodeData node) {
    final purchaseState = _nodePurchaseState(node);
    final stateColor = _purchaseStateColor(purchaseState);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(radius: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                node.icon,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      node.subtitle.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: stateColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stateColor.withAlpha(80)),
                ),
                child: Text(
                  _purchaseStateLabel(purchaseState),
                  style: TextStyle(
                    color: stateColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            node.description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _nodeStatChip(
                  widget.strings.cost,
                  node.costLabel,
                  Colors.amberAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _nodeStatChip(
                  widget.strings.effect,
                  node.effectLabel,
                  Colors.lightBlueAccent,
                ),
              ),
            ],
          ),
          if (node.dependencyLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            _nodeStatChip(
              widget.strings.dependency,
              node.dependencyLabel,
              Colors.white54,
            ),
          ],
          if (node.requirementLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            _nodeStatChip(
              widget.strings.requirement,
              node.requirementLabel,
              Colors.white54,
            ),
          ],
          if (_controller.state.chosenBranches.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _controller.state.chosenBranches
                  .map(
                    (branch) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withAlpha(16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.cyanAccent.withAlpha(50),
                        ),
                      ),
                      child: Text(
                        _branchLabel(branch),
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (_controller.canChooseBranch &&
              node.kind == TechTreeNodeKind.generator &&
              _controller.state.chosenBranches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.config.progression.branches
                    .map((branch) => _branchButton(branch.id, widget.strings.translateContent(branch.title)))
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: node.locked || node.kind == TechTreeNodeKind.secret
                  ? null
                  : () => _purchaseNode(node),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: purchaseState == _NodePurchaseState.canBuy
                    ? Colors.cyanAccent.withAlpha(200)
                    : null,
                foregroundColor: purchaseState == _NodePurchaseState.canBuy
                    ? const Color(0xFF071018)
                    : null,
              ),
              child: Text(
                node.kind == TechTreeNodeKind.secret
                    ? (node.purchased
                        ? widget.strings.discovered
                        : widget.strings.hidden)
                    : node.locked
                        ? widget.strings.locked
                        : widget.strings.purchase,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (_controller.state.chosenBranches.isNotEmpty) ...[
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final compactActions = constraints.maxWidth < 320;
                final respecButton = OutlinedButton(
                  onPressed: _controller.state.branchRespecTokens > 0
                      ? () {
                          final ok = _controller.respecBranch();
                          if (!ok) return;
                          setState(() {});
                        }
                      : null,
                  child: Text(
                    widget.strings.respecLabel(
                      _controller.state.branchRespecTokens,
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
                final loadoutButton = OutlinedButton(
                  onPressed: () => _showLoadoutSheet(),
                  child: Text(
                    widget.strings.loadout,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
                if (compactActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      respecButton,
                      const SizedBox(height: 6),
                      loadoutButton,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: respecButton),
                    const SizedBox(width: 6),
                    Expanded(child: loadoutButton),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _nodeStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withAlpha(160),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _branchButton(String branchId, String label) {
    return OutlinedButton(
      onPressed: () {
        final picked = _controller.chooseBranch(branchId);
        if (!picked) return;
        unawaited(widget.audioService.playBranchUnlock());
        setState(() {});
      },
      child: Text(label),
    );
  }

  Widget _buildTapOrb(Color accent) {
    final gain = TapSystem.calculateTapValueWithCombo(
      widget.config.baseTapValue,
      _controller.state.tapMultiplier,
      _controller.state.tapCombo,
      _controller.state.prestigeMultiplier,
    );
    final cooldownProgress = _controller.tapCooldownProgress;
    final canTap = _controller.canTap;
    return InkWell(
      onTap: _tap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, accent.withAlpha(90)],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(100),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: CircularProgressIndicator(
                    value: cooldownProgress,
                    strokeWidth: 3,
                    backgroundColor: Colors.white.withAlpha(16),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      canTap ? Colors.white70 : Colors.cyanAccent,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: canTap ? 1 : 0.94,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: canTap ? 1 : 0.72,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canTap
                          ? Icons.touch_app
                          : Icons.hourglass_bottom_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '+${gain.toStringFormatted()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _tap() {
    if (!_controller.canTap) {
      unawaited(widget.audioService.playUiInteraction());
      setState(() {});
      return;
    }
    HapticFeedback.lightImpact();
    unawaited(widget.audioService.playTap());
    setState(() {
      final tapped = _controller.tap();
      if (!tapped) return;
      _gainToasts.add(
        _GainToast(
          id: _toastId++,
          label:
              '+${_controller.lastTapGain.toStringFormatted()}${_controller.lastTapWasCritical ? ' CRIT' : ''}',
          critical: _controller.lastTapWasCritical,
        ),
      );
    });
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || _gainToasts.isEmpty) return;
      setState(() => _gainToasts.removeAt(0));
    });
  }

  void _activateAbility(ActiveAbilityType type) {
    final ok = _controller.activateAbility(type);
    if (!ok) {
      unawaited(widget.audioService.playInsufficientFunds());
      return;
    }
    unawaited(widget.audioService.playPurchase());
    setState(() {});
  }

  void _purchaseNode(TechTreeNodeData node) {
    if (node.kind == TechTreeNodeKind.secret) return;
    final purchased = node.kind == TechTreeNodeKind.generator
        ? _controller.purchaseGenerator(node.id, quantity: _generatorQuantity(node.id))
        : _controller.purchaseUpgrade(
            node.id,
            quantity: _upgradeQuantity(node.id),
          );
    if (!purchased) {
      unawaited(widget.audioService.playInsufficientFunds());
      return;
    }
    unawaited(widget.audioService.playPurchase());
    _handleFeedback();
    setState(() {});
  }

  int _generatorQuantity(String generatorId) {
    final generator = widget.config.generators[generatorId];
    if (generator == null) return 1;
    final currentLevel = _controller.state.generators[generatorId]?.level ?? 0;
    switch (_purchaseMode) {
      case PurchaseMode.x1:
        return 1;
      case PurchaseMode.x10:
        return 10;
      case PurchaseMode.x100:
        return 100;
      case PurchaseMode.max:
        int quantity = 0;
        var level = currentLevel;
        var coins = _controller.state.coins;
        while (quantity < 999) {
          final cost = generator.baseCost *
              GameNumber.fromDouble(
                math.pow(generator.costGrowthRate, level).toDouble(),
              );
          if (coins < cost) break;
          coins = coins - cost;
          level++;
          quantity++;
        }
        return math.max(1, quantity);
    }
  }

  int _upgradeQuantity(String upgradeId) {
    final upgrade = widget.config.upgrades[upgradeId];
    if (upgrade == null) return 1;
    final currentLevel = _controller.state.upgrades[upgradeId]?.level ?? 0;
    final remainingLevels =
        math.max(0, upgrade.maxLevel - currentLevel);
    if (remainingLevels <= 0) return 1;
    switch (_purchaseMode) {
      case PurchaseMode.x1:
        return 1;
      case PurchaseMode.x10:
        return math.min(10, remainingLevels);
      case PurchaseMode.x100:
        return math.min(100, remainingLevels);
      case PurchaseMode.max:
        return CostCalculator.maxAffordable(
          upgrade.baseCost,
          upgrade.costGrowthRate,
          currentLevel,
          _controller.state.coins,
        ).clamp(1, remainingLevels);
    }
  }

  void _handleFeedback() {
    final room = _controller.currentRoom;
    final roomState = _controller.currentRoomState;
    if (_lastRoomStage != roomState.currentTransformationStage) {
      if (_lastRoomStage >= 0 &&
          room != null &&
          roomState.currentTransformationStage < room.transformationStages.length) {
        final stage = room.transformationStages[roomState.currentTransformationStage];
        _showToast(
          widget.strings.translateContent(stage.name),
          Colors.cyanAccent,
        );
        unawaited(
          widget.audioService.playTransformationAdvance(
            roomId: _controller.currentRoomId,
          ),
        );
      }
      _lastRoomStage = roomState.currentTransformationStage;
      _robotGuide.onTransformationStageAdvanced(_controller.currentRoomId);
    }
    if (_lastRoomTwist != roomState.twistActivated) {
      if (roomState.twistActivated && room?.midSceneTwist != null) {
        _showToast(
          widget.strings.translateContent(room!.midSceneTwist!.title),
          Colors.deepOrangeAccent,
        );
        unawaited(
          widget.audioService.playRoomTwist(roomId: _controller.currentRoomId),
        );
      }
      _lastRoomTwist = roomState.twistActivated;
    }
    if (_lastSecretCount != _controller.state.discoveredSecrets.length) {
      if (_lastSecretCount > 0 ||
          _controller.state.discoveredSecrets.isNotEmpty) {
        unawaited(
          widget.audioService.playSecretDiscovered(
            roomId: _controller.currentRoomId,
          ),
        );
      }
      _lastSecretCount = _controller.state.discoveredSecrets.length;
    }
    if (_lastCompletedRooms != _controller.roomsCompleted) {
      if (_lastCompletedRooms > 0 || _controller.roomsCompleted > 0) {
        unawaited(
          widget.audioService.playRoomComplete(roomId: _controller.currentRoomId),
        );
      }
      _lastCompletedRooms = _controller.roomsCompleted;
    }
    if (_lastGuideMemoryCount != _controller.codexState.guideMemories.length) {
      if (_controller.codexState.guideMemories.isNotEmpty) {
        unawaited(
          widget.audioService.playGuideNotification(
            roomId: _controller.currentRoomId,
          ),
        );
      }
      _lastGuideMemoryCount = _controller.codexState.guideMemories.length;
    }
    final activeEvent = _controller.activeEvent;
    if (activeEvent?.id != _lastEventId) {
      _lastEventId = activeEvent?.id;
      if (activeEvent != null) {
        _showToast(
          widget.strings.translateContent(activeEvent.title),
          Colors.deepPurpleAccent,
        );
        unawaited(
          widget.audioService.playEventSpawn(
            roomId: _controller.currentRoomId,
            rarity: activeEvent.rarity,
          ),
        );
      }
    }
    if (_controller.lastUnlockedAchievements.isNotEmpty) {
      _showToast(
        '${widget.strings.achievementUnlocked}: ${_controller.lastUnlockedAchievements.first.name}',
        Colors.amberAccent,
      );
      unawaited(widget.audioService.playReward());
      _controller.lastUnlockedAchievements = [];
    }
    if (_controller.lastUnlockedMilestones.isNotEmpty) {
      final titles = _controller.lastUnlockedMilestones
          .map((id) => widget.strings.translateContent(widget.config.milestoneById(id)?.title ?? id))
          .join(', ');
      _showToast(
        widget.strings.unlockedMilestonesToast(titles),
        const Color(0xFF74E6FF),
      );
      unawaited(widget.audioService.playMilestone());
      _controller.lastUnlockedMilestones = [];
    }
    // Guide hook-ups for first-time milestones
    if (_controller.firstTapJustHappened) {
      _controller.firstTapJustHappened = false;
      _robotGuide.onFirstTap();
    }
    if (_controller.firstUpgradeJustPurchased) {
      _controller.firstUpgradeJustPurchased = false;
      _robotGuide.onFirstUpgradePurchased();
    }
    if (_controller.firstEventJustSpawned) {
      _controller.firstEventJustSpawned = false;
      _robotGuide.onFirstEventAppeared();
    }
  }

  void _handleUpdateServiceChanged() {
    if (!mounted) return;
    final updateService = widget.updateService;
    if (updateService.phase == AppUpdatePhase.available &&
        updateService.config.showPromptWhenAvailable &&
        updateService.availableVersion != null &&
        updateService.availableVersion != _lastPromptedUpdateVersion) {
      _lastPromptedUpdateVersion = updateService.availableVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showUpdateAvailableDialog();
      });
    }
    if (updateService.phase == AppUpdatePhase.readyToRestart &&
        updateService.availableVersion != null &&
        updateService.availableVersion != _lastRestartPromptVersion) {
      _lastRestartPromptVersion = updateService.availableVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showRestartToApplyDialog();
      });
    }
  }

  Future<void> _runManualUpdateCheck() async {
    final foundUpdate = await widget.updateService.checkForUpdates();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final strings = widget.strings;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          foundUpdate
              ? strings.updateAvailableSnackbar(widget.updateService.availableVersion)
              : strings.upToDateSnackbar,
        ),
      ),
    );
  }

  Future<void> _showUpdateAvailableDialog() async {
    final updateService = widget.updateService;
    if (!updateService.hasUpdate) return;
    final strings = widget.strings;
    final notes = updateService.releaseNotes;
    await showDialog<void>(
      context: context,
      barrierDismissible: !updateService.isMandatory,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF132332),
        title: Text(
          strings.updateAvailableTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.updateAvailableBody(
                  updateService.availableVersion ?? strings.unknownLabel,
                ),
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  strings.releaseNotesLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...notes.take(5).map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• ${note.message}',
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
              if (updateService.totalBytes > 0) ...[
                const SizedBox(height: 12),
                Text(
                  strings.updateDownloadSize(
                    updateService.totalMegabytes.toStringAsFixed(2),
                  ),
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!updateService.isMandatory)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.laterLabel),
            ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await widget.updateService.downloadUpdate();
            },
            icon: const Icon(Icons.download_rounded),
            label: Text(strings.downloadUpdateLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestartToApplyDialog() async {
    final strings = widget.strings;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF132332),
        title: Text(
          strings.updateReadyTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          strings.updateReadyBody,
          style: const TextStyle(color: Colors.white70, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.laterLabel),
          ),
          FilledButton.icon(
            onPressed: () async {
              await widget.updateService.restartToApply();
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(strings.restartToUpdateLabel),
          ),
        ],
      ),
    );
  }

  String _updateStatusLabel(AppUpdateService updateService) {
    final strings = widget.strings;
    return switch (updateService.phase) {
      AppUpdatePhase.unsupported => strings.updatesUnsupported,
      AppUpdatePhase.disabled => strings.updatesDisabled,
      AppUpdatePhase.idle => strings.updatesIdle,
      AppUpdatePhase.checking => strings.checkingForUpdates,
      AppUpdatePhase.upToDate => strings.updatesUpToDate,
      AppUpdatePhase.available => strings.updateAvailableSnackbar(
          updateService.availableVersion,
        ),
      AppUpdatePhase.downloading => strings.updateDownloading(
          updateService.downloadedMegabytes.toStringAsFixed(2),
          updateService.totalMegabytes.toStringAsFixed(2),
        ),
      AppUpdatePhase.readyToRestart => strings.updateReadyStatus,
      AppUpdatePhase.error => strings.updateError(
          updateService.errorMessage ?? strings.unknownLabel,
        ),
    };
  }

  void _syncEraWindow(String eraId) {
    widget.config.ensureEraContent(eraId);
    final ordered = widget.config.eras.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final index = ordered.indexWhere((item) => item.id == eraId);
    if (index < 0) return;

    for (final neighborIndex in [index - 1, index + 1]) {
      if (neighborIndex < 0 || neighborIndex >= ordered.length) continue;
      final neighbor = ordered[neighborIndex];
      if (_queuedEraPreloads.contains(neighbor.id)) continue;
      _queuedEraPreloads.add(neighbor.id);
      Future<void>.microtask(() {
        widget.config.ensureEraContent(neighbor.id);
        _queuedEraPreloads.remove(neighbor.id);
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _switchEra(String eraId) {
    if (!_controller.setCurrentEra(eraId)) return;
    widget.audioService.setRoomAudioProfile(_controller.currentRoomId);
    unawaited(
      widget.audioService.playRoomTransition(roomId: _controller.currentRoomId),
    );
    // Warm-start the new room's audio assets non-blocking after the transition.
    unawaited(
      widget.audioService.preloadEssentials(roomId: _controller.currentRoomId),
    );
    _syncEraWindow(eraId);
    _selectedNodeId = null;
    _cachedGraph = null;
    _cachedEraDef = null;
    _lastStateVersion = _kInvalidVersion; // Force tree rebuild
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrentEra());
  }

  void _focusCurrentEra() {
    // Use the cached graph if available, otherwise build one
    final graph = _cachedGraph ?? TechTreeBuilder.build(
      config: widget.config,
      controller: _controller,
      strings: widget.strings,
      purchaseMode: _purchaseMode,
      eraId: _currentEra(_controller),
      selectedNodeId: _selectedNodeId,
    );
    if (graph.nodes.isEmpty) return;
    final current = graph.nodes.firstWhere(
      (item) => item.kind == TechTreeNodeKind.generator,
      orElse: () => graph.nodes.first,
    );
    _focusNode(current.position, zoom: 0.78);
  }

  void _focusNode(Offset position, {double zoom = 0.92}) {
    final dx = (_viewportSize.width / 2) - (position.dx * zoom);
    final dy = (_viewportSize.height / 2) - (position.dy * zoom);
    _camera.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(zoom, zoom, 1, 1);
  }

  void _showOffline() {
    if (_offlineShown) return;
    _offlineShown = true;
    final earnings = _controller.pendingOfflineEarnings;
    final summary = _controller.pendingReturnSummary;
    if (earnings == null || earnings.isZero) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121D28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(widget.strings.welcomeBack,
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '+${earnings.toStringFormatted()}',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (summary != null)
              Text(
                widget.strings.awaySummary(
                  summary.timeAway.inMinutes,
                  widget.strings.formatOfflineObservation(summary.observation),
                  widget.strings.formatReturnIncentive(summary.incentive),
                ),
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.strings.collect),
          ),
        ],
      ),
    );
    _controller.pendingOfflineEarnings = null;
    _controller.pendingReturnSummary = null;
  }

  void _upgradeAll(String eraId) {
    final purchased = _controller.purchaseAllInEra(eraId);
    if (purchased <= 0) {
      _showToast(widget.strings.nothingAffordable, Colors.white38);
      unawaited(widget.audioService.playInsufficientFunds());
      return;
    }
    _showToast(
      widget.strings.upgradeAllPurchased(purchased),
      Colors.green.shade700,
    );
    unawaited(widget.audioService.playPurchase());
    _handleFeedback();
    setState(() {});
  }

  void _focusSuggestedNode() {
    final graph = _cachedGraph;
    if (graph == null) return;
    TechTreeNodeData? candidate;
    for (final node in graph.nodes) {
      if (node.kind == TechTreeNodeKind.secret || node.purchased) {
        continue;
      }
      if (_nodePurchaseState(node) == _NodePurchaseState.canBuy) {
        candidate = node;
        break;
      }
    }
    if (candidate == null) {
      _showToast(widget.strings.nothingAffordable, Colors.white38);
      return;
    }
    setState(() => _selectedNodeId = candidate!.id);
    _focusNode(candidate.position);
    unawaited(widget.audioService.playNodeSelect());
  }

  int _roomUpgradeTotal(String eraId) {
    return widget.config.upgrades.values
        .where((item) => item.eraId == eraId)
        .length;
  }

  int _roomUpgradeCount(String eraId) {
    var count = 0;
    for (final upgrade in widget.config.upgrades.values.where((item) => item.eraId == eraId)) {
      if ((_controller.state.upgrades[upgrade.id]?.level ?? 0) > 0) {
        count++;
      }
    }
    return count;
  }

  String _roomStageLabel(String eraId) {
    final total = math.max(1, _roomUpgradeTotal(eraId));
    final ratio = _roomUpgradeCount(eraId) / total;
    if (ratio < 0.2) return widget.strings.stageDormant;
    if (ratio < 0.45) return widget.strings.stageActive;
    if (ratio < 0.75) return widget.strings.stageRefined;
    return widget.strings.stageAscendant;
  }

  Future<void> _showRoomMapSheet() async {
    final ordered = _controller.allRooms.isNotEmpty
        ? _controller.allRooms
        : widget.config.eras
            .toList()
            .map((era) => _controller.roomForEra(era.id))
            .whereType<RoomScene>()
            .toList();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121D28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetTitle(widget.strings.roomMap),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: ordered.map((room) {
                      final era = widget.config.eras.firstWhere(
                        (item) => item.order == room.order,
                        orElse: () => widget.config.eras.first,
                      );
                      final unlocked = _controller.metaProgression.roomsCompleted
                              .contains(room.unlockRequirement) ||
                          room.unlockRequirement == null;
                      final selected = _controller.currentRoomId == room.id;
                      final roomState = _controller.state.roomStates[room.id] ??
                          RoomSceneState(roomId: room.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.cyanAccent.withAlpha(18)
                              : Colors.white.withAlpha(6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? Colors.cyanAccent.withAlpha(90)
                                : Colors.white.withAlpha(14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.strings.roomProgress(room.order, ordered.length)} • ${widget.strings.localizedEraName(room.name)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.strings.translateContent(room.subtitle)}\n${widget.strings.translateContent(room.guideTone)}',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _hudChip(Icons.auto_awesome_motion_rounded,
                                          widget.strings.roomUpgradeProgress(
                                            roomState.upgradesPurchased,
                                            room.transformationStages.isEmpty
                                                ? 0
                                                : room.transformationStages.last.requiredUpgrades,
                                          )),
                                      _hudChip(Icons.graphic_eq_rounded,
                                          '${widget.strings.ambientLayersLabel}: ${room.ambientAudioLayers.length}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.tonal(
                              onPressed: unlocked
                                  ? () {
                                      Navigator.pop(context);
                                      _switchEra(era.id);
                                    }
                                  : null,
                              child: Text(
                                unlocked
                                    ? (selected
                                        ? widget.strings.currentRoom
                                        : widget.strings.enterRoomZero)
                                    : widget.strings.locked,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstRoomChecklist() {
    final generatorLevel = _controller.state.generators['gen_era_1']?.level ?? 0;
    final upgradesBought = _roomUpgradeCount('era_1');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.strings.firstRoomChecklist,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _tutorialLine(
            Icons.touch_app_rounded,
            widget.strings.tutorialTapGoal(
              math.min(_controller.state.totalTaps, 25),
              25,
            ),
            _controller.state.totalTaps >= 25,
          ),
          _tutorialLine(
            Icons.memory_rounded,
            widget.strings.tutorialGeneratorGoal(
              math.min(generatorLevel, 6),
              6,
            ),
            generatorLevel >= 6,
          ),
          _tutorialLine(
            Icons.upgrade_rounded,
            widget.strings.tutorialUpgradeGoal(
              math.min(upgradesBought, 8),
              8,
            ),
            upgradesBought >= 8,
          ),
        ],
      ),
    );
  }

  Widget _tutorialLine(IconData icon, String text, bool complete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle_rounded : icon,
            color: complete ? Colors.greenAccent : Colors.white54,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: complete ? Colors.white : Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextRoomCard(String currentEraId) {
    final ordered = widget.config.eras.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final index = ordered.indexWhere((item) => item.id == currentEraId);
    if (index < 0 || index >= ordered.length - 1) {
      return const SizedBox.shrink();
    }
    final nextEra = ordered[index + 1];
    GeneratorDefinition? nextGenerator;
    for (final generator in widget.config.generators.values) {
      if (generator.eraId == nextEra.id) {
        nextGenerator = generator;
        break;
      }
    }
    final requirement = nextGenerator?.unlockRequirement;
    var requirementText = nextEra.description;
    int? currentLevel;
    int? neededLevel;
    if (requirement != null) {
      final parts = requirement.split(':');
      if (parts.length == 2) {
        currentLevel = _controller.state.generators[parts.first]?.level ?? 0;
        neededLevel = int.tryParse(parts.last) ?? 1;
        requirementText = widget.strings.unlockRequirementLabel(
          parts.first.replaceAll('_', ' '),
          neededLevel,
        );
        requirementText = '$requirementText • ${widget.strings.generatorLevelLabel(currentLevel)}';
      }
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.strings.nextRoomTarget,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.strings.localizedEraName(nextEra.name),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            requirementText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (currentLevel != null && neededLevel != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (currentLevel / math.max(1, neededLevel)).clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.white.withAlpha(16),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
              borderRadius: BorderRadius.circular(999),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecretHintsCard(String eraId) {
    final hints = widget.config.progression.secrets
        .where((item) => item.eraId == eraId)
        .where((item) => !_controller.state.discoveredSecrets.contains(item.id))
        .take(3)
        .toList();
    if (hints.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _glassBox(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                color: Colors.white38,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                widget.strings.secretHints,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...hints.map(
            (secret) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.strings.formatSecretHint(
                  secret,
                  branchLabel: secret.requiredBranchId == null
                      ? null
                      : widget.strings.translateContent(widget.config
                              .branchById(secret.requiredBranchId!)
                              ?.title ??
                          secret.requiredBranchId!),
                  milestoneTitle: secret.requiredMilestoneId == null
                      ? null
                      : widget.strings.translateContent(widget.config
                              .milestoneById(
                                secret.requiredMilestoneId!,
                              )
                              ?.title ??
                          secret.requiredMilestoneId!),
                ),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121D28),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetTitle(widget.strings.settings),

                _settingsSectionHeader(widget.strings.settingsGeneral),
                ListTile(
                  leading: const Icon(
                    Icons.language_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  title: Text(widget.strings.language,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(widget.strings.chooseLanguage,
                      style: const TextStyle(color: Colors.white54)),
                  trailing: DropdownButton<AppLanguage>(
                    value: widget.settings.language,
                    dropdownColor: const Color(0xFF121D28),
                    items: [
                      DropdownMenuItem(
                        value: AppLanguage.english,
                        child: Text(widget.strings.english,
                            style: const TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: AppLanguage.russian,
                        child: Text(widget.strings.russian,
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;
                      await widget.onSettingsChanged(
                        widget.settings.copyWith(language: value),
                      );
                      if (!mounted) return;
                      setState(() {});
                      setSheetState(() {});
                    },
                  ),
                ),

                const Divider(color: Colors.white10, height: 24),
                _settingsSectionHeader(widget.strings.settingsUpdates),
                ListenableBuilder(
                  listenable: widget.updateService,
                  builder: (context, _) {
                    final updateService = widget.updateService;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          secondary: const Icon(
                            Icons.system_update_alt_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          value: widget.settings.autoCheckUpdates,
                          title: Text(
                            widget.strings.autoCheckUpdatesLabel,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            widget.strings.autoCheckUpdatesDescription,
                            style: const TextStyle(color: Colors.white54),
                          ),
                          onChanged: (value) async {
                            await widget.onSettingsChanged(
                              widget.settings.copyWith(autoCheckUpdates: value),
                            );
                            if (!mounted) return;
                            setState(() {});
                            setSheetState(() {});
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.update_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          title: Text(
                            widget.strings.updates,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            _updateStatusLabel(updateService),
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: Text(
                            updateService.currentBuild == null
                                ? widget.strings.unknownLabel
                                : widget.strings.updateBuildLabel(
                                    updateService.currentBuild!,
                                  ),
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!updateService.isSupported)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 8,
                            ),
                            child: Text(
                              widget.strings.updatesWindowsOnly,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else if (!updateService.config.isConfigured)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 8,
                            ),
                            child: Text(
                              widget.strings.updatesConfigurationHint,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ),
                        if (updateService.isDownloading)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(
                                  value: updateService.downloadProgress == 0
                                      ? null
                                      : updateService.downloadProgress,
                                  minHeight: 8,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.strings.updateDownloading(
                                    updateService.downloadedMegabytes
                                        .toStringAsFixed(2),
                                    updateService.totalMegabytes
                                        .toStringAsFixed(2),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (updateService.hasUpdate &&
                            updateService.releaseNotes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.strings.releaseNotesLabel,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...updateService.releaseNotes.take(4).map(
                                  (note) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '• ${note.message}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: updateService.isEnabled &&
                                        updateService.phase !=
                                            AppUpdatePhase.checking
                                    ? _runManualUpdateCheck
                                    : null,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(widget.strings.checkForUpdatesLabel),
                              ),
                              if (updateService.hasUpdate &&
                                  !updateService.isDownloading &&
                                  !updateService.readyToRestart)
                                FilledButton.icon(
                                  onPressed: () async {
                                    await updateService.downloadUpdate();
                                  },
                                  icon: const Icon(Icons.download_rounded),
                                  label:
                                      Text(widget.strings.downloadUpdateLabel),
                                ),
                              if (updateService.readyToRestart)
                                FilledButton.icon(
                                  onPressed: () async {
                                    await updateService.restartToApply();
                                  },
                                  icon: const Icon(Icons.restart_alt_rounded),
                                  label:
                                      Text(widget.strings.restartToUpdateLabel),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const Divider(color: Colors.white10, height: 24),
                _settingsSectionHeader(widget.strings.settingsAudio),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  value: widget.settings.soundEnabled,
                  title: Text(widget.strings.sound,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(widget.strings.soundOn,
                      style: const TextStyle(color: Colors.white54)),
                  onChanged: (value) async {
                    await widget.onSettingsChanged(
                      widget.settings.copyWith(soundEnabled: value),
                    );
                    if (!mounted) return;
                    setState(() {});
                    setSheetState(() {});
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  title: Text(widget.strings.musicLayer,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Slider(
                    value: widget.settings.musicVolume,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    label: widget.settings.musicVolume.toStringAsFixed(1),
                    onChanged: (value) async {
                      await widget.onSettingsChanged(
                        widget.settings.copyWith(musicVolume: value),
                      );
                      if (!mounted) return;
                      setState(() {});
                      setSheetState(() {});
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  title: Text(widget.strings.sfxVolume,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Slider(
                    value: widget.settings.sfxVolume,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    label: widget.settings.sfxVolume.toStringAsFixed(1),
                    onChanged: (value) async {
                      await widget.onSettingsChanged(
                        widget.settings.copyWith(sfxVolume: value),
                      );
                      if (!mounted) return;
                      setState(() {});
                      setSheetState(() {});
                    },
                  ),
                ),

                const Divider(color: Colors.white10, height: 24),
                _settingsSectionHeader(widget.strings.settingsAccessibility),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.animation_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  value: widget.settings.reducedMotion,
                  title: Text(widget.strings.reducedMotion,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(widget.strings.reducedMotionDescription,
                      style: const TextStyle(color: Colors.white54)),
                  onChanged: (value) async {
                    await widget.onSettingsChanged(
                      widget.settings.copyWith(reducedMotion: value),
                    );
                    if (!mounted) return;
                    setState(() {});
                    setSheetState(() {});
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.vibration_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  value: widget.settings.screenShake,
                  title: Text(widget.strings.screenShake,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(widget.strings.screenShakeDescription,
                      style: const TextStyle(color: Colors.white54)),
                  onChanged: (value) async {
                    await widget.onSettingsChanged(
                      widget.settings.copyWith(screenShake: value),
                    );
                    if (!mounted) return;
                    setState(() {});
                    setSheetState(() {});
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.palette_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  title: Text(widget.strings.colorClarity,
                      style: const TextStyle(color: Colors.white)),
                  trailing: DropdownButton<ColorblindMode>(
                    value: widget.settings.colorblindMode,
                    dropdownColor: const Color(0xFF121D28),
                    items: ColorblindMode.values
                        .map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(
                                  widget.strings.formatColorblindMode(mode),
                                  style:
                                      const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      await widget.onSettingsChanged(
                        widget.settings.copyWith(colorblindMode: value),
                      );
                      if (!mounted) return;
                      setState(() {});
                      setSheetState(() {});
                    },
                  ),
                ),

                const Divider(color: Colors.white10, height: 24),
                _settingsSectionHeader(widget.strings.settingsGraphics),
                ListTile(
                  leading: const Icon(
                    Icons.text_fields_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  title: Text(widget.strings.uiScale,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Slider(
                    value: widget.settings.uiScale,
                    min: 0.85,
                    max: 1.5,
                    divisions: 13,
                    label: widget.settings.uiScale.toStringAsFixed(2),
                    onChanged: (value) async {
                      await widget.onSettingsChanged(
                        widget.settings.copyWith(uiScale: value),
                      );
                      if (!mounted) return;
                      setState(() {});
                      setSheetState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _showCodexSheet() async {
    final orderedEras = widget.config.eras.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    // Do NOT pre-load all configured eras' content here — iterating every era
    // and calling ensureEraContent() triggers a blocking synchronous JSON parse
    // for each room not yet loaded, causing a visible hitch when opening the
    // codex. Era content is lazy-loaded by _syncEraWindow as the player
    // progresses through rooms, so only already-visited eras are available in
    // the overview section; this is intentional.
    final seenEvents = _controller.seenEventTemplates;
    const sections = [
      'overview',
      'guide',
      'route',
      'secrets',
      'lore',
      'collections',
    ];
    var section = sections.first;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121D28),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.76,
          maxChildSize: 0.94,
          minChildSize: 0.48,
          expand: false,
          builder: (context, scrollController) {
            // Compute the flat item list once per section so the
            // SliverList.builder has a known itemCount without rebuilding
            // all widgets up-front.
            final items = _codexSectionItems(
              section,
              orderedEras: orderedEras,
              seenEvents: seenEvents,
            );
            return CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetTitle(widget.strings.codex),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: sections
                              .map(
                                (item) => ChoiceChip(
                                  selected: section == item,
                                  onSelected: (_) =>
                                      setModalState(() => section = item),
                                  label: Text(
                                      widget.strings.codexSectionLabel(item)),
                                ),
                              )
                              .toList(),
                        ),
                        // Static header for the selected section (stat lines,
                        // summary text, etc.) — always a small fixed set of
                        // widgets, never a long list.
                        _buildCodexSectionHeader(
                          section,
                          orderedEras: orderedEras,
                          seenEvents: seenEvents,
                        ),
                      ],
                    ),
                  ),
                ),
                // Virtualized list — only the visible archive cards are built.
                SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: _buildCodexItemWidget(items[index]),
                  ),
                ),
                // Bottom padding inside scroll area.
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Returns only the static header widgets for a codex section (stat lines,
  /// summary text, etc.). These are a small, fixed set and are always built.
  Widget _buildCodexSectionHeader(
    String section, {
    required List<Era> orderedEras,
    required Set<String> seenEvents,
  }) {
    final codex = _controller.codexState;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: switch (section) {
        'guide' => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statLine(
                widget.strings.guideAffinityLabel,
                _controller.guideAffinity.toStringAsFixed(1),
              ),
              _statLine(
                widget.strings.guideTierLabel,
                widget.strings.formatGuideTier(_controller.guideTier),
              ),
            ],
          ),
        'route' => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.strings.playstyle}: ${widget.strings.formatPlaystyle(_controller.dominantPlaystyle)}\n${widget.strings.route}: ${_controller.state.chosenBranches.isEmpty ? widget.strings.hidden : _controller.state.chosenBranches.map(_branchLabel).join(' / ')}',
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
            ],
          ),
        'secrets' => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statLine(
                widget.strings.seenSecrets,
                '${_controller.state.discoveredSecrets.length}',
              ),
            ],
          ),
        'collections' => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statLine(
                widget.strings.codexCompletion,
                '${codex.totalDiscovered}/${codex.totalAvailable}',
              ),
              _statLine(
                widget.strings.metaProgressLabel,
                '${_controller.metaProgression.relics.length} ${widget.strings.relicArchiveTitle} · ${_controller.metaProgression.memoryFragments.length} ${widget.strings.guideMemoryLog}',
              ),
            ],
          ),
        _ => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statLine(
                widget.strings.sceneArchive,
                widget.strings.sceneArchiveProgress(
                  _controller.completedSceneBadges.length,
                  orderedEras.length,
                ),
              ),
              _statLine(
                widget.strings.eventCodex,
                widget.strings.eventArchiveProgress(
                  seenEvents.length,
                  widget.config.progression.events.length,
                ),
              ),
              _statLine(
                widget.strings.codexCompletion,
                '${codex.totalDiscovered}/${codex.totalAvailable}',
              ),
            ],
          ),
      },
    );
  }

  /// Returns a flat list of [_CodexItemData] for [section]. Used by the
  /// `SliverList.builder` in the codex sheet so items are virtualized and
  /// only built when they scroll into view.
  List<_CodexItemData> _codexSectionItems(
    String section, {
    required List<Era> orderedEras,
    required Set<String> seenEvents,
  }) {
    final codex = _controller.codexState;
    return switch (section) {
      'guide' => codex.guideMemories.reversed
          .map(
            (memory) => _CodexItemData(
              title: widget.strings.translateContent(memory.title),
              subtitle: widget.strings.formatGuideMemoryType(memory.messageType),
              body: widget.strings.translateContent(memory.content),
              icon: Icons.smart_toy_rounded,
            ),
          )
          .toList(growable: false),
      'route' => codex.routeArchive
          .map(
            (entry) => _CodexItemData(
              title: _routeArchiveTitle(entry),
              subtitle:
                  '${entry.completionPercentage.toStringAsFixed(0)}% · ${entry.roomsVisited.length}/${_controller.totalRooms}',
              body:
                  '${widget.strings.translateContent(entry.description)}\n${entry.branchesChosen.isEmpty ? widget.strings.hidden : entry.branchesChosen.map(_branchLabel).join(' / ')}',
              icon: Icons.route_rounded,
            ),
          )
          .toList(growable: false),
      'secrets' => codex.secretArchive
          .map(
            (secret) => _CodexItemData(
              title: widget.strings.translateContent(secret.title),
              subtitle: secret.discovered
                  ? widget.strings.discovered
                  : widget.strings.hidden,
              body: secret.discovered
                  ? '${widget.strings.translateContent(secret.description)}\n${widget.strings.translateContent(secret.hint)}'
                  : widget.strings.hiddenRouteHint,
              icon: Icons.visibility_rounded,
            ),
          )
          .toList(growable: false),
      'lore' => codex.sceneLore
          .map(
            (entry) => _CodexItemData(
              title: widget.strings.translateContent(entry.title),
              subtitle:
                  '${widget.strings.currentRoom}: ${_roomLabel(entry.roomId)}',
              body: widget.strings.translateContent(entry.content),
              icon: Icons.menu_book_rounded,
            ),
          )
          .toList(growable: false),
      'collections' => codex.entries
          .map(
            (entry) => _CodexItemData(
              title: widget.strings.translateContent(entry.title),
              subtitle:
                  widget.strings.formatCodexEntryType(entry.type.name),
              body: widget.strings.translateContent(entry.content),
              icon: Icons.auto_stories_rounded,
            ),
          )
          .toList(growable: false),
      _ => orderedEras.map((era) {
          final bought = _roomUpgradeCount(era.id);
          final total = _roomUpgradeTotal(era.id);
          final completed =
              _controller.completedSceneBadges.contains(era.id);
          return _CodexItemData(
            title: widget.strings.localizedEraName(era.name),
            subtitle: completed
                ? widget.strings.sceneCompleted
                : widget.strings.notYetCompleted,
            body:
                '${widget.strings.roomUpgradeProgress(bought, total)}\n${widget.strings.localizedEraDescription(era)}',
            icon: Icons.meeting_room_rounded,
            progress: total <= 0 ? 0 : (bought / total).clamp(0.0, 1.0),
          );
        }).toList(growable: false),
    };
  }

  /// Builds the visual widget for a single [_CodexItemData]. Equivalent to
  /// the old `_archiveCard` but receives a typed data object so item
  /// construction is separated from item rendering.
  Widget _buildCodexItemWidget(_CodexItemData item) {
    return _archiveCard(
      title: item.title,
      subtitle: item.subtitle,
      body: item.body,
      icon: item.icon,
      progress: item.progress,
    );
  }


  Widget _archiveCard({
    required String title,
    required String subtitle,
    required String body,
    required IconData icon,
    double? progress,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withAlpha(12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
              borderRadius: BorderRadius.circular(999),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatsSheet() async {
    final state = _controller.state;
    await _simpleSheet(
      widget.strings.stats,
      Column(
        children: [
          _statLine(widget.strings.totalTapsStat, '${state.totalTaps}'),
          _statLine(widget.strings.strongestCombo, '${state.strongestCombo}'),
          _statLine(
            widget.strings.resourcesEarned,
            state.totalCoinsEarned.toStringFormatted(),
          ),
          _statLine(
            widget.strings.generatorsBought,
            '${state.totalGeneratorsPurchased}',
          ),
          _statLine(
            widget.strings.upgradesBought,
            '${state.totalUpgradesPurchased}',
          ),
          _statLine(widget.strings.criticalClicks, '${state.totalCriticalClicks}'),
          _statLine(widget.strings.eventsClicked, '${state.totalEventsClicked}'),
          _statLine(widget.strings.rareEvents, '${state.rareEventsFound}'),
          _statLine(widget.strings.bestEventChain, '${state.bestEventChain}'),
          _statLine(
            widget.strings.playtime,
            widget.strings.durationShort(state.totalPlaySeconds.round()),
          ),
          _statLine(
            widget.strings.offlineTime,
            widget.strings.durationShort(state.totalOfflineSeconds.round()),
          ),
          _statLine(
            widget.strings.playstyle,
            widget.strings.formatPlaystyle(_controller.dominantPlaystyle),
          ),
          _statLine(widget.strings.routeSignature, state.routeSignature),
        ],
      ),
    );
  }

  Future<void> _showAchievementsSheet() async {
    await _simpleSheet(
      widget.strings.achievements,
      SizedBox(
        height: 320,
        child: ListView(
          children: widget.config.achievements.map((achievement) {
            final unlocked =
                _controller.state.unlockedAchievements.contains(achievement.id);
            return ListTile(
              leading: Text(unlocked ? achievement.icon : '•'),
              title: Text(
                widget.strings.translateContent(achievement.name),
                style: TextStyle(
                  color: unlocked ? Colors.white : Colors.white54,
                ),
              ),
              subtitle: Text(
                widget.strings.translateContent(achievement.description),
                style: const TextStyle(color: Colors.white54),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showPrestigeSheet() async {
    await _simpleSheet(
      widget.strings.prestige,
      Column(
        children: [
          _statLine(
            widget.strings.currentMultiplier,
            'x${_controller.state.prestigeMultiplier.toStringFormatted()}',
          ),
          _statLine(
            widget.strings.nextMultiplier,
            'x${_controller.nextPrestigeMultiplier.toStringFormatted()}',
          ),
          _statLine(
            widget.strings.requirement,
            PrestigeSystem.prestigeThreshold.toStringFormatted(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _controller.canPrestige
                  ? () {
                      final ok = _controller.prestige();
                      if (!ok) return;
                      Navigator.pop(context);
                      setState(() {});
                    }
                  : null,
              child: Text(_controller.canPrestige
                  ? widget.strings.prestigeAction
                  : widget.strings.earnToPrestige(
                      PrestigeSystem.prestigeThreshold.toStringFormatted(),
                    )),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChallengesSheet() async {
    final daily = _controller.dailyChallenge;
    final weekly = _controller.weeklyChallenge;
    await _simpleSheet(
      widget.strings.challenges,
      Column(
        children: [
          if (daily != null) _challengeTile(daily),
          if (weekly != null) ...[
            const SizedBox(height: 12),
            _challengeTile(weekly),
          ],
          const SizedBox(height: 12),
          _statLine(widget.strings.rerolls,
              '${_controller.state.challengeRerollsRemaining}'),
          _statLine(widget.strings.missedEventCharges,
              '${_controller.state.missedEventCharges}'),
        ],
      ),
    );
  }

  Widget _challengeTile(ChallengeState challenge) {
    final ratio = challenge.target <= 0 ? 0.0 : challenge.progress / challenge.target;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.strings.translateContent(challenge.title),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                widget.strings.challengePeriodLabel(challenge.period),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.strings.translateContent(challenge.description),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: ratio.clamp(0.0, 1.0)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${challenge.progress.toStringAsFixed(0)} / ${challenge.target.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: challenge.claimed
                    ? null
                    : challenge.completed
                        ? () {
                            final ok = _controller.claimChallengeReward(challenge.id);
                            if (!ok) return;
                            setState(() {});
                            Navigator.pop(context);
                          }
                        : () {
                            final ok = _controller.rerollChallenge(challenge.period);
                            if (!ok) return;
                            setState(() {});
                            Navigator.pop(context);
                            _showChallengesSheet();
                          },
                child: Text(
                  challenge.completed
                      ? widget.strings.claim
                      : widget.strings.reroll,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showLeaderboardSheet() async {
    var selected = LeaderboardCategory.weeklyScore;
    var snapshot = await _leaderboardService.fetchTop(category: selected);
    var status = snapshot.notice ?? '';
    final playerName = _leaderboardPlayerName();
    var profile = widget.leaderboardSessionService.profile;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121D28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> reload(LeaderboardCategory category) async {
            setModalState(() {
              selected = category;
              status = widget.strings.refreshing;
            });
            final next = await _leaderboardService.fetchTop(category: category);
            if (!mounted) return;
            setModalState(() {
              snapshot = next;
              status = next.notice ?? '';
            });
          }

          Future<void> submitCurrent() async {
            setModalState(() => status = widget.strings.submittingCurrentRun);
            final submission = _leaderboardService.buildSubmission(
              playerName: playerName,
              category: selected,
              state: _controller.state,
            );
            final ok = await _leaderboardService.submit(submission);
            if (!mounted) return;
            setModalState(() {
              status = ok
                  ? widget.strings.submissionAccepted
                  : widget.strings.submissionUnavailable;
            });
          }

          Future<void> editSession() async {
            await _showLeaderboardSessionSheet(
              initialProfile: profile,
              onSaved: (nextProfile) {
                setModalState(() {
                  profile = nextProfile;
                  status = nextProfile.hasSession
                      ? widget.strings.leaderboardSessionUpdated
                      : widget.strings.leaderboardSessionCleared;
                });
              },
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetTitle(widget.strings.leaderboard),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LeaderboardCategory.values
                        .map(
                          (category) => ChoiceChip(
                            label: Text(
                              widget.strings.leaderboardCategoryLabel(category),
                            ),
                            selected: selected == category,
                            onSelected: (_) => reload(category),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _statLine(
                  widget.strings.source,
                  widget.strings.translateStatusNotice(snapshot.sourceLabel),
                ),
                _statLine(widget.strings.online,
                    snapshot.onlineEnabled
                        ? widget.strings.configured
                        : widget.strings.fallback),
                _statLine(
                  widget.strings.submitPath,
                  _leaderboardService.canSubmitTrusted
                      ? widget.strings.trusted
                      : widget.strings.disabled,
                ),
                _statLine(widget.strings.session,
                    profile.hasSession
                        ? widget.strings.trustedSubmitReady
                        : widget.strings.missing),
                _statLine(widget.strings.playerTag, playerName),
                const SizedBox(height: 10),
                SizedBox(
                  height: 240,
                  child: ListView(
                    children: snapshot.entries
                        .map(
                          (entry) => ListTile(
                            dense: true,
                            leading: Text('#${entry.rank}',
                                style: const TextStyle(color: Colors.white70)),
                            title: Text(entry.playerName,
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(entry.meta,
                                style: const TextStyle(color: Colors.white54)),
                            trailing: Text(entry.scoreLabel,
                                style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.w700)),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.strings.translateStatusNotice(status),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => reload(selected),
                        child: Text(widget.strings.refresh),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: editSession,
                        child: Text(widget.strings.session),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _leaderboardService.canSubmitTrusted
                            ? () async {
                                await submitCurrent();
                              }
                            : null,
                        child: Text(
                          _leaderboardService.canSubmitTrusted
                              ? widget.strings.save
                              : widget.strings.submitLocked,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.strings.leaderboardSetupHint,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _simpleSheet(String title, Widget child) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121D28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetTitle(title),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _showLoadoutSheet() async {
    final initialSelection = _controller.state.chosenBranches.isEmpty
        ? <String>{}
        : {..._controller.state.chosenBranches};
    final nameController = TextEditingController(
      text: initialSelection.isEmpty
          ? ''
          : initialSelection.map(_branchLabel).join(' '),
    );
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121D28),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        var selectedBranches = initialSelection;
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              _sheetTitle(widget.strings.loadouts),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: widget.strings.presetName,
                      labelStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: Colors.white.withAlpha(24)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: Colors.cyanAccent.withAlpha(140)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.config.progression.branches.map((branch) {
                      final selected = selectedBranches.contains(branch.id);
                      return FilterChip(
                        label: Text(widget.strings.translateContent(branch.title)),
                        selected: selected,
                        onSelected: (_) {
                          setModalState(() {
                            selectedBranches = {branch.id};
                            if (nameController.text.trim().isEmpty ||
                                nameController.text.trim() ==
                                    initialSelection.map(_branchLabel).join(' ')) {
                              nameController.text = widget.strings.translateContent(branch.title);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: selectedBranches.isEmpty
                              ? null
                              : () {
                                  final ok = _controller.saveLoadoutPreset(
                                    name: nameController.text,
                                    preferredBranches: selectedBranches,
                                    favorite: false,
                                  );
                                  if (!ok) return;
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                          child: Text(widget.strings.savePreset),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _controller.state.chosenBranches.isEmpty
                              ? null
                              : () {
                                  final ok = _controller.saveLoadoutPreset(
                                    name: nameController.text.isEmpty
                                        ? _controller.state.chosenBranches
                                            .map(_branchLabel)
                                            .join(' ')
                                        : nameController.text,
                                    preferredBranches:
                                        _controller.state.chosenBranches,
                                    favorite: true,
                                  );
                                  if (!ok) return;
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                          child: Text(widget.strings.saveCurrent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.strings.savedPresets,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._controller.state.loadoutPresets.map(
                    (preset) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withAlpha(14)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  preset.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  final ok = _controller
                                      .toggleLoadoutFavorite(preset.id);
                                  if (!ok) return;
                                  setState(() {});
                                  setModalState(() {});
                                },
                                icon: Icon(
                                  preset.favorite
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: preset.favorite
                                      ? Colors.amberAccent
                                      : Colors.white54,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  final ok =
                                      _controller.deleteLoadoutPreset(preset.id);
                                  if (!ok) return;
                                  setState(() {});
                                  setModalState(() {});
                                },
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            preset.preferredBranches.map(_branchLabel).join(' / '),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    final ok =
                                        _controller.applyLoadoutPreset(preset.id);
                                    if (!ok) return;
                                    setState(() {});
                                    Navigator.pop(context);
                                  },
                                  child: Text(widget.strings.apply),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    nameController.text = preset.name;
                                    setModalState(() {
                                      selectedBranches = {
                                        ...preset.preferredBranches,
                                      };
                                    });
                                  },
                                  child: Text(widget.strings.editCopy),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    nameController.dispose();
  }

  Future<void> _showLeaderboardSessionSheet({
    required LeaderboardProfile initialProfile,
    required ValueChanged<LeaderboardProfile> onSaved,
  }) async {
    final aliasController =
        TextEditingController(text: initialProfile.playerAlias);
    final tokenController =
        TextEditingController(text: initialProfile.accessToken);
    final userIdController = TextEditingController(text: initialProfile.userId);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121D28),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetTitle(widget.strings.leaderboardSession),
              _sessionField(
                controller: aliasController,
                label: widget.strings.playerAlias,
                hint: widget.strings.playerAliasHint,
              ),
              const SizedBox(height: 10),
              _sessionField(
                controller: userIdController,
                label: widget.strings.userId,
                hint: widget.strings.userIdHint,
              ),
              const SizedBox(height: 10),
              _sessionField(
                controller: tokenController,
                label: widget.strings.accessToken,
                hint: widget.strings.accessTokenHint,
                obscure: true,
                minLines: 3,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await widget.leaderboardSessionService.clear();
                        onSaved(widget.leaderboardSessionService.profile);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      child: Text(widget.strings.clear),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final profile = LeaderboardProfile(
                          playerAlias: aliasController.text,
                          accessToken: tokenController.text,
                          userId: userIdController.text,
                        );
                        await widget.leaderboardSessionService.saveProfile(profile);
                        onSaved(widget.leaderboardSessionService.profile);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      child: Text(widget.strings.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    aliasController.dispose();
    tokenController.dispose();
    userIdController.dispose();
  }

  Widget _sheetTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _leaderboardPlayerName() {
    final alias = widget.leaderboardSessionService.profile.playerAlias.trim();
    if (alias.isNotEmpty) return alias;
    final branch = _controller.state.chosenBranches.isEmpty
        ? 'fresh'
        : _controller.state.chosenBranches.first;
    return 'RZ-${branch.toUpperCase()}-${_controller.state.prestigeCount}';
  }

  String _branchLabel(String branchId) {
    for (final branch in widget.config.progression.branches) {
      if (branch.id == branchId) return widget.strings.translateContent(branch.title);
    }
    return branchId;
  }

  String _routeArchiveTitle(RouteArchiveEntry entry) {
    if (entry.branchesChosen.isEmpty) {
      return widget.strings.translateContent(entry.title);
    }
    return entry.branchesChosen.map(_branchLabel).join(' / ');
  }

  String _roomLabel(String roomId) {
    for (final room in _controller.allRooms) {
      if (room.id == roomId) {
        return widget.strings.localizedEraName(room.name);
      }
    }
    return widget.strings.translateContent(roomId);
  }

  Widget _sessionField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscure = false,
    int minLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: obscure,
      minLines: minLines,
      maxLines: minLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white30),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withAlpha(24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.cyanAccent.withAlpha(140)),
        ),
      ),
    );
  }

  _NodePurchaseState _nodePurchaseState(TechTreeNodeData node) {
    if (node.kind == TechTreeNodeKind.secret) {
      return node.purchased
          ? _NodePurchaseState.owned
          : _NodePurchaseState.locked;
    }
    if (node.purchased && node.kind == TechTreeNodeKind.upgrade) {
      final upgrade = widget.config.upgrades[node.id];
      if (upgrade != null) {
        final level = _controller.state.upgrades[node.id]?.level ?? 0;
        if (level >= upgrade.maxLevel) return _NodePurchaseState.owned;
      }
    }
    if (node.locked) return _NodePurchaseState.locked;
    if (node.affordable) return _NodePurchaseState.canBuy;
    return _NodePurchaseState.tooExpensive;
  }

  Color _purchaseStateColor(_NodePurchaseState state) {
    return switch (state) {
      _NodePurchaseState.canBuy => Colors.cyanAccent,
      _NodePurchaseState.tooExpensive => Colors.amberAccent,
      _NodePurchaseState.locked => Colors.white38,
      _NodePurchaseState.owned => Colors.greenAccent,
    };
  }

  String _purchaseStateLabel(_NodePurchaseState state) {
    return switch (state) {
      _NodePurchaseState.canBuy => widget.strings.canPurchase,
      _NodePurchaseState.tooExpensive => widget.strings.notEnoughCoins,
      _NodePurchaseState.locked => widget.strings.locked,
      _NodePurchaseState.owned => widget.strings.alreadyOwned,
    };
  }

  Widget _statLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // Cached glass-box decorations to avoid per-build allocation.
  static const BoxDecoration _kGlassBox22 = BoxDecoration(
    color: Color(0xCC101A24),
    borderRadius: BorderRadius.all(Radius.circular(22)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0x12FFFFFF)),
    ),
    boxShadow: [
      BoxShadow(color: Color(0x44000000), blurRadius: 10, offset: Offset(0, 4)),
    ],
  );
  static const BoxDecoration _kGlassBox16 = BoxDecoration(
    color: Color(0xCC101A24),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0x12FFFFFF)),
    ),
    boxShadow: [
      BoxShadow(color: Color(0x44000000), blurRadius: 10, offset: Offset(0, 4)),
    ],
  );

  BoxDecoration _glassBox({double radius = 22}) {
    if (radius == 22) return _kGlassBox22;
    if (radius == 16) return _kGlassBox16;
    return BoxDecoration(
      color: const Color(0xCC101A24),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withAlpha(18)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x44000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1600),
        backgroundColor: color.withAlpha(220),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  int _highestEraOrder() {
    int best = 1;
    for (final gen in _controller.config.generators.values) {
      final state = _controller.state.generators[gen.id];
      if (state != null && state.level > 0) {
        final era = _controller.config.eras.firstWhere(
          (e) => e.id == gen.eraId,
          orElse: () => _controller.config.eras.first,
        );
        if (era.order > best) best = era.order;
      }
    }
    return best;
  }
}

class _AnimatedGainToast extends StatelessWidget {
  final String label;
  final bool critical;

  const _AnimatedGainToast({
    super.key,
    required this.label,
    required this.critical,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 760),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: 1 - value,
          child: Transform.translate(
            offset: Offset(-18 * value, -52 * value),
            child: child,
          ),
        );
      },
      child: Text(
        label,
        style: TextStyle(
          color: critical ? Colors.amberAccent : Colors.white,
          fontSize: critical ? 18 : 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GainToast {
  final int id;
  final String label;
  final bool critical;

  const _GainToast({
    required this.id,
    required this.label,
    required this.critical,
  });
}

const _eraThemes = <String, _EraTheme>{
  'era_1': _EraTheme(Color(0xFF4E342E), Color(0xFF3E2723), Color(0xFFBCAAA4)),
  'era_2': _EraTheme(Color(0xFF2E7D32), Color(0xFF1B5E20), Color(0xFF81C784)),
  'era_3': _EraTheme(Color(0xFFAD1457), Color(0xFF880E4F), Color(0xFFF48FB1)),
  'era_4': _EraTheme(Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF64B5F6)),
  'era_5': _EraTheme(Color(0xFF00838F), Color(0xFF006064), Color(0xFF4DD0E1)),
  'era_6': _EraTheme(Color(0xFFD84315), Color(0xFFBF360C), Color(0xFFFF8A65)),
  'era_7': _EraTheme(Color(0xFF283593), Color(0xFF1A237E), Color(0xFF7986CB)),
  'era_8': _EraTheme(Color(0xFF00695C), Color(0xFF004D40), Color(0xFF4DB6AC)),
  'era_9': _EraTheme(Color(0xFF4527A0), Color(0xFF311B92), Color(0xFF9575CD)),
  'era_10': _EraTheme(Color(0xFF37474F), Color(0xFF263238), Color(0xFF90A4AE)),
  'era_11': _EraTheme(Color(0xFF6A1B9A), Color(0xFF4A148C), Color(0xFFCE93D8)),
  'era_12': _EraTheme(Color(0xFFC2185B), Color(0xFF880E4F), Color(0xFFF06292)),
  'era_13': _EraTheme(Color(0xFF455A64), Color(0xFF37474F), Color(0xFFB0BEC5)),
  'era_14': _EraTheme(Color(0xFF5E35B1), Color(0xFF4527A0), Color(0xFFB39DDB)),
  'era_15': _EraTheme(Color(0xFF00BFA5), Color(0xFF00897B), Color(0xFF64FFDA)),
  'era_16': _EraTheme(Color(0xFF0277BD), Color(0xFF01579B), Color(0xFF4FC3F7)),
  'era_17': _EraTheme(Color(0xFF2E7D32), Color(0xFF1B5E20), Color(0xFFA5D6A7)),
  'era_18': _EraTheme(Color(0xFF7B1FA2), Color(0xFF6A1B9A), Color(0xFFE1BEE7)),
  'era_19': _EraTheme(Color(0xFFE65100), Color(0xFFBF360C), Color(0xFFFFCC80)),
  'era_20': _EraTheme(Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFFE8EAF6)),
};

class _EraTheme {
  final Color start;
  final Color end;
  final Color accent;

  const _EraTheme(this.start, this.end, this.accent);
}

List<Color> _eraGradient(String eraId) {
  final theme = _eraThemes[eraId] ??
      const _EraTheme(Color(0xFF37474F), Color(0xFF263238), Color(0xFF90A4AE));
  return [theme.start, theme.end];
}

Color _eraAccent(String eraId) =>
    (_eraThemes[eraId] ??
            const _EraTheme(
              Color(0xFF37474F),
              Color(0xFF263238),
              Color(0xFF90A4AE),
            ))
        .accent;

List<Color> _sceneGradient(RoomScene? room, String eraId) {
  if (room == null) return _eraGradient(eraId);
  final background = _sceneColor(room.themeColors.background);
  final primary = _sceneColor(room.themeColors.primary);
  final accent = _sceneColor(room.themeColors.accent);
  return [
    Color.lerp(background, primary, 0.72)!,
    Color.lerp(background, accent, 0.28)!,
  ];
}

Color _sceneAccent(RoomScene? room, String eraId) {
  if (room == null) return _eraAccent(eraId);
  return _sceneColor(room.themeColors.accent);
}

Color _sceneColor(String hex) {
  final normalized = hex.replaceAll('#', '');
  final buffer = StringBuffer();
  if (normalized.length == 6) buffer.write('ff');
  buffer.write(normalized);
  return Color(int.parse(buffer.toString(), radix: 16));
}

String _currentEra(GameController controller) {
  return controller.currentEraId;
}

enum _NodePurchaseState { canBuy, tooExpensive, locked, owned }


/// Lightweight data holder for a single codex archive card.
/// Separates data preparation from widget construction so the
/// SliverList.builder can index into a pre-built list without
/// constructing any widgets until an item scrolls into view.
class _CodexItemData {
  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
  final double? progress;

  const _CodexItemData({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
    this.progress,
  });
}
