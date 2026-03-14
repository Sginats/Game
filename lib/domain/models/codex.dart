/// Types of codex entries in the collection system.
enum CodexEntryType {
  guideMemo,
  routeArchive,
  secretArchive,
  sceneLore,
  eventArchive,
  relicArchive,
  challengeArchive,
  transformationArchive,
  glossary,
  upgradeFamily,
  companionArchive,
  sideActivityArchive,
  machineMoodArchive,
  landmarkArchive,
  weirdPhenomenaArchive,
  roomLawArchive,
}

/// A single entry in the player's codex/collection.
class CodexEntry {
  final String id;
  final String title;
  final String content;
  final CodexEntryType type;
  final String category;
  final String? roomId;
  final bool discovered;
  final DateTime? discoveredAt;
  final String icon;
  final String rarity;

  const CodexEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.category = '',
    this.roomId,
    this.discovered = false,
    this.discoveredAt,
    this.icon = '📖',
    this.rarity = 'common',
  });

  factory CodexEntry.fromJson(Map<String, dynamic> json) {
    return CodexEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: CodexEntryType.values.firstWhere(
        (t) => t.name == json['type'] as String,
      ),
      category: json['category'] as String? ?? '',
      roomId: json['roomId'] as String?,
      discovered: json['discovered'] as bool? ?? false,
      discoveredAt: json['discoveredAt'] != null
          ? DateTime.parse(json['discoveredAt'] as String)
          : null,
      icon: json['icon'] as String? ?? '📖',
      rarity: json['rarity'] as String? ?? 'common',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'type': type.name,
        'category': category,
        'roomId': roomId,
        'discovered': discovered,
        'discoveredAt': discoveredAt?.toIso8601String(),
        'icon': icon,
        'rarity': rarity,
      };
}

/// A memory log entry from the robot guide.
class GuideMemoryLog {
  final String id;
  final String roomId;
  final String title;
  final String content;
  final DateTime? timestamp;
  final double guideAffinity;
  final String messageType;

  const GuideMemoryLog({
    required this.id,
    required this.roomId,
    required this.title,
    required this.content,
    this.timestamp,
    this.guideAffinity = 0.0,
    this.messageType = 'general',
  });

  factory GuideMemoryLog.fromJson(Map<String, dynamic> json) {
    return GuideMemoryLog(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      guideAffinity:
          (json['guideAffinity'] as num?)?.toDouble() ?? 0.0,
      messageType: json['messageType'] as String? ?? 'general',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'title': title,
        'content': content,
        'timestamp': timestamp?.toIso8601String(),
        'guideAffinity': guideAffinity,
        'messageType': messageType,
      };
}

/// An archive entry for a completed or in-progress route.
class RouteArchiveEntry {
  final String id;
  final String routeId;
  final String title;
  final String description;
  final List<String> roomsVisited;
  final List<String> branchesChosen;
  final double completionPercentage;
  final String? endingReached;

  const RouteArchiveEntry({
    required this.id,
    required this.routeId,
    required this.title,
    required this.description,
    this.roomsVisited = const [],
    this.branchesChosen = const [],
    this.completionPercentage = 0.0,
    this.endingReached,
  });

