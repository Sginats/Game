import 'package:flutter/foundation.dart';

enum AppUpdatePhase {
  unsupported,
  disabled,
  idle,
  checking,
  upToDate,
  available,
  downloading,
  readyToRestart,
  error,
}

class AppUpdateConfig {
  final String windowsArchiveUrl;
  final bool autoCheckOnLaunch;
  final bool showPromptWhenAvailable;

  const AppUpdateConfig({
    this.windowsArchiveUrl = '',
    this.autoCheckOnLaunch = true,
    this.showPromptWhenAvailable = true,
  });

  bool get isConfigured => windowsArchiveUrl.trim().isNotEmpty;

  AppUpdateConfig copyWith({
    String? windowsArchiveUrl,
    bool? autoCheckOnLaunch,
    bool? showPromptWhenAvailable,
  }) {
    return AppUpdateConfig(
      windowsArchiveUrl: windowsArchiveUrl ?? this.windowsArchiveUrl,
      autoCheckOnLaunch: autoCheckOnLaunch ?? this.autoCheckOnLaunch,
      showPromptWhenAvailable:
          showPromptWhenAvailable ?? this.showPromptWhenAvailable,
    );
  }

  factory AppUpdateConfig.fromJson(Map<String, dynamic> json) {
    return AppUpdateConfig(
      windowsArchiveUrl: json['windowsArchiveUrl'] as String? ?? '',
      autoCheckOnLaunch: json['autoCheckOnLaunch'] as bool? ?? true,
      showPromptWhenAvailable:
          json['showPromptWhenAvailable'] as bool? ?? true,
    );
  }
}

class AppUpdateChange {
  final String message;

  const AppUpdateChange(this.message);
}

class AppUpdateService extends ChangeNotifier {
  AppUpdateService({required this.config});

  factory AppUpdateService.disabled() =>
      AppUpdateService(config: const AppUpdateConfig());

  final AppUpdateConfig config;
  AppUpdatePhase _phase = AppUpdatePhase.unsupported;
  bool _initialized = false;
  String? _errorMessage;

  AppUpdatePhase get phase => _phase;
  Object? get availableUpdate => null;
  Object? get updateProgress => null;
  String? get currentBuild => null;
  String? get errorMessage => _errorMessage;
  bool get initialized => _initialized;
  bool get isSupported => false;
  bool get isEnabled => false;
  bool get hasUpdate => false;
  bool get isDownloading => false;
  bool get readyToRestart => false;
  bool get isMandatory => false;
  String? get availableVersion => null;
  List<AppUpdateChange> get releaseNotes => const [];
  double get downloadProgress => 0;
  int get downloadedBytes => 0;
  int get totalBytes => 0;
  double get totalMegabytes => 0;
  double get downloadedMegabytes => 0;

  Future<void> initialize({required bool autoCheckEnabled}) async {
    _initialized = true;
    _phase = AppUpdatePhase.unsupported;
    notifyListeners();
  }

  Future<bool> checkForUpdates({bool silent = false}) async {
    _phase = AppUpdatePhase.unsupported;
    if (!silent) notifyListeners();
    return false;
  }

  Future<void> downloadUpdate() async {}

  Future<void> restartToApply() async {}
}
