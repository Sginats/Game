import 'package:ai_evolution/domain/models/ui_ux_systems.dart';
import 'package:ai_evolution/application/services/room_ux_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _buildSampleConfig() {
  return {
    'roomUXProfiles': [
      {
        'roomId': 'room_01',
        'transition': {
          'roomId': 'room_01',
          'enterEffect': 'cableGrowth',
          'exitEffect': 'simpleFade',
          'enterDurationMs': 800,
          'exitDurationMs': 500,
          'titleRevealStyle': 'slide_up',
          'subtitleStyle': 'fade_in',
          'guideLineOnEnter': 'Welcome to the junk corner.',
          'skippableAfterFirst': true,
        },
        'roomLawBadgeStyle': 'rustic',
        'eventCardStyle': 'worn',
        'sideActivityEntryStyle': 'workbench',
        'landmarkAnimBehavior': 'gentle_pulse',
        'transformRevealBehavior': 'glow_expand',
        'completionCeremonyFormat': 'standard',
        'microLifeEffects': [
          {
            'id': 'room_01_dust',
            'type': 'particle',
            'description': 'Dust motes drift in weak light',
            'triggerCondition': 'always',
            'intensityMin': 0.1,
            'intensityMax': 0.5,
            'reactsToCombo': false,
            'reactsToDanger': false,
            'reactsToTrust': false,
            'reactsToProgression': true,
          },
          {
            'id': 'room_01_fan',
            'type': 'fan',
            'description': 'Old fan rattles when combo is high',
            'triggerCondition': 'combo_high',
            'intensityMin': 0.3,
            'intensityMax': 0.8,
            'reactsToCombo': true,
            'reactsToDanger': false,
            'reactsToTrust': false,
            'reactsToProgression': false,
          },
        ],
        'landmarkReactivity': {
          'landmarkId': 'lm_scrap_throne',
          'breathingStyle': 'gentle_pulse',
          'lightingShiftStyle': 'ambient',
          'scarConditions': ['reckless_play', 'overheated'],
        },
      },
      {
        'roomId': 'room_02',
        'transition': {
          'roomId': 'room_02',
          'enterEffect': 'signalDistortion',
          'exitEffect': 'dataTunnel',
          'enterDurationMs': 900,
          'exitDurationMs': 600,
          'titleRevealStyle': 'typewriter',
          'subtitleStyle': 'glitch',
          'skippableAfterFirst': false,
        },
        'roomLawBadgeStyle': 'technical',
        'eventCardStyle': 'wired',
        'microLifeEffects': [
          {
            'id': 'room_02_static',
            'type': 'staticRain',
            'description': 'Static rain falls from monitors',
            'triggerCondition': 'danger_active',
            'intensityMin': 0.2,
            'intensityMax': 0.9,
            'reactsToCombo': false,
            'reactsToDanger': true,
            'reactsToTrust': false,
            'reactsToProgression': false,
          },
        ],
      },
    ],
    'onboardingSteps': [
      {
        'id': 'onboard_tap',
        'title': 'Tap the Core',
        'description': 'Tap the central node to generate resources.',
        'triggerCondition': 'first_room_enter',
        'relatedMechanic': 'tapping',
      },
      {
        'id': 'onboard_upgrade',
        'title': 'Your First Upgrade',
        'description': 'Purchase an upgrade to boost your system.',
        'triggerCondition': 'first_upgrade',
        'relatedMechanic': 'upgrades',
      },
      {
        'id': 'onboard_event',
        'title': 'Event Alert',
        'description': 'An event has appeared — tap it before it expires.',
        'triggerCondition': 'first_event',
        'relatedMechanic': 'events',
      },
    ],
    'glossaryEntries': [
      {
        'id': 'gloss_combo',
        'term': 'Combo',
        'definition': 'A multiplier that increases with rapid taps.',
        'category': 'mechanics',
      },
      {
        'id': 'gloss_room_law',
        'term': 'Room Law',
        'definition': 'A mechanic rule unique to each room.',
        'category': 'rooms',
      },
      {
        'id': 'gloss_mastery',
        'term': 'Mastery',
        'definition': 'Advanced goals beyond normal room completion.',
        'category': 'progression',
        'relatedRoomId': null,
      },
    ],
  };
}