  factory RouteArchiveEntry.fromJson(Map<String, dynamic> json) {
    return RouteArchiveEntry(
      id: json['id'] as String,
      routeId: json['routeId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      roomsVisited: json['roomsVisited'] != null
          ? (json['roomsVisited'] as List<dynamic>)
              .map((e) => e as String)
              .toList()
          : const [],
      branchesChosen: json['branchesChosen'] != null
          ? (json['branchesChosen'] as List<dynamic>)
              .map((e) => e as String)
              .toList()
          : const [],
      completionPercentage:
          (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      endingReached: json['endingReached'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeId': routeId,
        'title': title,
        'description': description,
        'roomsVisited': roomsVisited,
        'branchesChosen': branchesChosen,
        'completionPercentage': completionPercentage,
        'endingReached': endingReached,
      };
}

/// An archive entry for a discovered (or undiscovered) secret.
class SecretArchiveEntry {
  final String id;
  final String roomId;
  final String title;
  final String description;
  final String hint;
  final String clueSource;
  final String discoveryMethod;
  final String rewardDescription;
  final bool discovered;

  const SecretArchiveEntry({
    required this.id,
    required this.roomId,
    required this.title,
    required this.description,
    this.hint = '',
    this.clueSource = '',
    this.discoveryMethod = '',
    this.rewardDescription = '',
    this.discovered = false,
  });

  factory SecretArchiveEntry.fromJson(Map<String, dynamic> json) {
    return SecretArchiveEntry(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      hint: json['hint'] as String? ?? '',
      clueSource: json['clueSource'] as String? ?? '',
      discoveryMethod: json['discoveryMethod'] as String? ?? '',
      rewardDescription: json['rewardDescription'] as String? ?? '',
      discovered: json['discovered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'title': title,
        'description': description,
        'hint': hint,
        'clueSource': clueSource,
        'discoveryMethod': discoveryMethod,
        'rewardDescription': rewardDescription,
        'discovered': discovered,
      };
}

/// A lore entry tied to a scene or room.
class SceneLoreEntry {
  final String id;
  final String roomId;
  final String title;
  final String content;
  final String loreCategory;
  final int chapter;
  final bool discovered;

  const SceneLoreEntry({
    required this.id,
    required this.roomId,
    required this.title,
    required this.content,
    this.loreCategory = 'history',
    this.chapter = 1,
    this.discovered = false,
  });

  factory SceneLoreEntry.fromJson(Map<String, dynamic> json) {
    return SceneLoreEntry(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      loreCategory: json['loreCategory'] as String? ?? 'history',
      chapter: json['chapter'] as int? ?? 1,
      discovered: json['discovered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'title': title,
        'content': content,
        'loreCategory': loreCategory,
        'chapter': chapter,
        'discovered': discovered,
      };
}

/// Aggregate codex/collection state — immutable, updated via [copyWith].
class CodexState {
  final List<CodexEntry> entries;
  final List<GuideMemoryLog> guideMemories;
  final List<RouteArchiveEntry> routeArchive;
  final List<SecretArchiveEntry> secretArchive;
  final List<SceneLoreEntry> sceneLore;

  const CodexState({
    this.entries = const [],
    this.guideMemories = const [],
    this.routeArchive = const [],
    this.secretArchive = const [],
    this.sceneLore = const [],
  });

  /// Number of codex entries the player has discovered.
  int get totalDiscovered =>
      entries.where((e) => e.discovered).length +
      secretArchive.where((s) => s.discovered).length +
      sceneLore.where((l) => l.discovered).length;

  /// Total number of discoverable entries across all collections.
  int get totalAvailable =>
      entries.length + secretArchive.length + sceneLore.length;

  /// Overall completion percentage (0.0 – 100.0).
  double get completionPercentage =>
      totalAvailable > 0 ? (totalDiscovered / totalAvailable) * 100.0 : 0;

  CodexState copyWith({
    List<CodexEntry>? entries,
    List<GuideMemoryLog>? guideMemories,
    List<RouteArchiveEntry>? routeArchive,
    List<SecretArchiveEntry>? secretArchive,
    List<SceneLoreEntry>? sceneLore,
  }) {
    return CodexState(
      entries: entries ?? this.entries,
      guideMemories: guideMemories ?? this.guideMemories,
      routeArchive: routeArchive ?? this.routeArchive,
      secretArchive: secretArchive ?? this.secretArchive,
      sceneLore: sceneLore ?? this.sceneLore,
    );
  }

  factory CodexState.fromJson(Map<String, dynamic> json) {
    return CodexState(
      entries: json['entries'] != null
          ? (json['entries'] as List<dynamic>)
              .map((e) => CodexEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      guideMemories: json['guideMemories'] != null
          ? (json['guideMemories'] as List<dynamic>)
              .map((e) => GuideMemoryLog.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      routeArchive: json['routeArchive'] != null
          ? (json['routeArchive'] as List<dynamic>)
              .map(
                  (e) => RouteArchiveEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      secretArchive: json['secretArchive'] != null
          ? (json['secretArchive'] as List<dynamic>)
              .map((e) =>
                  SecretArchiveEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      sceneLore: json['sceneLore'] != null
          ? (json['sceneLore'] as List<dynamic>)
              .map((e) => SceneLoreEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
        'guideMemories': guideMemories.map((e) => e.toJson()).toList(),
        'routeArchive': routeArchive.map((e) => e.toJson()).toList(),
        'secretArchive': secretArchive.map((e) => e.toJson()).toList(),
        'sceneLore': sceneLore.map((e) => e.toJson()).toList(),
      };
}
