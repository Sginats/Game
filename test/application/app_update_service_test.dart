import 'package:ai_evolution/application/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppUpdateConfig parses updater settings from JSON', () {
    final config = AppUpdateConfig.fromJson(const {
      'windowsArchiveUrl': 'https://updates.example.com/app-archive.json',
      'autoCheckOnLaunch': false,
      'showPromptWhenAvailable': false,
    });

    expect(
      config.windowsArchiveUrl,
      'https://updates.example.com/app-archive.json',
    );
    expect(config.autoCheckOnLaunch, isFalse);
    expect(config.showPromptWhenAvailable, isFalse);
    expect(config.isConfigured, isTrue);
  });

  test('AppUpdateConfig defaults to disabled updater when archive URL is empty', () {
    final config = AppUpdateConfig.fromJson(const {});

    expect(config.windowsArchiveUrl, isEmpty);
    expect(config.autoCheckOnLaunch, isTrue);
    expect(config.showPromptWhenAvailable, isTrue);
    expect(config.isConfigured, isFalse);
  });
}
