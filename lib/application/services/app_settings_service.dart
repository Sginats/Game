import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/gameplay_extensions.dart';

enum AppLanguage {
  english('en'),
  russian('ru');

  final String code;
  const AppLanguage(this.code);

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (value) => value.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

class AppSettings {
  final AppLanguage language;
  final bool languageConfirmed;
  final bool soundEnabled;
  final bool reducedMotion;
  final double uiScale;
  final double musicVolume;
  final double sfxVolume;
  final ColorblindMode colorblindMode;

  const AppSettings({
    this.language = AppLanguage.english,
    this.languageConfirmed = false,
    this.soundEnabled = true,
    this.reducedMotion = false,
    this.uiScale = 1,
    this.musicVolume = 0.65,
    this.sfxVolume = 0.85,
    this.colorblindMode = ColorblindMode.off,
  });

  AppSettings copyWith({
    AppLanguage? language,
    bool? languageConfirmed,
    bool? soundEnabled,
    bool? reducedMotion,
    double? uiScale,
    double? musicVolume,
    double? sfxVolume,
    ColorblindMode? colorblindMode,
  }) {
    return AppSettings(
      language: language ?? this.language,
      languageConfirmed: languageConfirmed ?? this.languageConfirmed,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      uiScale: uiScale ?? this.uiScale,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      colorblindMode: colorblindMode ?? this.colorblindMode,
    );
  }
}

class AppSettingsService {
  static const _languageKey = 'app_language';
  static const _languageConfirmedKey = 'language_confirmed';
  static const _soundEnabledKey = 'sound_enabled';
  static const _reducedMotionKey = 'reduced_motion';
  static const _uiScaleKey = 'ui_scale';
  static const _musicVolumeKey = 'music_volume';
  static const _sfxVolumeKey = 'sfx_volume';
  static const _colorblindModeKey = 'colorblind_mode';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      language: AppLanguage.fromCode(prefs.getString(_languageKey)),
      languageConfirmed: prefs.getBool(_languageConfirmedKey) ?? false,
      soundEnabled: prefs.getBool(_soundEnabledKey) ?? true,
      reducedMotion: prefs.getBool(_reducedMotionKey) ?? false,
      uiScale: prefs.getDouble(_uiScaleKey) ?? 1,
      musicVolume: prefs.getDouble(_musicVolumeKey) ?? 0.65,
      sfxVolume: prefs.getDouble(_sfxVolumeKey) ?? 0.85,
      colorblindMode: ColorblindMode.values.firstWhere(
        (value) => value.name == prefs.getString(_colorblindModeKey),
        orElse: () => ColorblindMode.off,
      ),
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, settings.language.code);
    await prefs.setBool(_languageConfirmedKey, settings.languageConfirmed);
    await prefs.setBool(_soundEnabledKey, settings.soundEnabled);
    await prefs.setBool(_reducedMotionKey, settings.reducedMotion);
    await prefs.setDouble(_uiScaleKey, settings.uiScale);
    await prefs.setDouble(_musicVolumeKey, settings.musicVolume);
    await prefs.setDouble(_sfxVolumeKey, settings.sfxVolume);
    await prefs.setString(_colorblindModeKey, settings.colorblindMode.name);
  }
}
