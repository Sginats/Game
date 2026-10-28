import 'dart:async';
import 'dart:io';

import 'package:desktop_updater/desktop_updater.dart';
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

class AppUpdateService extends ChangeNotifier {
  AppUpdateService({
    required this.config,
    DesktopUpdater? updater,
  }) : _updater = updater ?? DesktopUpdater();

  factory AppUpdateService.disabled() {
    return AppUpdateService(config: const AppUpdateConfig());
  }

  final AppUpdateConfig config;
  final DesktopUpdater _updater;

  AppUpdatePhase _phase = AppUpdatePhase.idle;
  AppUpdatePhase get phase => _phase;

  ItemModel? _availableUpdate;
  ItemModel? get availableUpdate => _availableUpdate;

  UpdateProgress? _updateProgress;
  UpdateProgress? get updateProgress => _updateProgress;

  String? _currentBuild;
  String? get currentBuild => _currentBuild;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _initialized = false;
  bool get initialized => _initialized;

  bool get isSupported => !kIsWeb && Platform.isWindows;
  bool get isEnabled => isSupported && config.isConfigured;
  bool get hasUpdate => _phase == AppUpdatePhase.available;
  bool get isDownloading => _phase == AppUpdatePhase.downloading;
  bool get readyToRestart => _phase == AppUpdatePhase.readyToRestart;
  bool get isMandatory => _availableUpdate?.mandatory ?? false;
  String? get availableVersion => _availableUpdate?.version;
  List<ChangeModel> get releaseNotes => _availableUpdate?.changes ?? const [];
  double get downloadProgress =>
      (_updateProgress == null || _updateProgress!.totalBytes == 0)
          ? 0
          : _updateProgress!.receivedBytes / _updateProgress!.totalBytes;
  int get downloadedBytes => (_updateProgress?.receivedBytes ?? 0).toInt();
  int get totalBytes => (_updateProgress?.totalBytes ?? 0).toInt();
  double get totalMegabytes => totalBytes / (1024 * 1024);
  double get downloadedMegabytes => downloadedBytes / (1024 * 1024);

  Future<void> initialize({
    required bool autoCheckEnabled,
  }) async {
    _initialized = true;
    if (!isSupported) {
      _phase = AppUpdatePhase.unsupported;
      notifyListeners();
      return;
    }

    try {
      _currentBuild = await _updater.getCurrentVersion();
    } catch (_) {
      _currentBuild = null;
    }

    if (!config.isConfigured) {
      _phase = AppUpdatePhase.disabled;
      notifyListeners();
      return;
    }

    _phase = AppUpdatePhase.idle;
    notifyListeners();

    if (autoCheckEnabled && config.autoCheckOnLaunch) {
      unawaited(checkForUpdates(silent: true));
    }
  }

  Future<bool> checkForUpdates({bool silent = false}) async {
    if (!isSupported) {
      _phase = AppUpdatePhase.unsupported;
      if (!silent) notifyListeners();
      return false;
    }
    if (!config.isConfigured) {
      _phase = AppUpdatePhase.disabled;
      if (!silent) notifyListeners();
      return false;
    }

    _phase = AppUpdatePhase.checking;
    _availableUpdate = null;
    _updateProgress = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final item = await _updater.versionCheck(
        appArchiveUrl: config.windowsArchiveUrl,
      );
      _availableUpdate = item;
      _phase =
          item == null ? AppUpdatePhase.upToDate : AppUpdatePhase.available;
      notifyListeners();
      return item != null;
    } catch (error) {
      _errorMessage = error.toString();
      _phase = AppUpdatePhase.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> downloadUpdate() async {
    final item = _availableUpdate;
    if (item == null) return;
    if (item.changedFiles == null || item.changedFiles!.isEmpty) {
      _phase = AppUpdatePhase.readyToRestart;
      notifyListeners();
      return;
    }

    _phase = AppUpdatePhase.downloading;
    _errorMessage = null;
    _updateProgress = null;
    notifyListeners();

    try {
      final stream = await _updater.updateApp(
        remoteUpdateFolder: item.url,
        changedFiles: item.changedFiles ?? const [],
      );
      final completer = Completer<void>();
      late final StreamSubscription<UpdateProgress> subscription;
      subscription = stream.listen(
        (event) {
          _updateProgress = event;
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          _errorMessage = error.toString();
          _phase = AppUpdatePhase.error;
          notifyListeners();
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        },
        onDone: () {
          _phase = AppUpdatePhase.readyToRestart;
          notifyListeners();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        cancelOnError: true,
      );

      await completer.future;
      await subscription.cancel();
    } catch (error) {
      _errorMessage = error.toString();
      _phase = AppUpdatePhase.error;
      notifyListeners();
    }
  }

  Future<void> restartToApply() async {
    await _updater.restartApp();
  }
}
