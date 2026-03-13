import 'leaderboard_transport_stub.dart'
    if (dart.library.io) 'leaderboard_transport_io.dart';

class LeaderboardTransportResponse {
  final int statusCode;
  final String body;

  const LeaderboardTransportResponse({
    required this.statusCode,
    required this.body,
  });
}

abstract class LeaderboardTransport {
  Future<LeaderboardTransportResponse> get(
    String url, {
    Map<String, String> headers = const {},
  });

  Future<LeaderboardTransportResponse> post(
    String url, {
    Map<String, String> headers = const {},
    String body = '',
  });
}

LeaderboardTransport createLeaderboardTransport() => createTransport();
