import 'package:ai_evolution/domain/models/side_activity.dart';

/// Service that loads, manages, and queries side-activity definitions and
/// player progress.  Pure Dart — no Flutter imports.
///
/// Definitions are parsed eagerly from a JSON list via [loadDefinitions]
/// and cached in an internal map for O(1) lookups.  Runtime helpers
/// operate on [SideActivityState] to answer gameplay questions such as
/// whether an activity is unlocked or can be repeated.
class SideActivityService {
  /// Parsed [SideActivityDefinition] cache keyed by definition id.
  final Map<String, SideActivityDefinition> _definitions = {};

  /// Whether [loadDefinitions] has been called successfully.
  bool _initialized = false;

  /// Creates the service.
  ///
  /// Optionally accepts [jsonList] to load definitions immediately.
  /// If omitted, call [loadDefinitions] before accessing data.
  SideActivityService({List<Map<String, dynamic>>? jsonList}) {
    if (jsonList != null) {
      loadDefinitions(jsonList);
    }
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Populate the service with side-activity definitions parsed from JSON.
  ///
  /// Each map is expected to contain at least an `id` key.  Entries missing
  /// a valid id are silently skipped.
  void loadDefinitions(List<Map<String, dynamic>> jsonList) {
    _definitions.clear();

    for (final json in jsonList) {
      final id = json['id'];
      if (id is! String) continue;

      final definition = SideActivityDefinition.fromJson(json);
      _definitions[definition.id] = definition;
    }

    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Definition accessors
  // ---------------------------------------------------------------------------

  /// Returns the [SideActivityDefinition] with the given [id], or `null` if
  /// not found.
  SideActivityDefinition? getDefinition(String id) {
    if (!_initialized) return null;
    return _definitions[id];
  }

  /// Returns all definitions whose [SideActivityDefinition.roomId] matches [roomId].
  List<SideActivityDefinition> getDefinitionsForRoom(String roomId) {
    if (!_initialized) return const [];
    return _definitions.values
        .where((d) => d.roomId == roomId)
        .toList();
  }

  /// All loaded definitions in insertion order.
  List<SideActivityDefinition> get allDefinitions {
    if (!_initialized) return const [];
    return _definitions.values.toList();
  }

  /// Total number of definitions registered in the service.
  int get totalDefinitions => _definitions.length;

  // ---------------------------------------------------------------------------
  // Runtime helpers
  // ---------------------------------------------------------------------------

  /// Returns the [SideActivityProgress] for [activityId] from [state],
  /// or `null` when the player has no recorded progress.
  SideActivityProgress? getProgress(
    SideActivityState state,
    String activityId,
  ) {
    return state.progresses[activityId];
  }

  /// Whether [activityId] has been unlocked by the player in [state].
  bool isUnlocked(SideActivityState state, String activityId) {
    final progress = state.progresses[activityId];
    if (progress == null) return false;
    return progress.unlocked;
  }

  /// Whether [def] can be repeated on a daily cadence given [progress].
  /// Returns `true` when repeatable daily and dailyCompletions < 1.
  /// A `null` [progress] means never attempted, so repeat is allowed.
  bool canRepeatDaily(
    SideActivityDefinition def,
    SideActivityProgress? progress,
  ) {
    if (!def.repeatableDaily) return false;
    if (progress == null) return true;
    return progress.dailyCompletions < 1;
  }

  /// Whether [def] can be repeated on a weekly cadence given [progress].
  /// Returns `true` when repeatable weekly and weeklyCompletions < 1.
  /// A `null` [progress] means never attempted, so repeat is allowed.
  bool canRepeatWeekly(
    SideActivityDefinition def,
    SideActivityProgress? progress,
  ) {
    if (!def.repeatableWeekly) return false;
    if (progress == null) return true;
    return progress.weeklyCompletions < 1;
  }
}
