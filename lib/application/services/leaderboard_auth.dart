class LeaderboardSession {
  final String accessToken;
  final String? userId;

  const LeaderboardSession({
    required this.accessToken,
    this.userId,
  });
}

abstract class LeaderboardSessionProvider {
  const LeaderboardSessionProvider();

  Future<LeaderboardSession?> currentSession();
}

class EnvironmentLeaderboardSessionProvider
    extends LeaderboardSessionProvider {
  static const String _accessToken =
      String.fromEnvironment('SUPABASE_AUTH_ACCESS_TOKEN');
  static const String _userId = String.fromEnvironment('SUPABASE_AUTH_USER_ID');

  const EnvironmentLeaderboardSessionProvider();

  @override
  Future<LeaderboardSession?> currentSession() async {
    if (_accessToken.isEmpty) return null;
    return LeaderboardSession(
      accessToken: _accessToken,
      userId: _userId.isEmpty ? null : _userId,
    );
  }
}
