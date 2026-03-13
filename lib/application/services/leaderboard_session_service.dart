import 'package:shared_preferences/shared_preferences.dart';

import 'leaderboard_auth.dart';

class LeaderboardProfile {
  final String playerAlias;
  final String accessToken;
  final String userId;

  const LeaderboardProfile({
    this.playerAlias = '',
    this.accessToken = '',
    this.userId = '',
  });

  bool get hasSession => accessToken.trim().isNotEmpty;

  LeaderboardProfile copyWith({
    String? playerAlias,
    String? accessToken,
    String? userId,
  }) {
    return LeaderboardProfile(
      playerAlias: playerAlias ?? this.playerAlias,
      accessToken: accessToken ?? this.accessToken,
      userId: userId ?? this.userId,
    );
  }
}

class LeaderboardSessionService extends LeaderboardSessionProvider {
  static const _playerAliasKey = 'leaderboard_player_alias';
  static const _accessTokenKey = 'leaderboard_access_token';
  static const _userIdKey = 'leaderboard_user_id';

  LeaderboardProfile _profile = const LeaderboardProfile();

  LeaderboardProfile get profile => _profile;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _profile = LeaderboardProfile(
      playerAlias: prefs.getString(_playerAliasKey) ?? '',
      accessToken: prefs.getString(_accessTokenKey) ?? '',
      userId: prefs.getString(_userIdKey) ?? '',
    );
  }

  Future<void> saveProfile(LeaderboardProfile profile) async {
    final normalized = LeaderboardProfile(
      playerAlias: profile.playerAlias.trim(),
      accessToken: profile.accessToken.trim(),
      userId: profile.userId.trim(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerAliasKey, normalized.playerAlias);
    await prefs.setString(_accessTokenKey, normalized.accessToken);
    await prefs.setString(_userIdKey, normalized.userId);
    _profile = normalized;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playerAliasKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_userIdKey);
    _profile = const LeaderboardProfile();
  }

  @override
  Future<LeaderboardSession?> currentSession() async {
    if (_profile.accessToken.isEmpty) {
      await load();
    }
    if (_profile.accessToken.trim().isEmpty) return null;
    return LeaderboardSession(
      accessToken: _profile.accessToken.trim(),
      userId: _profile.userId.trim().isEmpty ? null : _profile.userId.trim(),
    );
  }
}