void main() {
  // ─── ToastNotification serialization ──────────────────────────────

  group('ToastNotification', () {
    test('roundtrip toJson/fromJson', () {
      final toast = ToastNotification(
        id: 'toast_1',
        title: 'Achievement Unlocked',
        subtitle: 'First combo bonus',
        priority: NotificationPriority.high,
        category: NotificationCategory.achievement,
        iconName: 'trophy',
        durationMs: 4000,
        createdAt: DateTime.utc(2026, 3, 15),
      );
      final json = toast.toJson();
      final restored = ToastNotification.fromJson(json);
      expect(restored.id, 'toast_1');
      expect(restored.title, 'Achievement Unlocked');
      expect(restored.subtitle, 'First combo bonus');
      expect(restored.priority, NotificationPriority.high);
      expect(restored.category, NotificationCategory.achievement);
      expect(restored.iconName, 'trophy');
      expect(restored.durationMs, 4000);
      expect(restored.dismissed, false);
    });

    test('copyWith', () {
      final toast = ToastNotification(
        id: 'toast_1',
        title: 'Test',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final dismissed = toast.copyWith(dismissed: true);
      expect(dismissed.dismissed, true);
      expect(dismissed.id, 'toast_1');
    });
  });

  // ─── RoomTransitionConfig serialization ───────────────────────────

  group('RoomTransitionConfig', () {
    test('roundtrip toJson/fromJson', () {
      const config = RoomTransitionConfig(
        roomId: 'room_01',
        enterEffect: TransitionEffect.cableGrowth,
        exitEffect: TransitionEffect.simpleFade,
        enterDurationMs: 800,
        exitDurationMs: 500,
        titleRevealStyle: 'slide_up',
        subtitleStyle: 'fade_in',
        guideLineOnEnter: 'Welcome.',
        skippableAfterFirst: true,
      );
      final json = config.toJson();
      final restored = RoomTransitionConfig.fromJson(json);
      expect(restored.roomId, 'room_01');
      expect(restored.enterEffect, TransitionEffect.cableGrowth);
      expect(restored.exitEffect, TransitionEffect.simpleFade);
      expect(restored.enterDurationMs, 800);
      expect(restored.exitDurationMs, 500);
      expect(restored.guideLineOnEnter, 'Welcome.');
      expect(restored.skippableAfterFirst, true);
    });

    test('defaults for missing JSON fields', () {
      final restored =
          RoomTransitionConfig.fromJson({'roomId': 'room_01'});
      expect(restored.enterEffect, TransitionEffect.simpleFade);
      expect(restored.exitEffect, TransitionEffect.simpleFade);
      expect(restored.enterDurationMs, 800);
      expect(restored.skippableAfterFirst, true);
    });
  });

  // ─── NodeDisplayInfo serialization ────────────────────────────────

  group('NodeDisplayInfo', () {
    test('roundtrip', () {
      const info = NodeDisplayInfo(
        nodeId: 'node_1',
        state: NodeStateLabel.purchasable,
        tooltipOverride: 'Buy this now',
        whyThisMatters: 'Boosts production by 50%',
        highlighted: true,
      );
      final json = info.toJson();
      final restored = NodeDisplayInfo.fromJson(json);
      expect(restored.nodeId, 'node_1');
      expect(restored.state, NodeStateLabel.purchasable);
      expect(restored.tooltipOverride, 'Buy this now');
      expect(restored.whyThisMatters, 'Boosts production by 50%');
      expect(restored.highlighted, true);
    });
  });

  // ─── NodeStateLabel enum ──────────────────────────────────────────

  group('NodeStateLabel', () {
    test('has expected values', () {
      expect(NodeStateLabel.values.length, 11);
      expect(NodeStateLabel.values.contains(NodeStateLabel.purchasable), true);
      expect(NodeStateLabel.values.contains(NodeStateLabel.blockedByRoomLaw),
          true);
      expect(NodeStateLabel.values.contains(NodeStateLabel.guideRecommended),
          true);
    });
  });

  // ─── RoomPreviewData serialization ────────────────────────────────

  group('RoomPreviewData', () {
    test('roundtrip', () {
      const preview = RoomPreviewData(
        roomId: 'room_01',
        name: 'Junk Corner',
        subtitle: 'Where it all begins',
        roomLawName: 'Scrap Economy',
        masteryStars: 3,
        maxMasteryStars: 7,
        completionPercent: 0.65,
        secretsFound: 2,
        totalSecrets: 3,
        hasRevisitContent: true,
        featuredBadge: 'Featured This Week',
        pinnedGoals: ['speed_clear', 'no_fail'],
      );
      final json = preview.toJson();
      final restored = RoomPreviewData.fromJson(json);
      expect(restored.roomId, 'room_01');
      expect(restored.name, 'Junk Corner');
      expect(restored.masteryStars, 3);
      expect(restored.completionPercent, 0.65);
      expect(restored.hasRevisitContent, true);
      expect(restored.pinnedGoals.length, 2);
    });
  });

  // ─── RoomMilestoneSummary serialization ───────────────────────────

  group('RoomMilestoneSummary', () {
    test('roundtrip', () {
      final summary = RoomMilestoneSummary(
        roomId: 'room_01',
        milestoneTitle: 'Stage 2 Reached',
        changes: const [
          SummaryChangeItem(
            label: 'New upgrade branch available',
            category: 'roomStatus',
          ),
          SummaryChangeItem(
            label: 'Secret clue discovered',
            category: 'secretLead',
            detail: 'Check the wiring behind the desk',
          ),
        ],
        newArchiveEntries: const ['archive_junk_lore_1'],
        masteryStarsGained: 1,
        revisitHints: const ['Room 3 has new content'],
        generatedAt: DateTime.utc(2026, 3, 15),
      );
      final json = summary.toJson();
      final restored = RoomMilestoneSummary.fromJson(json);
      expect(restored.roomId, 'room_01');
      expect(restored.milestoneTitle, 'Stage 2 Reached');
      expect(restored.changes.length, 2);
      expect(restored.changes[1].detail, 'Check the wiring behind the desk');
      expect(restored.newArchiveEntries.length, 1);
      expect(restored.masteryStarsGained, 1);
      expect(restored.revisitHints.length, 1);
    });
  });

  // ─── OnboardingStep serialization ─────────────────────────────────

  group('OnboardingStep', () {
    test('roundtrip', () {
      const step = OnboardingStep(
        id: 'onboard_tap',
        title: 'Tap the Core',
        description: 'Generate resources.',
        triggerCondition: 'first_room_enter',
        relatedMechanic: 'tapping',
      );
      final json = step.toJson();
      final restored = OnboardingStep.fromJson(json);
      expect(restored.id, 'onboard_tap');
      expect(restored.title, 'Tap the Core');
      expect(restored.completed, false);
    });

    test('copyWith', () {
      const step = OnboardingStep(
        id: 'onboard_tap',
        title: 'Tap the Core',
        description: 'Generate resources.',
        triggerCondition: 'first_room_enter',
      );
      final completed = step.copyWith(completed: true);
      expect(completed.completed, true);
      expect(completed.id, 'onboard_tap');
    });
  });

  // ─── GlossaryEntry serialization ──────────────────────────────────

  group('GlossaryEntry', () {
    test('roundtrip', () {
      const entry = GlossaryEntry(
        id: 'gloss_combo',
        term: 'Combo',
        definition: 'Rapid tap multiplier.',
        category: 'mechanics',
      );
      final json = entry.toJson();
      final restored = GlossaryEntry.fromJson(json);
      expect(restored.id, 'gloss_combo');
      expect(restored.term, 'Combo');
      expect(restored.discoveredInGame, false);
    });

    test('copyWith discoveredInGame', () {
      const entry = GlossaryEntry(
        id: 'gloss_combo',
        term: 'Combo',
        definition: 'Rapid tap multiplier.',
      );
      final discovered = entry.copyWith(discoveredInGame: true);
      expect(discovered.discoveredInGame, true);
    });
  });

  // ─── MicroLifeEffect serialization ────────────────────────────────

  group('MicroLifeEffect', () {
    test('roundtrip', () {
      const effect = MicroLifeEffect(
        id: 'room_01_dust',
        type: MicroLifeType.particle,
        description: 'Dust motes drift',
        triggerCondition: 'always',
        intensityMin: 0.1,
        intensityMax: 0.5,
        reactsToCombo: true,
      );
      final json = effect.toJson();
      final restored = MicroLifeEffect.fromJson(json);
      expect(restored.id, 'room_01_dust');
      expect(restored.type, MicroLifeType.particle);
      expect(restored.reactsToCombo, true);
      expect(restored.reactsToDanger, false);
    });
  });

  // ─── LandmarkReactivity serialization ─────────────────────────────

  group('LandmarkReactivity', () {
    test('roundtrip', () {
      const reactivity = LandmarkReactivity(
        landmarkId: 'lm_scrap_throne',
        breathingStyle: 'gentle_pulse',
        lightingShiftStyle: 'ambient',
        scarConditions: ['reckless_play'],
      );
      final json = reactivity.toJson();
      final restored = LandmarkReactivity.fromJson(json);
      expect(restored.landmarkId, 'lm_scrap_throne');
      expect(restored.scarConditions.length, 1);
    });
  });

  // ─── RoomUXProfile serialization ──────────────────────────────────

  group('RoomUXProfile', () {
    test('roundtrip', () {
      const profile = RoomUXProfile(
        roomId: 'room_01',
        transition: RoomTransitionConfig(roomId: 'room_01'),
        roomLawBadgeStyle: 'rustic',
        eventCardStyle: 'worn',
        microLifeEffects: [
          MicroLifeEffect(
            id: 'room_01_dust',
            type: MicroLifeType.particle,
            description: 'Dust motes',
          ),
        ],
        landmarkReactivity: LandmarkReactivity(landmarkId: 'lm_test'),
      );
      final json = profile.toJson();
      final restored = RoomUXProfile.fromJson(json);
      expect(restored.roomId, 'room_01');
      expect(restored.roomLawBadgeStyle, 'rustic');
      expect(restored.microLifeEffects.length, 1);
      expect(restored.landmarkReactivity?.landmarkId, 'lm_test');
    });
  });

  // ─── Enums ────────────────────────────────────────────────────────

  group('TransitionEffect enum', () {
    test('has 12 values', () {
      expect(TransitionEffect.values.length, 12);
    });
  });

  group('MicroLifeType enum', () {
    test('has 13 values', () {
      expect(MicroLifeType.values.length, 13);
    });
  });

  group('NotificationPriority enum', () {
    test('has 4 values', () {
      expect(NotificationPriority.values.length, 4);
    });
  });

  group('NotificationCategory enum', () {
    test('has 10 values', () {
      expect(NotificationCategory.values.length, 10);
    });
  });

  // ─── UIUXState serialization ──────────────────────────────────────

  group('UIUXState', () {
    test('empty defaults', () {
      const state = UIUXState();
      expect(state.onboardingProgress, isEmpty);
      expect(state.discoveredGlossary, isEmpty);
      expect(state.recentSummaries, isEmpty);
      expect(state.seenTransitions, isEmpty);
      expect(state.contrastMode, ContrastMode.standard);
      expect(state.tooltipBehavior, TooltipBehavior.onHover);
      expect(state.transitionSpeed, TransitionSpeed.full);
      expect(state.focusModeEnabled, false);
      expect(state.pinnedGoalsMinimized, false);
    });

    test('roundtrip toJson/fromJson', () {
      final state = UIUXState(
        onboardingProgress: const [
          OnboardingStep(
            id: 'onboard_tap',
            title: 'Tap',
            description: 'Tap the core.',
            triggerCondition: 'first_room_enter',
            completed: true,
          ),
        ],
        discoveredGlossary: const [
          GlossaryEntry(
            id: 'gloss_combo',
            term: 'Combo',
            definition: 'Tap multiplier.',
            discoveredInGame: true,
          ),
        ],
        recentSummaries: [
          RoomMilestoneSummary(
            roomId: 'room_01',
            milestoneTitle: 'Complete',
            generatedAt: DateTime.utc(2026, 3, 15),
          ),
        ],
        seenTransitions: const {'room_01': true},
        contrastMode: ContrastMode.highContrast,
        tooltipBehavior: TooltipBehavior.onTap,
        transitionSpeed: TransitionSpeed.fast,
        focusModeEnabled: true,
        pinnedGoalsMinimized: true,
      );
      final json = state.toJson();
      final restored = UIUXState.fromJson(json);
      expect(restored.onboardingProgress.length, 1);
      expect(restored.onboardingProgress.first.completed, true);
      expect(restored.discoveredGlossary.length, 1);
      expect(restored.discoveredGlossary.first.discoveredInGame, true);
      expect(restored.recentSummaries.length, 1);
      expect(restored.seenTransitions['room_01'], true);
      expect(restored.contrastMode, ContrastMode.highContrast);
      expect(restored.tooltipBehavior, TooltipBehavior.onTap);
      expect(restored.transitionSpeed, TransitionSpeed.fast);
      expect(restored.focusModeEnabled, true);
      expect(restored.pinnedGoalsMinimized, true);
    });

    test('fromJson with empty map', () {
      final state = UIUXState.fromJson({});
      expect(state.onboardingProgress, isEmpty);
      expect(state.contrastMode, ContrastMode.standard);
      expect(state.focusModeEnabled, false);
    });

    test('copyWith', () {
      const state = UIUXState();
      final updated = state.copyWith(focusModeEnabled: true);
      expect(updated.focusModeEnabled, true);
      expect(updated.pinnedGoalsMinimized, false);
    });
  });

  // ─── RoomUXService ────────────────────────────────────────────────

  group('RoomUXService', () {
    late RoomUXService service;

    setUp(() {
      service = RoomUXService(configJson: _buildSampleConfig());
    });

    test('loads without crashing', () {
      expect(service.allProfiles.length, 2);
    });

    test('profileForRoom returns correct profile', () {
      final profile = service.profileForRoom('room_01');
      expect(profile, isNotNull);
      expect(profile!.roomId, 'room_01');
      expect(profile.roomLawBadgeStyle, 'rustic');
    });

    test('profileForRoom returns null for unknown room', () {
      expect(service.profileForRoom('room_99'), isNull);
    });

    test('transitionForRoom returns correct config', () {
      final config = service.transitionForRoom('room_01');
      expect(config, isNotNull);
      expect(config!.enterEffect, TransitionEffect.cableGrowth);
      expect(config.enterDurationMs, 800);
    });

    test('microLifeForRoom returns effects', () {
      final effects = service.microLifeForRoom('room_01');
      expect(effects.length, 2);
      expect(effects.first.id, 'room_01_dust');
    });

    test('activeMicroLife filters by trigger', () {
      // Without combo, only "always" effects are active
      final noCombo = service.activeMicroLife('room_01');
      expect(noCombo.length, 1);
      expect(noCombo.first.triggerCondition, 'always');

      // With combo, both "always" and "combo_high" are active
      final withCombo =
          service.activeMicroLife('room_01', comboActive: true);
      expect(withCombo.length, 2);
    });

    test('activeMicroLife danger filter', () {
      final withDanger =
          service.activeMicroLife('room_02', dangerActive: true);
      expect(withDanger.length, 1);
      expect(withDanger.first.type, MicroLifeType.staticRain);
    });

    test('landmarkReactivityForRoom', () {
      final reactivity = service.landmarkReactivityForRoom('room_01');
      expect(reactivity, isNotNull);
      expect(reactivity!.landmarkId, 'lm_scrap_throne');
    });

    test('hasSeenTransition and markTransitionSeen', () {
      const state = UIUXState();
      expect(service.hasSeenTransition(state, 'room_01'), false);

      final updated = service.markTransitionSeen(state, 'room_01');
      expect(service.hasSeenTransition(updated, 'room_01'), true);
    });

    test('effectiveTransitionDurationMs', () {
      const state = UIUXState();

      // Full speed, not seen
      final full =
          service.effectiveTransitionDurationMs('room_01', state);
      expect(full, 800);

      // Mark as seen — should be halved (skippableAfterFirst=true)
      final seen = service.markTransitionSeen(state, 'room_01');
      final afterSeen =
          service.effectiveTransitionDurationMs('room_01', seen);
      expect(afterSeen, 400);

      // Reduced motion
      final reduced = service.effectiveTransitionDurationMs(
        'room_01',
        state,
        reducedMotion: true,
      );
      expect(reduced, 200);

      // Instant speed
      final instant = service.effectiveTransitionDurationMs(
        'room_01',
        state,
        transitionSpeed: 'instant',
      );
      expect(instant, 0);

      // Fast speed, not seen
      final fast = service.effectiveTransitionDurationMs(
        'room_01',
        state,
        transitionSpeed: 'fast',
      );
      expect(fast, 400); // 0.5 * 800

      // Room 02 is NOT skippable — seen should still use full duration
      final r2seen = service.markTransitionSeen(state, 'room_02');
      final r2dur =
          service.effectiveTransitionDurationMs('room_02', r2seen);
      expect(r2dur, 900); // Not skippable
    });

    test('onboarding steps', () {
      expect(service.onboardingSteps.length, 3);
    });

    test('nextOnboardingStep returns correct step', () {
      const state = UIUXState();
      final step =
          service.nextOnboardingStep(state, 'first_room_enter');
      expect(step, isNotNull);
      expect(step!.id, 'onboard_tap');
    });

    test('completeOnboardingStep marks as completed', () {
      const state = UIUXState();
      final updated =
          service.completeOnboardingStep(state, 'onboard_tap');
      expect(updated.onboardingProgress.length, 1);
      expect(updated.onboardingProgress.first.completed, true);

      // Should not find it as next anymore
      final next =
          service.nextOnboardingStep(updated, 'first_room_enter');
      expect(next, isNull);
    });

    test('glossary entries', () {
      expect(service.glossaryEntries.length, 3);
    });

    test('discoverGlossaryEntry', () {
      const state = UIUXState();
      final updated =
          service.discoverGlossaryEntry(state, 'gloss_combo');
      expect(updated.discoveredGlossary.length, 1);
      expect(updated.discoveredGlossary.first.discoveredInGame, true);

      // Idempotent
      final again =
          service.discoverGlossaryEntry(updated, 'gloss_combo');
      expect(again.discoveredGlossary.length, 1);
    });

    test('discoverGlossaryEntry unknown id', () {
      const state = UIUXState();
      final updated =
          service.discoverGlossaryEntry(state, 'gloss_nonexistent');
      expect(updated.discoveredGlossary, isEmpty);
    });

    test('glossaryForCategory', () {
      final mechanics = service.glossaryForCategory('mechanics');
      expect(mechanics.length, 1);
      expect(mechanics.first.term, 'Combo');
    });

    test('addMilestoneSummary', () {
      const state = UIUXState();
      final summary = RoomMilestoneSummary(
        roomId: 'room_01',
        milestoneTitle: 'Complete',
        generatedAt: DateTime.utc(2026, 3, 15),
      );
      final updated = service.addMilestoneSummary(state, summary);
      expect(updated.recentSummaries.length, 1);
      expect(updated.recentSummaries.first.milestoneTitle, 'Complete');
    });

    test('addMilestoneSummary caps at 10', () {
      var state = const UIUXState();
      for (var i = 0; i < 15; i++) {
        state = service.addMilestoneSummary(
          state,
          RoomMilestoneSummary(
            roomId: 'room_${i + 1}',
            milestoneTitle: 'Milestone $i',
            generatedAt: DateTime.utc(2026, 3, 15),
          ),
        );
      }
      expect(state.recentSummaries.length, 10);
      // Most recent first
      expect(state.recentSummaries.first.milestoneTitle, 'Milestone 14');
    });

    test('buildRoomPreview', () {
      final preview = service.buildRoomPreview(
        roomId: 'room_01',
        name: 'Junk Corner',
        subtitle: 'Where it all begins',
        masteryStars: 3,
        secretsFound: 2,
      );
      expect(preview.roomId, 'room_01');
      expect(preview.masteryStars, 3);
      expect(preview.secretsFound, 2);
    });

    test('toggleFocusMode', () {
      const state = UIUXState();
      final toggled = service.toggleFocusMode(state);
      expect(toggled.focusModeEnabled, true);
      final toggledBack = service.toggleFocusMode(toggled);
      expect(toggledBack.focusModeEnabled, false);
    });

    test('togglePinnedGoals', () {
      const state = UIUXState();
      final toggled = service.togglePinnedGoals(state);
      expect(toggled.pinnedGoalsMinimized, true);
    });

    test('classifyNodeState', () {
      expect(
        service.classifyNodeState(
          canAfford: true,
          dependenciesMet: true,
          owned: false,
          maxed: false,
        ),
        NodeStateLabel.purchasable,
      );
      expect(
        service.classifyNodeState(
          canAfford: true,
          dependenciesMet: true,
          owned: true,
          maxed: false,
        ),
        NodeStateLabel.owned,
      );
      expect(
        service.classifyNodeState(
          canAfford: true,
          dependenciesMet: true,
          owned: false,
          maxed: true,
        ),
        NodeStateLabel.maxLevel,
      );
      expect(
        service.classifyNodeState(
          canAfford: false,
          dependenciesMet: true,
          owned: false,
          maxed: false,
        ),
        NodeStateLabel.blockedByResource,
      );
      expect(
        service.classifyNodeState(
          canAfford: true,
          dependenciesMet: false,
          owned: false,
          maxed: false,
        ),
        NodeStateLabel.blockedByDependency,
      );
      expect(
        service.classifyNodeState(
          canAfford: true,
          dependenciesMet: true,
          owned: false,
          maxed: false,
          blockedByLaw: true,
        ),
        NodeStateLabel.blockedByRoomLaw,
      );
      expect(
        service.classifyNodeState(
          canAfford: true,
          dependenciesMet: true,
          owned: false,
          maxed: false,
          guideRecommended: true,
        ),
        NodeStateLabel.guideRecommended,
      );
    });

    test('handles empty config', () {
      final empty = RoomUXService(configJson: {});
      expect(empty.allProfiles, isEmpty);
      expect(empty.onboardingSteps, isEmpty);
      expect(empty.glossaryEntries, isEmpty);
    });

    test('handles malformed entries gracefully', () {
      final bad = RoomUXService(configJson: {
        'roomUXProfiles': [
          {'no_room_id': true},
          {'roomId': 'room_01'},
        ],
        'onboardingSteps': [
          {'no_id': true},
          {'id': 'step_1', 'title': 'T', 'description': 'D', 'triggerCondition': 'tc'},
        ],
        'glossaryEntries': [
          {'no_id': true},
          {'id': 'g1', 'term': 'T', 'definition': 'D'},
        ],
      });
      expect(bad.allProfiles.length, 1);
      expect(bad.onboardingSteps.length, 1);
      expect(bad.glossaryEntries.length, 1);
    });
  });
}
