import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/game_state.dart';
import 'leaderboard_auth.dart';

enum LeaderboardCategory {
  allTimeScore,
  weeklyScore,
  prestige,
  combo,
  eventClicks,
  eventChain,
}

class LeaderboardEntry {
  final String playerName;
  final String scoreLabel;
  final int rank;
  final String meta;

  const LeaderboardEntry({
    required this.playerName,
    required this.scoreLabel,
    required this.rank,
    required this.meta,
  });
}

class LeaderboardSnapshot {
  final LeaderboardCategory category;
  final List<LeaderboardEntry> entries;
  final String sourceLabel;
  final bool onlineEnabled;
  final String? notice;

  const LeaderboardSnapshot({
    required this.category,
    required this.entries,
    required this.sourceLabel,
    required this.onlineEnabled,
    this.notice,
  });
}

class LeaderboardSubmission {
  final String playerName;
  final LeaderboardCategory category;
  final num score;
  final Map<String, Object?> metadata;

  const LeaderboardSubmission({
    required this.playerName,
    required this.category,
    required this.score,
    this.metadata = const {},
  });
}

/// Supabase-ready scaffold.
/// The app currently uses a local fallback snapshot unless env-backed wiring is added.
class LeaderboardService {
  final LeaderboardSessionProvider _sessionProvider;

  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://uqixesqvozizevjuzjjn.supabase.co',
  );

  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVxaXhlc3F2b3ppemV2anV6ampuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MTMxMTMsImV4cCI6MjA4ODk4OTExM30.dTlIqXh4Z7sBSVijYfyHz-NDBgZk9R2Olj2HvXfdG1s',
  );

  static const String _leaderboardTable = String.fromEnvironment(
    'SUPABASE_LEADERBOARD_TABLE',
    defaultValue: 'leaderboard_entries',
  );

  static const String _submitUrl = String.fromEnvironment(
    'SUPABASE_SUBMIT_URL',
    defaultValue: '',
  );

  const LeaderboardService({
    LeaderboardSessionProvider sessionProvider =
        const EnvironmentLeaderboardSessionProvider(),
  })  : _sessionProvider = sessionProvider;

  bool get isConfigured =>
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;
  bool get canSubmitTrusted => _submitUrl.isNotEmpty;

  SupabaseClient get _client => Supabase.instance.client;

  Future<LeaderboardSnapshot> fetchTop({
    required LeaderboardCategory category,
    int limit = 20,
  }) async {
    if (!isConfigured) {
      return _fallbackSnapshot(
        category,
        notice: 'Supabase credentials are not configured.',
      );
    }

    try {
      var filter = _client
          .from(_leaderboardTable)
          .select('player_name,score,metadata,submitted_at')
          .eq('category', category.wireKey);

      if (category == LeaderboardCategory.weeklyScore) {
        filter = filter.eq('weekly_key', _currentWeeklyKey());
      }

      final payload = await filter
          .order('score', ascending: false)
          .limit(limit);
      final entries = <LeaderboardEntry>[];
      for (var index = 0; index < payload.length; index++) {
        final row = payload[index];
        final metadata =
            (row['metadata'] as Map?)?.cast<String, Object?>() ?? const {};
        entries.add(
          LeaderboardEntry(
            playerName: (row['player_name'] as String?)?.trim().isNotEmpty == true
                ? row['player_name'] as String
                : 'ANON-${index + 1}',
            scoreLabel: _formatScore(row['score']),
            rank: index + 1,
            meta: _metaLabel(category, metadata),
          ),
        );
      }
      return LeaderboardSnapshot(
        category: category,
        entries: entries,
        sourceLabel: 'Supabase',
        onlineEnabled: true,
        notice: entries.isEmpty ? 'No submissions found yet.' : null,
      );
    } catch (_) {
      return _fallbackSnapshot(
        category,
        notice: 'Supabase is configured, but the request failed in the current environment.',
      );
    }
  }

  Future<bool> submit(LeaderboardSubmission submission) async {
    if (!canSubmitTrusted || !_isValidSubmission(submission)) return false;
    final session = await _sessionProvider.currentSession();
    if (session == null || session.accessToken.isEmpty) return false;

    try {
      await _client.functions.invoke(
        _submitUrl,
        body: _payloadForSubmission(submission),
        headers: {
          if (session.userId != null) 'X-Player-Id': session.userId!,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  LeaderboardSubmission buildSubmission({
    required String playerName,
    required LeaderboardCategory category,
    required GameState state,
  }) {
    final score = switch (category) {
      LeaderboardCategory.allTimeScore => state.totalCoinsEarned.toDouble(),
      LeaderboardCategory.weeklyScore => state.totalCoinsEarned.toDouble(),
      LeaderboardCategory.prestige => state.prestigeCount,
      LeaderboardCategory.combo => state.strongestCombo,
      LeaderboardCategory.eventClicks => state.totalEventsClicked,
      LeaderboardCategory.eventChain => state.bestEventChain,
    };

    return LeaderboardSubmission(
      playerName: playerName,
      category: category,
      score: score,
      metadata: {
        'prestige': state.prestigeCount,
        'best_combo': state.strongestCombo,
        'total_clicks': state.totalTaps,
        'event_clicks': state.totalEventsClicked,
        'rare_event_clicks': state.rareEventsFound,
        'best_event_chain': state.bestEventChain,
        'route_signature': state.routeSignature,
        'season_key': state.currentSeasonKey,
        'weekly_key': _currentWeeklyKey(),
      },
    );
  }



  Map<String, Object?> _payloadForSubmission(LeaderboardSubmission submission) {
    final metadata = Map<String, Object?>.from(submission.metadata);
    return {
      'player_name': submission.playerName.trim(),
      'category': submission.category.wireKey,
      'score': submission.score,
      'prestige': metadata['prestige'] ?? 0,
      'era_reached': metadata['era_reached'],
      'best_combo': metadata['best_combo'] ?? 0,
      'total_clicks': metadata['total_clicks'] ?? 0,
      'event_clicks': metadata['event_clicks'] ?? 0,
      'rare_event_clicks': metadata['rare_event_clicks'] ?? 0,
      'best_event_chain': metadata['best_event_chain'] ?? 0,
      'route_signature': metadata['route_signature'],
      'season_key': metadata['season_key'] ?? 'season_alpha',
      'weekly_key': metadata['weekly_key'] ?? _currentWeeklyKey(),
      'metadata': metadata,
    };
  }

  bool _isValidSubmission(LeaderboardSubmission submission) {
    final trimmedName = submission.playerName.trim();
    if (trimmedName.isEmpty || trimmedName.length > 24) return false;
    final score = submission.score.toDouble();
    if (!score.isFinite || score.isNaN || score < 0) return false;
    if (score > 1e30) return false;
    return true;
  }

  LeaderboardSnapshot _fallbackSnapshot(
    LeaderboardCategory category, {
    String? notice,
  }) {
    return LeaderboardSnapshot(
      category: category,
      sourceLabel: isConfigured ? 'Offline fallback' : 'Local demo',
      onlineEnabled: isConfigured,
      notice: notice,
      entries: const [
        LeaderboardEntry(
          playerName: 'SENVA-01',
          scoreLabel: '2.4M',
          rank: 1,
          meta: 'Combo 28',
        ),
        LeaderboardEntry(
          playerName: 'GHOSTGRID',
          scoreLabel: '1.9M',
          rank: 2,
          meta: 'Weekly chain 9',
        ),
        LeaderboardEntry(
          playerName: 'ROOMZERO',
          scoreLabel: '1.4M',
          rank: 3,
          meta: 'Prestige 3',
        ),
      ],
    );
  }

  static String _currentWeeklyKey([DateTime? now]) {
    final date = (now ?? DateTime.now()).toUtc();
    final weekday = date.weekday == DateTime.sunday ? 7 : date.weekday;
    final thursday = date.add(Duration(days: 4 - weekday));
    final firstThursday = DateTime.utc(thursday.year, 1, 4);
    final firstWeekday =
        firstThursday.weekday == DateTime.sunday ? 7 : firstThursday.weekday;
    final firstWeekStart =
        firstThursday.subtract(Duration(days: firstWeekday - 1));
    final weekNumber =
        ((thursday.difference(firstWeekStart).inDays) / 7).floor() + 1;
    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  static String _formatScore(Object? value) {
    final score = (value as num?)?.toDouble() ?? 0;
    if (score >= 1e12) return '${(score / 1e12).toStringAsFixed(2)}T';
    if (score >= 1e9) return '${(score / 1e9).toStringAsFixed(2)}B';
    if (score >= 1e6) return '${(score / 1e6).toStringAsFixed(2)}M';
    if (score >= 1e3) return '${(score / 1e3).toStringAsFixed(1)}K';
    return score.toStringAsFixed(score >= 100 ? 0 : 1);
  }

  static String _metaLabel(
    LeaderboardCategory category,
    Map<String, Object?> metadata,
  ) {
    return switch (category) {
      LeaderboardCategory.allTimeScore =>
        'Prestige ${metadata['prestige'] ?? 0}',
      LeaderboardCategory.weeklyScore =>
        'Week ${metadata['weekly_key'] ?? '-'}',
      LeaderboardCategory.prestige =>
        'Route ${metadata['route_signature'] ?? 'fresh'}',
      LeaderboardCategory.combo =>
        'Clicks ${metadata['total_clicks'] ?? 0}',
      LeaderboardCategory.eventClicks =>
        'Rare ${metadata['rare_event_clicks'] ?? 0}',
      LeaderboardCategory.eventChain =>
        'Events ${metadata['event_clicks'] ?? 0}',
    };
  }
}

extension on LeaderboardCategory {
  String get wireKey => switch (this) {
        LeaderboardCategory.allTimeScore => 'all_time_score',
        LeaderboardCategory.weeklyScore => 'weekly_score',
        LeaderboardCategory.prestige => 'prestige',
        LeaderboardCategory.combo => 'combo',
        LeaderboardCategory.eventClicks => 'event_clicks',
        LeaderboardCategory.eventChain => 'event_chain',
      };
}
