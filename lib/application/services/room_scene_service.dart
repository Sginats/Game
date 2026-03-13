import 'package:ai_evolution/domain/models/room_scene.dart';
import 'package:ai_evolution/domain/models/scene_event.dart';

/// Service that loads, manages, and provides room data for the game.
/// Pure Dart — no Flutter imports.
///
/// Rooms are lazily parsed from raw JSON maps on first access and cached
/// for subsequent lookups, keeping startup work minimal even when the
/// full 20-room dataset is provided.
class RoomSceneService {
  /// Raw JSON maps keyed by room id, supplied at construction or via
  /// [initialize].  Entries are consumed and removed once parsed.
  final Map<String, Map<String, dynamic>> _rawRoomJsonById = {};

  /// Raw event-pool JSON maps keyed by room id.
  final Map<String, Map<String, dynamic>> _rawEventPoolJsonById = {};

  /// Parsed [RoomScene] cache keyed by room id.
  final Map<String, RoomScene> _roomCache = {};

  /// Parsed [SceneEventPool] cache keyed by room id.
  final Map<String, SceneEventPool> _eventPoolCache = {};

  /// Ordered list of room ids as they appear in config (by `order` field).
  /// Built once during [initialize] so we never need to re-sort.
  List<String> _orderedRoomIds = [];

  /// Whether [initialize] has been called.
  bool _initialized = false;

  /// Creates the service.
  ///
  /// Optionally accepts [roomJsonList] to initialize immediately.
  /// If omitted, call [initialize] before accessing data.
  RoomSceneService({List<Map<String, dynamic>>? roomJsonList}) {
    if (roomJsonList != null) {
      initialize(roomJsonList);
    }
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Populate the service with raw room JSON maps parsed from config files.
  ///
  /// Each map is expected to contain at least `id` and `order` keys so
  /// rooms can be indexed and sorted.  An optional `eventPool` key holds
  /// the [SceneEventPool] data for that room.
  void initialize(List<Map<String, dynamic>> roomJsonList) {
    _rawRoomJsonById.clear();
    _rawEventPoolJsonById.clear();
    _roomCache.clear();
    _eventPoolCache.clear();

    // Index raw JSON by id and extract event pools.
    // Entries missing required keys (id, order) are silently skipped.
    for (final json in roomJsonList) {
      final id = json['id'];
      final order = json['order'];
      if (id is! String || order is! int) continue;

      _rawRoomJsonById[id] = json;

      final eventPool = json['eventPool'];
      if (eventPool is Map<String, dynamic>) {
        _rawEventPoolJsonById[id] = eventPool;
      }
    }

    // Build a lightweight order index without fully parsing each room.
    final orderEntries = <_OrderEntry>[];
    for (final entry in _rawRoomJsonById.entries) {
      orderEntries.add(
        _OrderEntry(
          id: entry.key,
          order: entry.value['order'] as int,
        ),
      );
    }
    orderEntries.sort((a, b) => a.order.compareTo(b.order));
    _orderedRoomIds = orderEntries.map((e) => e.id).toList();

    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Lazy parsing helpers
  // ---------------------------------------------------------------------------

  /// Parse and cache a [RoomScene] from raw JSON on first access.
  RoomScene? _ensureRoom(String id) {
    if (_roomCache.containsKey(id)) return _roomCache[id];

    final json = _rawRoomJsonById[id];
    if (json == null) return null;

    final room = RoomScene.fromJson(json);
    _roomCache[id] = room;
    return room;
  }

  /// Parse and cache a [SceneEventPool] from raw JSON on first access.
  SceneEventPool? _ensureEventPool(String roomId) {
    if (_eventPoolCache.containsKey(roomId)) return _eventPoolCache[roomId];

    final json = _rawEventPoolJsonById[roomId];
    if (json == null) return null;

    final pool = SceneEventPool.fromJson(json);
    _eventPoolCache[roomId] = pool;
    return pool;
  }

  // ---------------------------------------------------------------------------
  // Public accessors
  // ---------------------------------------------------------------------------

  /// Returns the [RoomScene] with the given [id], or `null` if not found.
  RoomScene? getRoomById(String id) {
    if (!_initialized) return null;
    return _ensureRoom(id);
  }

  /// Returns the [RoomScene] whose `order` equals [order], or `null`.
  RoomScene? getRoomByOrder(int order) {
    if (!_initialized) return null;
    for (final id in _orderedRoomIds) {
      // Check already-parsed rooms first (cheapest).
      final cached = _roomCache[id];
      if (cached != null) {
        if (cached.order == order) return cached;
        continue;
      }
      // Peek at raw JSON to avoid parsing every room.
      final json = _rawRoomJsonById[id];
      if (json != null && json['order'] == order) {
        return _ensureRoom(id);
      }
    }
    return null;
  }

  /// All rooms sorted by their `order` field.
  ///
  /// Forces parsing of every room on first call; the results are cached.
  List<RoomScene> get allRooms {
    if (!_initialized) return const [];
    return _orderedRoomIds
        .map((id) => _ensureRoom(id))
        .whereType<RoomScene>()
        .toList();
  }

  /// Returns the [SceneEventPool] for the room with the given [roomId].
  SceneEventPool? getEventPool(String roomId) {
    if (!_initialized) return null;
    return _ensureEventPool(roomId);
  }

  /// Returns the next room in order after the room with [currentRoomId],
  /// or `null` if the current room is the last one (or not found).
  RoomScene? getNextRoom(String currentRoomId) {
    if (!_initialized) return null;
    final index = _orderedRoomIds.indexOf(currentRoomId);
    if (index < 0 || index >= _orderedRoomIds.length - 1) return null;
    return _ensureRoom(_orderedRoomIds[index + 1]);
  }

  /// Whether the room identified by [roomId] is unlocked given the
  /// set of [completedRooms].
  ///
  /// A room is considered unlocked when:
  /// - it has no [RoomScene.unlockRequirement], **or**
  /// - its unlock requirement (a room id) is present in [completedRooms].
  bool isRoomUnlocked(String roomId, Set<String> completedRooms) {
    if (!_initialized) return false;
    final room = _ensureRoom(roomId);
    if (room == null) return false;
    if (room.unlockRequirement == null ||
        room.unlockRequirement!.isEmpty) {
      return true;
    }
    return completedRooms.contains(room.unlockRequirement);
  }

  /// Total number of rooms registered in the service.
  int get totalRooms => _orderedRoomIds.length;
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Lightweight pair used to sort room ids by order without parsing full
/// [RoomScene] objects.
class _OrderEntry {
  final String id;
  final int order;
  const _OrderEntry({required this.id, required this.order});
}
