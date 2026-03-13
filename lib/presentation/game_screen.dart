import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/controllers/game_controller.dart';
import '../application/services/app_settings_service.dart';
import '../application/services/app_strings.dart';
import '../application/services/config_service.dart';
import '../application/services/game_audio_service.dart';
import '../application/services/leaderboard_service.dart';
import '../application/services/leaderboard_session_service.dart';
import '../core/math/game_number.dart';
import '../domain/mechanics/cost_calculator.dart';
import '../domain/models/game_systems.dart';
import '../domain/models/gameplay_extensions.dart';
import '../domain/systems/prestige_system.dart';
import '../domain/systems/tap_system.dart';
import 'tech_tree/tech_tree_builder.dart';
import 'tech_tree/tech_tree_models.dart';
import 'tech_tree/tech_tree_view.dart';

class GameScreen extends StatefulWidget {
  final GameController controller;
  final ConfigService config;
  final AppSettings settings;
  final AppStrings strings;
  final GameAudioService audioService;
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
    required this.leaderboardService,
    required this.leaderboardSessionService,
    required this.onSettingsChanged,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TransformationController _camera = TransformationController();
  final List<_GainToast> _gainToasts = [];
  Timer? _tickTimer;
  String? _selectedNodeId;
  String? _hoveredNodeId;
  PurchaseMode _purchaseMode = PurchaseMode.x1;
  bool _offlineShown = false;
  Size _viewportSize = const Size(1200, 700);
  int _toastId = 0;

