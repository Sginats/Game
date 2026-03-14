import 'package:ai_evolution/domain/models/companion.dart';

/// Service that loads, manages, and queries companion definitions and state.
/// Pure Dart — no Flutter imports.
///
/// Companion definitions are parsed eagerly from a JSON list via
/// [loadDefinitions] and cached in an internal map for O(1) lookups.
/// Query helpers filter the cached definitions by room affinity, rarity,
/// type, and collection group.  Runtime helpers operate on [CompanionState]
/// and [CompanionSystemState] to answer gameplay questions such as whether
/// a companion can evolve or what the total automation rate is.
class CompanionService {
  /// Parsed [CompanionDefinition] cache keyed by definition id.
  final Map<String, CompanionDefinition> _definitions = {};

  /// Whether [loadDefinitions] has been called successfully.
  bool _initialized = false;

  /// Creates the service.
  ///
  /// Optionally accepts [jsonList] to load definitions immediately.
  /// If omitted, call [loadDefinitions] before accessing data.
  CompanionService({List<Map<String, dynamic>>? jsonList}) {
    if (jsonList != null) {
      loadDefinitions(jsonList);
    }
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Populate the service with companion definitions parsed from JSON.
  ///
  /// Each map is expected to contain at least an `id` key.  Entries missing
  /// a valid id are silently skipped.
  void loadDefinitions(List<Map<String, dynamic>> jsonList) {
    _definitions.clear();

    for (final json in jsonList) {
      final id = json['id'];
      if (id is! String) continue;

      final definition = CompanionDefinition.fromJson(json);
      _definitions[definition.id] = definition;
    }

    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Definition accessors
  // ---------------------------------------------------------------------------

  /// Returns the [CompanionDefinition] with the given [id], or `null` if
  /// not found.
  CompanionDefinition? getDefinition(String id) {
    if (!_initialized) return null;
    return _definitions[id];
  }

  /// Returns all definitions whose [CompanionDefinition.sceneAffinity]
  /// matches [roomId].
  List<CompanionDefinition> getDefinitionsForRoom(String roomId) {
    if (!_initialized) return const [];
    return _definitions.values
        .where((d) => d.sceneAffinity == roomId)
        .toList();
  }

  /// Returns all definitions that match the given [rarity].
  List<CompanionDefinition> getDefinitionsByRarity(CompanionRarity rarity) {
    if (!_initialized) return const [];
    return _definitions.values
        .where((d) => d.rarity == rarity)
        .toList();
  }

  /// Returns all definitions that match the given [type].
  List<CompanionDefinition> getDefinitionsByType(CompanionType type) {
    if (!_initialized) return const [];
    return _definitions.values
        .where((d) => d.type == type)
        .toList();
  }

  /// Returns all definitions whose [CompanionDefinition.collectionGroup]
  /// matches [group].
  List<CompanionDefinition> getCollectionGroup(String group) {
    if (!_initialized) return const [];
    return _definitions.values
        .where((d) => d.collectionGroup == group)
        .toList();
  }

  /// All loaded definitions in insertion order.
  List<CompanionDefinition> get allDefinitions {
    if (!_initialized) return const [];
    return _definitions.values.toList();
  }

  /// Total number of definitions registered in the service.
  int get totalDefinitions => _definitions.length;

  // ---------------------------------------------------------------------------
  // Runtime helpers
  // ---------------------------------------------------------------------------

  /// Whether the given [bonus] is fulfilled by the [owned] companion states.
  ///
  /// A bonus is fulfilled when every id in
  /// [CompanionCollectionBonus.requiredCompanionIds] has a matching
  /// [CompanionState] in [owned] that is acquired.
  bool checkCollectionBonus(
    CompanionCollectionBonus bonus,
    List<CompanionState> owned,
  ) {
    final ownedIds = <String>{
      for (final c in owned)
        if (c.acquired) c.definitionId,
    };
    return bonus.requiredCompanionIds.every(ownedIds.contains);
  }

  /// Whether the companion represented by [state] can evolve further.
  ///
  /// Looks up the matching [CompanionDefinition] to compare the current
  /// [CompanionState.evolutionStage] against the definition's
  /// [CompanionDefinition.maxEvolutionStage].  Returns `false` when the
  /// definition is missing or the companion is already at max stage.
  bool canEvolve(CompanionState state) {
    final definition = _definitions[state.definitionId];
    if (definition == null) return false;
    return state.evolutionStage < definition.maxEvolutionStage;
  }

  /// Returns the list of [CompanionState]s that are currently equipped
  /// within the given [systemState].
  List<CompanionState> getEquippedCompanions(
    CompanionSystemState systemState,
  ) {
    return systemState.ownedCompanions
        .where((c) => c.equipped)
        .toList();
  }

  /// Computes the total automation rate contributed by all equipped
  /// companions in [systemState].
  ///
  /// For each equipped companion the matching definition's
  /// [CompanionDefinition.automationRate] is looked up and accumulated.
  /// Companions whose definition is missing are silently skipped.
  double totalAutomationRate(CompanionSystemState systemState) {
    var total = 0.0;
    for (final companion in systemState.ownedCompanions) {
      if (!companion.equipped) continue;
      final definition = _definitions[companion.definitionId];
      if (definition == null) continue;
      total += definition.automationRate;
    }
    return total;
  }
}
