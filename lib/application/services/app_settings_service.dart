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
  final bool autoCheckUpdates;
  final bool reducedMotion;
  final bool screenShake;
  final double uiScale;
  final double musicVolume;
  final double sfxVolume;
  final ColorblindMode colorblindMode;
  final String contrastMode;
  final String tooltipBehavior;
  final String transitionSpeed;

  const AppSettings({
    this.language = AppLanguage.english,
    this.languageConfirmed = false,
    this.soundEnabled = true,
    this.autoCheckUpdates = true,
    this.reducedMotion = false,
    this.screenShake = true,
    this.uiScale = 1,
    this.musicVolume = 0.65,
    this.sfxVolume = 0.85,
    this.colorblindMode = ColorblindMode.off,
    this.contrastMode = 'standard',
    this.tooltipBehavior = 'onHover',
    this.transitionSpeed = 'full',
  });

  AppSettings copyWith({
    AppLanguage? language,
    bool? languageConfirmed,
    bool? soundEnabled,
    bool? autoCheckUpdates,
    bool? reducedMotion,
    bool? screenShake,
    double? uiScale,
    double? musicVolume,
    double? sfxVolume,
    ColorblindMode? colorblindMode,
    String? contrastMode,
    String? tooltipBehavior,
    String? transitionSpeed,
  }) {
    return AppSettings(
      language: language ?? this.language,
      languageConfirmed: languageConfirmed ?? this.languageConfirmed,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      screenShake: screenShake ?? this.screenShake,
      uiScale: uiScale ?? this.uiScale,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      colorblindMode: colorblindMode ?? this.colorblindMode,
      contrastMode: contrastMode ?? this.contrastMode,
      tooltipBehavior: tooltipBehavior ?? this.tooltipBehavior,
      transitionSpeed: transitionSpeed ?? this.transitionSpeed,
    );
  }
}

class AppSettingsService {
  static const _languageKey = 'app_language';
  static const _languageConfirmedKey = 'language_confirmed';
  static const _soundEnabledKey = 'sound_enabled';
  static const _autoCheckUpdatesKey = 'auto_check_updates';
  static const _reducedMotionKey = 'reduced_motion';
  static const _uiScaleKey = 'ui_scale';
  static const _musicVolumeKey = 'music_volume';
  static const _sfxVolumeKey = 'sfx_volume';
  static const _colorblindModeKey = 'colorblind_mode';
  static const _screenShakeKey = 'screen_shake';
  static const _contrastModeKey = 'contrast_mode';
  static const _tooltipBehaviorKey = 'tooltip_behavior';
  static const _transitionSpeedKey = 'transition_speed';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      language: AppLanguage.fromCode(prefs.getString(_languageKey)),
      languageConfirmed: prefs.getBool(_languageConfirmedKey) ?? false,
      soundEnabled: prefs.getBool(_soundEnabledKey) ?? true,
      autoCheckUpdates: prefs.getBool(_autoCheckUpdatesKey) ?? true,
      reducedMotion: prefs.getBool(_reducedMotionKey) ?? false,
      screenShake: prefs.getBool(_screenShakeKey) ?? true,
      uiScale: prefs.getDouble(_uiScaleKey) ?? 1,
      musicVolume: prefs.getDouble(_musicVolumeKey) ?? 0.65,
      sfxVolume: prefs.getDouble(_sfxVolumeKey) ?? 0.85,
      colorblindMode: ColorblindMode.values.firstWhere(
        (value) => value.name == prefs.getString(_colorblindModeKey),
        orElse: () => ColorblindMode.off,
      ),
      contrastMode: prefs.getString(_contrastModeKey) ?? 'standard',
      tooltipBehavior: prefs.getString(_tooltipBehaviorKey) ?? 'onHover',
      transitionSpeed: prefs.getString(_transitionSpeedKey) ?? 'full',
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, settings.language.code);
    await prefs.setBool(_languageConfirmedKey, settings.languageConfirmed);
    await prefs.setBool(_soundEnabledKey, settings.soundEnabled);
    await prefs.setBool(_autoCheckUpdatesKey, settings.autoCheckUpdates);
    await prefs.setBool(_reducedMotionKey, settings.reducedMotion);
    await prefs.setBool(_screenShakeKey, settings.screenShake);
    await prefs.setDouble(_uiScaleKey, settings.uiScale);
    await prefs.setDouble(_musicVolumeKey, settings.musicVolume);
    await prefs.setDouble(_sfxVolumeKey, settings.sfxVolume);
    await prefs.setString(_colorblindModeKey, settings.colorblindMode.name);
    await prefs.setString(_contrastModeKey, settings.contrastMode);
    await prefs.setString(_tooltipBehaviorKey, settings.tooltipBehavior);
    await prefs.setString(_transitionSpeedKey, settings.transitionSpeed);
  }
}
