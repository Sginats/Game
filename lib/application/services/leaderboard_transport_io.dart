import 'dart:io';

import 'leaderboard_transport.dart';

class _IoLeaderboardTransport implements LeaderboardTransport {
  final HttpClient _client = HttpClient();

  @override
  Future<LeaderboardTransportResponse> get(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    final request = await _client.getUrl(Uri.parse(url));
    headers.forEach(request.headers.set);
    final response = await request.close();
    final body = await response.transform(const SystemEncoding().decoder).join();
    return LeaderboardTransportResponse(
      statusCode: response.statusCode,
      body: body,
    );
  }

  @override
  Future<LeaderboardTransportResponse> post(
    String url, {
    Map<String, String> headers = const {},
    String body = '',
  }) async {
    final request = await _client.postUrl(Uri.parse(url));
    headers.forEach(request.headers.set);
    request.write(body);
    final response = await request.close();
    final responseBody =
        await response.transform(const SystemEncoding().decoder).join();
    return LeaderboardTransportResponse(
      statusCode: response.statusCode,
      body: responseBody,
    );
  }
}

LeaderboardTransport createTransport() => _IoLeaderboardTransport();
