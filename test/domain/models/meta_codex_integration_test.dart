import 'package:ai_evolution/domain/models/codex.dart';
import 'package:ai_evolution/domain/models/game_state.dart';
import 'package:ai_evolution/domain/models/meta_progression.dart';
import 'package:ai_evolution/domain/models/room_scene.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MetaProgressionState serializes and deserializes', () {
    const state = MetaProgressionState(
      relics: [
        Relic(
          id: 'relic_1',
          name: 'Ancient Circuit',
          description: 'A relic from the first room.',
          rarity: RelicRarity.rare,
          effects: [
            RelicEffect(
              effectType: 'multiplier',
              targetSystem: 'production',
              magnitude: 1.5,
              description: 'Boosts production by 50%.',
            ),
          ],
          acquired: true,
          sourceDescription: 'Room 1 completion',
        ),
      ],
      memoryFragments: [
        MemoryFragment(
          id: 'mem_1',
          title: 'First Boot',
          content: 'The system remembers waking up.',
          sourceRoomId: 'room_01',
          sourceType: 'milestone',
          acquired: true,
        ),
      ],
      totalPrestigeTokens: 5,
      lifetimePrestigeTokens: 12,
      roomsCompleted: {'room_01', 'room_02'},
      secretsArchived: {'room_01_secret_1'},
      challengesCleared: 3,
      guideMilestones: {'intro_complete'},
    );

    final json = state.toJson();
    final restored = MetaProgressionState.fromJson(json);

    expect(restored.relics.length, 1);
    expect(restored.relics.first.name, 'Ancient Circuit');
    expect(restored.relics.first.acquired, isTrue);
    expect(restored.relics.first.effects.first.magnitude, 1.5);
    expect(restored.memoryFragments.length, 1);
    expect(restored.totalPrestigeTokens, 5);
    expect(restored.lifetimePrestigeTokens, 12);
    expect(restored.roomsCompleted, contains('room_01'));
    expect(restored.roomsCompleted, contains('room_02'));
    expect(restored.secretsArchived, contains('room_01_secret_1'));
    expect(restored.challengesCleared, 3);
    expect(restored.guideMilestones, contains('intro_complete'));
  });

  test('MetaProgressionState defaults are empty', () {
    const state = MetaProgressionState();
    expect(state.relics, isEmpty);
    expect(state.memoryFragments, isEmpty);
    expect(state.totalPrestigeTokens, 0);
    expect(state.roomsCompleted, isEmpty);
  });

  test('MetaProgressionState copyWith works', () {
    const state = MetaProgressionState(totalPrestigeTokens: 5);
    final updated = state.copyWith(totalPrestigeTokens: 10);
    expect(updated.totalPrestigeTokens, 10);
    expect(state.totalPrestigeTokens, 5);
  });

  test('CodexState serializes and deserializes', () {
    final state = CodexState(
      entries: [
        CodexEntry(
          id: 'entry_1',
          title: 'First Entry',
          content: 'You discovered something.',
          type: CodexEntryType.sceneLore,
          category: 'lore',
          roomId: 'room_01',
          discovered: true,
          discoveredAt: DateTime(2026, 1, 1),
          icon: '📖',
          rarity: 'common',
        ),
      ],
      guideMemories: [
        const GuideMemoryLog(
          id: 'guide_1',
          roomId: 'room_01',
          title: 'First Hello',
          content: 'The guide said hello.',
          guideAffinity: 2.0,
          messageType: 'greeting',
        ),
      ],
      routeArchive: [
        const RouteArchiveEntry(
          id: 'route_1',
          routeId: 'main_route',
          title: 'Main Path',
          description: 'The standard route.',
          roomsVisited: ['room_01', 'room_02'],
          branchesChosen: ['tap'],
          completionPercentage: 10.0,
        ),
      ],
      secretArchive: [
        const SecretArchiveEntry(
          id: 'secret_1',
          roomId: 'room_01',
          title: 'Hidden Cache',
          description: 'A secret stash.',
          discovered: true,
        ),
      ],
      sceneLore: [
        const SceneLoreEntry(
          id: 'lore_1',
          roomId: 'room_01',
          title: 'Junk Corner Origins',
          content: 'This room was once a storage closet.',
          discovered: true,
        ),
      ],
    );

    final json = state.toJson();
    final restored = CodexState.fromJson(json);

    expect(restored.entries.length, 1);
    expect(restored.entries.first.title, 'First Entry');
    expect(restored.entries.first.discovered, isTrue);
    expect(restored.guideMemories.length, 1);
    expect(restored.routeArchive.length, 1);
    expect(restored.secretArchive.length, 1);
    expect(restored.secretArchive.first.discovered, isTrue);
    expect(restored.sceneLore.length, 1);
  });

  test('CodexState computed properties work', () {
    const state = CodexState(
      entries: [
        CodexEntry(
          id: 'e1',
          title: 'E1',
          content: 'C1',
          type: CodexEntryType.glossary,
          discovered: true,
        ),
        CodexEntry(
          id: 'e2',
          title: 'E2',
          content: 'C2',
          type: CodexEntryType.glossary,
          discovered: false,
        ),
      ],
      secretArchive: [
        SecretArchiveEntry(
          id: 's1',
          roomId: 'room_01',
          title: 'S1',
          description: 'D1',
          discovered: true,
        ),
      ],
      sceneLore: [
        SceneLoreEntry(
          id: 'l1',
          roomId: 'room_01',
          title: 'L1',
          content: 'C1',
          discovered: false,
        ),
      ],
    );

    expect(state.totalDiscovered, 2);
    expect(state.totalAvailable, 4);
    expect(state.completionPercentage, closeTo(50.0, 0.1));
  });

  test('GameState includes metaProgression and codex in serialization', () {
    final state = GameState.initial().copyWith(
      metaProgression: const MetaProgressionState(
        totalPrestigeTokens: 7,
        roomsCompleted: {'room_01'},
      ),
      codex: const CodexState(
        sceneLore: [
          SceneLoreEntry(
            id: 'lore_1',
            roomId: 'room_01',
            title: 'Test Lore',
            content: 'Content',
            discovered: true,
          ),
        ],
      ),
      currentRoomId: 'room_03',
      roomStates: {
        'room_01': const RoomSceneState(
          roomId: 'room_01',
          completed: true,
          upgradesPurchased: 50,
        ),
      },
    );

    final json = state.toJson();
    final restored = GameState.fromJson(json);

    expect(restored.metaProgression.totalPrestigeTokens, 7);
    expect(restored.metaProgression.roomsCompleted, contains('room_01'));
    expect(restored.codex.sceneLore.length, 1);
    expect(restored.codex.sceneLore.first.title, 'Test Lore');
    expect(restored.currentRoomId, 'room_03');
    expect(restored.roomStates.containsKey('room_01'), isTrue);
    expect(restored.roomStates['room_01']!.completed, isTrue);
    expect(restored.roomStates['room_01']!.upgradesPurchased, 50);
  });

  test('GameState defaults include empty metaProgression and codex', () {
    final state = GameState.initial();
    expect(state.metaProgression.relics, isEmpty);
    expect(state.metaProgression.totalPrestigeTokens, 0);
    expect(state.codex.entries, isEmpty);
    expect(state.currentRoomId, 'room_01');
    expect(state.roomStates, isEmpty);
  });

  test('GameState backward compatibility with missing fields', () {
    final json = GameState.initial().toJson();
    json.remove('metaProgression');
    json.remove('codex');
    json.remove('currentRoomId');
    json.remove('roomStates');

    final restored = GameState.fromJson(json);
    expect(restored.metaProgression.totalPrestigeTokens, 0);
    expect(restored.codex.entries, isEmpty);
    expect(restored.currentRoomId, 'room_01');
    expect(restored.roomStates, isEmpty);
  });
}