  GameController get _controller => widget.controller;
  LeaderboardService get _leaderboardService => widget.leaderboardService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tickTimer = Timer.periodic(
      Duration(milliseconds: widget.config.tickRateMs),
      (_) {
        setState(() {
          _controller.tick(widget.config.tickRateMs / 1000.0);
        });
        _handleFeedback();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOffline();
      _focusCurrentEra();
    });
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
    WidgetsBinding.instance.removeObserver(this);
    _tickTimer?.cancel();
    _camera.dispose();
    unawaited(_controller.saveGame());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eraId = _currentEra(_controller);
    final accent = _eraAccent(eraId);
    final gradient = _eraGradient(eraId);
    final graph = TechTreeBuilder.build(
      config: widget.config,
      controller: _controller,
      strings: widget.strings,
      purchaseMode: _purchaseMode,
      selectedNodeId: _selectedNodeId,
    );
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
              Positioned(
                top: -120,
                left: -80,
                child: _blurBlob(accent.withAlpha(80), 260),
              ),
              Positioned(
                bottom: -160,
                right: -60,
                child: _blurBlob(Colors.lightBlueAccent.withAlpha(36), 340),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    children: [
                      _buildHud(accent),
                      const SizedBox(height: 12),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            _viewportSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            final compact = constraints.maxWidth < 1180 ||
                                constraints.maxHeight < 760;
                            if (compact) {
                              return Column(
                                children: [
                                  _buildNotificationStack(compact: true),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildTreeArea(graph, accent),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: math.min(320, constraints.maxWidth * 0.34),
                                          child: _buildContextPanel(node),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildBottomDock(accent),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildNotificationStack(compact: false),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: _buildTreeArea(graph, accent),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                SizedBox(
                                  width: math.min(340, constraints.maxWidth * 0.28),
                                  child: _buildContextPanel(node),
                                ),
                                const SizedBox(width: 14),
                                SizedBox(
                                  width: 220,
                                  child: _buildSideRail(accent),
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
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _miniAction(Icons.save_rounded, () {
          unawaited(_controller.saveGame());
          _showToast(widget.strings.gameSaved, Colors.green.shade700);
        }),
        _miniAction(Icons.bar_chart_rounded, _showStatsSheet),
        _miniAction(Icons.military_tech_rounded, _showChallengesSheet),
        _miniAction(Icons.leaderboard_rounded, _showLeaderboardSheet),
        _miniAction(Icons.emoji_events_rounded, _showAchievementsSheet),
        _miniAction(Icons.auto_awesome, _showPrestigeSheet),
        _miniAction(Icons.settings_rounded, _showSettingsSheet),
      ],
    );
    final summary = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _glassBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              state.coins.toStringFormatted(),
              key: ValueKey(state.coins.toStringFormatted()),
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _glassChip(
                icon: Icons.trending_up,
                label: widget.strings.perSecond(
                  _controller.productionPerSecond.toStringFormatted(),
                ),
              ),
              _glassChip(
                icon: Icons.local_fire_department,
                label: widget.strings.combo(state.tapCombo),
              ),
              _glassChip(
                icon: Icons.psychology_alt,
                label: widget.strings.formatPlaystyle(
                  _controller.dominantPlaystyle,
                ),
              ),
              _glassChip(
                icon: Icons.meeting_room_rounded,
                label: widget.strings.roomProgress(
                  currentEraDef.order,
                  widget.config.eras.length,
                ),
              ),
              _glassChip(
                icon: Icons.rule_rounded,
                label: currentEraDef.rule,
              ),
            ],
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              summary,
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: actions),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: summary),
            const SizedBox(width: 10),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildNotificationStack({required bool compact}) {
    final cards = <Widget>[];
    if (_controller.activeEvent != null) {
      cards.add(_buildEventCard(compact: compact));
    }
    if (_controller.activeNarrativeBeat != null) {
      cards.add(_buildNarrativeCard(compact: compact));
    }
    if (_controller.lastRecommendation != null) {
      cards.add(
        _buildInfoCard(
          icon: Icons.auto_awesome,
          title: widget.strings.notifications,
          body: widget.strings.formatRecommendation(
            _controller.lastRecommendation!,
          ),
          accent: const Color(0xFF5BD2FF),
        ),
      );
    }

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 420 : 360),
        child: cards.isEmpty
            ? _buildInfoCard(
                icon: Icons.check_circle_outline,
                title: widget.strings.notifications,
                body: widget.strings.noNotifications,
                accent: Colors.white24,
                compact: true,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i != cards.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildTreeArea(TechTreeGraph graph, Color accent) {
    return Stack(
      children: [
        Positioned.fill(
          child: TechTreeView(
            graph: graph,
            selectedNodeId: _selectedNodeId,
            hoveredNodeId: _hoveredNodeId,
            transformationController: _camera,
            onNodeTap: (value) {
              unawaited(widget.audioService.playNodeSelect());
              setState(() => _selectedNodeId = value.id);
              _focusNode(value.position);
            },
            onHoverChanged: (value) {
              if (_hoveredNodeId == value) return;
              setState(() => _hoveredNodeId = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard({required bool compact}) {
    final event = _controller.activeEvent!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.crisis_alert, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${event.remainingSeconds.ceil()}s',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            event.description,
            style: const TextStyle(color: Colors.white60, height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final ok =
                        _controller.resolveActiveEvent(aggressiveChoice: false);
                    if (!ok) return;
                    unawaited(widget.audioService.playBranchUnlock());
                    setState(() {});
                  },
                  child: Text(widget.strings.safeChoice),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final ok =
                        _controller.resolveActiveEvent(aggressiveChoice: true);
                    if (!ok) return;
                    unawaited(widget.audioService.playMilestone());
                    setState(() {});
                  },
                  child: Text(
                    event.risky
                        ? widget.strings.pushChoice
                        : widget.strings.takeChoice,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNarrativeCard({required bool compact}) {
    final beat = _controller.activeNarrativeBeat!;
    return _buildInfoCard(
      icon: Icons.psychology_alt,
      title: beat.title,
      body: beat.body,
      accent: Colors.lightBlueAccent,
      trailing: TextButton(
        onPressed: () {
          _controller.dismissNarrativeBeat(beat.id);
          setState(() {});
        },
        child: Text(widget.strings.close),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String body,
    required Color accent,
    Widget? trailing,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: _glassBox(radius: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
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
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseMode(Color accent) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: _glassBox(),
      child: Wrap(
        spacing: 6,
        children: widget.config.purchaseModes.map((mode) {
          final selected = mode == _purchaseMode;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _purchaseMode = mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? accent.withAlpha(80) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                mode.label,
                style: TextStyle(
                  color: selected ? accent : Colors.white54,
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
      spacing: 8,
      runSpacing: 8,
      children: _controller.abilities.values.map((ability) {
        final icon = switch (ability.type) {
          ActiveAbilityType.overclock => Icons.bolt,
          ActiveAbilityType.focus => Icons.ads_click,
          ActiveAbilityType.surge => Icons.flash_on,
          ActiveAbilityType.sync => Icons.sync,
        };
        return Opacity(
          opacity: ability.unlocked ? 1 : 0.35,
          child: InkWell(
            onTap: ability.unlocked ? () => _activateAbility(ability.type) : null,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: _glassBox(),
              child: Column(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    widget.strings.formatAbilityLabel(ability.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSideRail(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRoomTools(accent),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: _glassBox(radius: 18),
          child: _buildAbilityBar(),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: _glassBox(radius: 18),
          child: Column(
            children: [
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
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _miniAction(Icons.memory, () {
                    _showToast(
                      _controller.lastAiLine == null
                          ? widget.strings.noNotifications
                          : widget.strings.formatAiLine(_controller.lastAiLine!),
                      accent,
                    );
                  }),
                  _miniAction(Icons.dns_rounded, () {
                    _activateAbility(ActiveAbilityType.overclock);
                  }),
                  _miniAction(Icons.smart_toy_outlined, () {
                    _showToast(
                      _controller.lastAiLine == null
                          ? widget.strings.noNotifications
                          : widget.strings.formatAiLine(_controller.lastAiLine!),
                      Colors.lightBlueAccent,
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomDock(Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _buildRoomTools(accent)),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: _glassBox(radius: 18),
            child: Row(
              children: [
                Expanded(child: _buildAbilityBar()),
                const SizedBox(width: 10),
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
          ),
        ),
      ],
    );
  }

  Widget _buildRoomTools(Color accent) {
    final currentEra = _currentEra(_controller);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _glassBox(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPurchaseMode(accent),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => _upgradeAll(currentEra),
            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
            label: Text(widget.strings.upgradeAll),
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
          node == null
              ? Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _glassBox(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.strings.selectedNode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.strings.treeFocusHint,
                        style: const TextStyle(color: Colors.white60, height: 1.4),
                      ),
                    ],
                  ),
                )
              : _buildNodeCard(node),
          const SizedBox(height: 12),
          _buildSecretHintsCard(currentEra),
        ],
      ),
    );
  }

  Widget _buildNodeCard(TechTreeNodeData node) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _glassBox(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${node.icon} ${node.title}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            node.subtitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(node.description, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 14),
          _statLine(widget.strings.cost, node.costLabel),
          _statLine(widget.strings.effect, node.effectLabel),
          _statLine(widget.strings.dependency, node.dependencyLabel),
          _statLine(widget.strings.requirement, node.requirementLabel),
          if (_controller.state.chosenBranches.isNotEmpty)
            _statLine(
              widget.strings.route,
              _controller.state.chosenBranches.join(' / '),
            ),
          if (_controller.canChooseBranch &&
              node.kind == TechTreeNodeKind.generator &&
              _controller.state.chosenBranches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.config.progression.branches
                    .map((branch) => _branchButton(branch.id, branch.title))
                    .toList(),
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: node.locked || node.kind == TechTreeNodeKind.secret
                  ? null
                  : () => _purchaseNode(node),
              child: Text(
                node.kind == TechTreeNodeKind.secret
                    ? (node.purchased
                        ? widget.strings.discovered
                        : widget.strings.hidden)
                    : node.locked
                        ? widget.strings.locked
                        : widget.strings.purchase,
              ),
            ),
          ),
          if (_controller.state.chosenBranches.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _controller.state.branchRespecTokens > 0
                        ? () {
                            final ok = _controller.respecBranch();
                            if (!ok) return;
                            setState(() {});
                          }
                        : null,
                    child: Text(
                      'Respec (${_controller.state.branchRespecTokens})',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showLoadoutSheet(),
                    child: Text(widget.strings.loadout),
                  ),
                ),
              ],
            ),
          ],
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
        width: 118,
        height: 118,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, accent.withAlpha(90)],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(120),
              blurRadius: 22,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    value: cooldownProgress,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withAlpha(20),
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
                      canTap ? Icons.touch_app : Icons.hourglass_bottom_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '+${gain.toStringFormatted()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canTap
                          ? widget.strings.ready
                          : widget.strings.secondsShort(
                              _controller.tapCooldownRemainingSeconds.ceil(),
                            ),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
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
          .map((id) => widget.config.milestoneById(id)?.title ?? id)
          .join(', ');
      _showToast(
        widget.strings.unlockedMilestonesToast(titles),
        const Color(0xFF74E6FF),
      );
      unawaited(widget.audioService.playMilestone());
      _controller.lastUnlockedMilestones = [];
    }
  }

  void _focusCurrentEra() {
    final graph = TechTreeBuilder.build(
      config: widget.config,
      controller: _controller,
      strings: widget.strings,
      purchaseMode: _purchaseMode,
      selectedNodeId: _selectedNodeId,
    );
    final current = graph.nodes.lastWhere(
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

  Widget _buildSecretHintsCard(String eraId) {
    final hints = widget.config.progression.secrets
        .where((item) => item.eraId == eraId)
        .where((item) => !_controller.state.discoveredSecrets.contains(item.id))
        .take(3)
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _glassBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.strings.secretHints,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.strings.hiddenRouteHint,
            style: const TextStyle(color: Colors.white60, height: 1.35),
          ),
          const SizedBox(height: 10),
          if (hints.isEmpty)
            Text(
              widget.strings.noSecretHints,
              style: const TextStyle(color: Colors.white54),
            )
          else
            ...hints.map(
              (secret) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _glassChip(
                  icon: Icons.visibility_outlined,
                  label: widget.strings.formatSecretHint(
                    secret,
                    branchLabel: secret.requiredBranchId == null
                        ? null
                        : widget.config.branchById(secret.requiredBranchId!)?.title ??
                            secret.requiredBranchId,
                    milestoneTitle: secret.requiredMilestoneId == null
                        ? null
                        : widget.config.milestoneById(secret.requiredMilestoneId!)?.title ??
                            secret.requiredMilestoneId,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetTitle(widget.strings.settings),
              ListTile(
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
              SwitchListTile(
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
              SwitchListTile(
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
              ListTile(
                title: Text(widget.strings.uiScale,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Slider(
                  value: widget.settings.uiScale,
                  min: 0.9,
                  max: 1.25,
                  divisions: 7,
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
              ListTile(
                title: Text(widget.strings.musicLayer,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${widget.audioService.currentMusicLayer} • ${widget.settings.musicVolume.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
              ListTile(
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
              ListTile(
                title: Text(widget.strings.colorClarity,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  widget.strings.formatColorblindMode(
                    widget.settings.colorblindMode,
                  ),
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: DropdownButton<ColorblindMode>(
                  value: widget.settings.colorblindMode,
                  dropdownColor: const Color(0xFF121D28),
                  items: ColorblindMode.values
                      .map((mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(
                                widget.strings.formatColorblindMode(mode),
                                style: const TextStyle(color: Colors.white)),
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
            ],
          ),
        ),
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
                achievement.name,
                style: TextStyle(
                  color: unlocked ? Colors.white : Colors.white54,
                ),
              ),
              subtitle: Text(
                achievement.description,
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
                  challenge.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                challenge.period.name.toUpperCase(),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(challenge.description, style: const TextStyle(color: Colors.white70)),
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
                _statLine(widget.strings.source, snapshot.sourceLabel),
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
                    status,
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
                        label: Text(branch.title),
                        selected: selected,
                        onSelected: (_) {
                          setModalState(() {
                            selectedBranches = {branch.id};
                            if (nameController.text.trim().isEmpty ||
                                nameController.text.trim() ==
                                    initialSelection.map(_branchLabel).join(' ')) {
                              nameController.text = branch.title;
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
      if (branch.id == branchId) return branch.title;
    }
    return branchId;
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

  Widget _miniAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 48,
        height: 48,
        decoration: _glassBox(),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _glassChip({required IconData icon, required String label}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _glassBox(radius: 999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _glassBox({double radius = 22}) {
    return BoxDecoration(
      color: const Color(0xCC101A24),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withAlpha(18)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x44000000),
          blurRadius: 18,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  Widget _blurBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 30)],
      ),
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

String _currentEra(GameController controller) {
  final generators = controller.config.generators.values.toList();
  String best = 'era_1';
  int bestOrder = 1;
  for (final generator in generators) {
    final state = controller.state.generators[generator.id];
    if (state != null && state.level > 0) {
      final era = controller.config.eras.firstWhere(
        (value) => value.id == generator.eraId,
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
