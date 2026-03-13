import 'leaderboard_transport.dart';

class _StubLeaderboardTransport implements LeaderboardTransport {
  @override
  Future<LeaderboardTransportResponse> get(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    throw UnsupportedError('Network transport is unavailable on this platform.');
  }

  @override
  Future<LeaderboardTransportResponse> post(
    String url, {
    Map<String, String> headers = const {},
    String body = '',
  }) async {
    throw UnsupportedError('Network transport is unavailable on this platform.');
  }
}

LeaderboardTransport createTransport() => _StubLeaderboardTransport();
