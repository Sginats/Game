import '../../domain/models/era.dart';
import '../../domain/models/generator.dart';
import '../../domain/models/upgrade.dart';
import 'room_content_generator.dart';

/// Manages lazy loading of era-specific content.
/// Instead of generating all 2000+ upgrades at startup, generates content
/// per-era on demand and caches the results.
class EraContentManager {
  final RoomContentGenerator _generator;
  final List<Era> _eras;
  final List<GeneratorDefinition> _baseGenerators;
  final List<UpgradeDefinition> _baseUpgrades;

  final Map<String, GeneratedRoomContent> _cache = {};
  final Map<String, GeneratorDefinition> _generatorCache = {};
  final Map<String, UpgradeDefinition> _upgradeCache = {};

  /// Track which eras have been loaded into the main maps.
  final Set<String> _loadedEras = {};

  EraContentManager({
    required RoomContentGenerator generator,
    required List<Era> eras,
    required List<GeneratorDefinition> baseGenerators,
    required List<UpgradeDefinition> baseUpgrades,
  })  : _generator = generator,
        _eras = eras,
        _baseGenerators = baseGenerators,
        _baseUpgrades = baseUpgrades {
    // Index base content by ID
    for (final gen in _baseGenerators) {
      _generatorCache[gen.id] = gen;
    }
    for (final upg in _baseUpgrades) {
      _upgradeCache[upg.id] = upg;
    }
  }

  /// Get all currently loaded generators (base + generated for loaded eras).
  Map<String, GeneratorDefinition> get generators =>
      Map.unmodifiable(_generatorCache);

  /// Get all currently loaded upgrades (base + generated for loaded eras).
  Map<String, UpgradeDefinition> get upgrades =>
      Map.unmodifiable(_upgradeCache);

  /// Ensure content for a specific era is loaded and cached.
  void ensureEraLoaded(String eraId) {
    if (_loadedEras.contains(eraId)) return;

    final era = _eras.firstWhere(
      (e) => e.id == eraId,
      orElse: () => _eras.first,
    );

    if (!_cache.containsKey(eraId)) {
      _cache[eraId] = _generator.buildForEra(
        era: era,
        baseGenerators: _baseGenerators,
      );
    }

    final content = _cache[eraId]!;
    for (final gen in content.generators) {
      _generatorCache.putIfAbsent(gen.id, () => gen);
    }
    for (final upg in content.upgrades) {
      _upgradeCache.putIfAbsent(upg.id, () => upg);
    }
    _loadedEras.add(eraId);
  }

  /// Load content for the current era and its neighbors.
  /// This ensures smooth transitions without loading everything.
  void ensureErasAroundLoaded(Set<String> unlockedEras) {
    for (final eraId in unlockedEras) {
      ensureEraLoaded(eraId);
    }

    // Also preload the next era after any unlocked one
    for (final eraId in unlockedEras) {
      final era = _eras.firstWhere(
        (e) => e.id == eraId,
        orElse: () => _eras.first,
      );
      final nextOrder = era.order + 1;
      if (nextOrder <= _eras.length) {
        final nextEra = _eras.firstWhere(
          (e) => e.order == nextOrder,
          orElse: () => _eras.first,
        );
        ensureEraLoaded(nextEra.id);
      }
    }
  }

  /// Load all eras at once (used for save/load compatibility).
  void loadAllEras() {
    for (final era in _eras) {
      ensureEraLoaded(era.id);
    }
  }

  bool isEraLoaded(String eraId) => _loadedEras.contains(eraId);
}
