import 'app_settings_service.dart';
import 'leaderboard_service.dart';
import '../../domain/models/progression_content.dart';
import '../../domain/models/gameplay_extensions.dart';
import '../../domain/models/generator.dart';
import '../../domain/models/era.dart';
import '../../domain/models/upgrade.dart';

class AppStrings {
  final AppLanguage currentLanguage;

  const AppStrings(this.currentLanguage);

  bool get isRussian => currentLanguage == AppLanguage.russian;

  String get appTitle => isRussian ? 'Room Zero' : 'Room Zero';
  String get loading => isRussian ? 'Загрузка…' : 'Loading…';
  String get startIntro => isRussian
      ? 'Маленький ИИ пробуждается в сломанной комнате.\nРазвей его от угла с хламом до камеры сингулярности.'
      : 'A tiny AI awakens in a broken room.\nEvolve it from junk corner to singularity chamber.';
  String get tapToEarnTitle => isRussian ? 'Тапайте ради ресурсов' : 'Tap to Earn';
  String get tapToEarnText => isRussian
      ? 'Нажимайте на ядро комнаты, чтобы добывать лом. Быстрые нажатия собирают комбо и дают бонусные ресурсы.'
      : 'Tap the room core to generate scrap. Rapid tapping builds a combo for bonus resources!';
  String get buildGeneratorsTitle =>
      isRussian ? 'Стройте генераторы' : 'Build Generators';
  String get buildGeneratorsText => isRussian
      ? 'Вкладывайтесь в системы комнаты, чтобы получать ресурсы автоматически.'
      : 'Invest in room systems to earn resources automatically.';
  String get upgradeEvolveTitle =>
      isRussian ? 'Улучшайте и эволюционируйте' : 'Upgrade & Evolve';
  String get upgradeEvolveText => isRussian
      ? 'Проводите комнату через 20 эпох. Делайте престиж ради постоянных бонусов.'
      : 'Upgrade your room through 20 eras. Prestige to reset with permanent bonuses!';
  String get enterRoomZero =>
      isRussian ? 'Войти в Room Zero' : 'Enter Room Zero';
  String get chooseStartLanguage => isRussian
      ? 'Выберите язык перед началом'
      : 'Choose a language before starting';
  String get languageRequired => isRussian
      ? 'Сначала подтвердите язык интерфейса.'
      : 'Confirm the interface language first.';
  String get comboTaps => isRussian ? 'Комбо-тапы' : 'Combo taps';
  String get branchingTree => isRussian ? 'Ветвящееся дерево' : 'Branching tree';
  String get activeAbilities => isRussian ? 'Активные способности' : 'Active abilities';
  String get eventsAndMilestones => isRussian
      ? 'События и рубежи'
      : 'Events & milestones';
  String get welcomeBack => isRussian ? 'С возвращением!' : 'Welcome Back!';
  String get offlineWorked => isRussian
      ? 'Пока вас не было, ваш ИИ продолжал работать.'
      : 'While you were away, your AI kept working.';
  String get collect => isRussian ? 'Забрать' : 'Collect';
  String get achievementUnlocked =>
      isRussian ? 'Достижение открыто!' : 'Achievement Unlocked!';
  String eraProgress(int current, int total, String currency) => isRussian
      ? 'Эпоха $current/$total · $currency'
      : 'Era $current/$total · $currency';
  String perSecond(String value) =>
      isRussian ? '$value/сек' : '$value/sec';
  String combo(int value) =>
      isRussian ? '🔥 Комбо ×$value' : '🔥 Combo ×$value';
  String get stats => isRussian ? 'Статистика' : 'Stats';
  String get settings => isRussian ? 'Настройки' : 'Settings';
  String get leaderboard => isRussian ? 'Таблица лидеров' : 'Leaderboard';
  String get codex => isRussian ? 'Кодекс' : 'Codex';
  String get sceneArchive => isRussian ? 'Архив сцен' : 'Scene archive';
  String get eventCodex => isRussian ? 'Архив событий' : 'Event codex';
  String get routeSummary => isRussian ? 'Сводка маршрута' : 'Route summary';
  String get guideStatus => isRussian ? 'Статус гида' : 'Guide status';
  String get discoveredEntries => isRussian ? 'Открыто записей' : 'Discovered entries';
  String get sceneBadge => isRussian ? 'Значок сцены' : 'Scene badge';
  String get activeEventTitle => isRussian ? 'Активное событие' : 'Active event';
  String get eventChain => isRussian ? 'Цепочка событий' : 'Event chain';
  String get timeRemaining => isRussian ? 'Осталось времени' : 'Time remaining';
  String get sceneCompleted => isRussian ? 'Сцена завершена' : 'Scene complete';
  String get notYetCompleted => isRussian ? 'Ещё не завершена' : 'Not yet complete';
  String get seenSecrets => isRussian ? 'Найдено секретов' : 'Secrets found';
  String get guideAffinityLabel => isRussian ? 'Доверие гида' : 'Guide affinity';
  String get guideTierLabel => isRussian ? 'Уровень гида' : 'Guide tier';
  String get mutators => isRussian ? 'Мутаторы' : 'Mutators';
  String get challenges => isRussian ? 'Испытания' : 'Challenges';
  String get reducedMotion => isRussian ? 'Меньше анимации' : 'Reduced motion';
  String get reducedMotionDescription => isRussian
      ? 'Смягчает интенсивные анимации и движение интерфейса.'
      : 'Tones down movement-heavy effects.';
  String get screenShake => isRussian ? 'Тряска экрана' : 'Screen shake';
  String get screenShakeDescription => isRussian
      ? 'Включить эффекты тряски экрана при действиях.'
      : 'Enable screen shake effects on actions.';
  String get uiScale => isRussian ? 'Масштаб UI' : 'UI scale';
  String get musicLayer => isRussian ? 'Музыкальный слой' : 'Music layer';
  String get sfxVolume => isRussian ? 'Громкость SFX' : 'SFX volume';
  String get colorClarity => isRussian ? 'Цветовая ясность' : 'Color clarity';
  String get settingsGeneral => isRussian ? 'Основные' : 'General';
  String get settingsUpdates => isRussian ? 'Обновления' : 'Updates';
  String get settingsAudio => isRussian ? 'Звук' : 'Audio';
  String get settingsGraphics => isRussian ? 'Графика' : 'Graphics';
  String get settingsAccessibility =>
      isRussian ? 'Доступность' : 'Accessibility';
  String get settingsGameplay =>
      isRussian ? 'Игровой процесс' : 'Gameplay';
  String get purchaseQuantity =>
      isRussian ? 'Количество покупки' : 'Purchase quantity';
  String get abilities => isRussian ? 'Способности' : 'Abilities';
  String get selectNodeHint => isRussian
      ? 'Нажмите на узел дерева'
      : 'Tap a tree node';
  String get canPurchase => isRussian ? 'Можно купить' : 'Can purchase';
  String get notEnoughCoins =>
      isRussian ? 'Недостаточно ресурсов' : 'Not enough resources';
  String get dependencyMissing =>
      isRussian ? 'Зависимость не выполнена' : 'Dependency not met';
  String get alreadyOwned => isRussian ? 'Уже куплено' : 'Already owned';
  String get lockedByRoute =>
      isRussian ? 'Заблокировано маршрутом' : 'Locked by route';
  String get source => isRussian ? 'Источник' : 'Source';
  String get online => isRussian ? 'Сеть' : 'Online';
  String get submitPath => isRussian ? 'Путь отправки' : 'Submit path';
  String get playerTag => isRussian ? 'Тег игрока' : 'Player tag';
  String get refresh => isRussian ? 'Обновить' : 'Refresh';
  String get session => isRussian ? 'Сессия' : 'Session';
  String get save => isRussian ? 'Сохранить' : 'Save';
  String get clear => isRussian ? 'Очистить' : 'Clear';
  String get updates => isRussian ? 'Обновления' : 'Updates';
  String get unknownLabel => isRussian ? 'Неизвестно' : 'Unknown';
  String get laterLabel => isRussian ? 'Позже' : 'Later';
  String get autoCheckUpdatesLabel => isRussian
      ? 'Проверять обновления автоматически'
      : 'Check for updates automatically';
  String get autoCheckUpdatesDescription => isRussian
      ? 'Проверять наличие новой версии при запуске игры.'
      : 'Check for a newer build when the game starts.';
  String get checkingForUpdates => isRussian
      ? 'Проверка обновлений…'
      : 'Checking for updates...';
  String get updatesUnsupported => isRussian
      ? 'Встроенное обновление доступно только в Windows-сборке.'
      : 'In-app updates are only available in the Windows build.';
  String get updatesDisabled => isRussian
      ? 'Лента обновлений ещё не настроена.'
      : 'The update feed is not configured yet.';
  String get updatesIdle => isRussian
      ? 'Автообновление готово к проверке.'
      : 'The updater is ready to check for updates.';
  String get updatesUpToDate => isRussian
      ? 'У вас установлена актуальная версия.'
      : 'You already have the latest version.';
  String get updatesWindowsOnly => isRussian
      ? 'Этот механизм обновления работает только в Windows-приложении.'
      : 'This updater only runs inside the Windows desktop app.';
  String get updatesConfigurationHint => isRussian
      ? 'Укажите windowsArchiveUrl в assets/config/update_config.json и опубликуйте app-archive.json вместе с архивом обновления.'
      : 'Set windowsArchiveUrl in assets/config/update_config.json and publish app-archive.json with the update archive.';
  String get checkForUpdatesLabel => isRussian
      ? 'Проверить обновления'
      : 'Check for updates';
  String get downloadUpdateLabel => isRussian
      ? 'Скачать обновление'
      : 'Download update';
  String get restartToUpdateLabel => isRussian
      ? 'Перезапустить и обновить'
      : 'Restart to update';
  String get updateAvailableTitle => isRussian
      ? 'Доступно обновление'
      : 'Update available';
  String updateAvailableBody(String version) => isRussian
      ? 'Найдена версия $version. Её можно скачать и применить прямо из игры.'
      : 'Version $version is available. You can download and apply it from inside the game.';
  String get releaseNotesLabel => isRussian ? 'Что изменилось' : 'What changed';
  String updateDownloadSize(String sizeMb) => isRussian
      ? 'Размер загрузки: $sizeMb МБ'
      : 'Download size: $sizeMb MB';
  String get updateReadyTitle => isRussian
      ? 'Обновление готово'
      : 'Update ready';
  String get updateReadyBody => isRussian
      ? 'Файлы обновления уже загружены. Перезапустите игру, чтобы применить новую версию.'
      : 'The update files are downloaded. Restart the game to apply the new version.';
  String get updateReadyStatus => isRussian
      ? 'Обновление загружено и ждёт перезапуска.'
      : 'The update is downloaded and ready to restart.';
  String updateBuildLabel(String build) =>
      isRussian ? 'Сборка $build' : 'Build $build';
  String updateDownloading(String downloadedMb, String totalMb) => isRussian
      ? 'Загрузка обновления: $downloadedMb / $totalMb МБ'
      : 'Downloading update: $downloadedMb / $totalMb MB';
  String updateError(String message) => isRussian
      ? 'Ошибка обновления: $message'
      : 'Update error: $message';
  String updateAvailableSnackbar(String? version) => isRussian
      ? 'Найдена новая версия ${version ?? unknownLabel}.'
      : 'New version ${version ?? unknownLabel} is available.';
  String get upToDateSnackbar => isRussian
      ? 'Обновлений не найдено.'
      : 'No updates found.';
  String get purchase => isRussian ? 'Купить' : 'Purchase';
  String get locked => isRussian ? 'Заблокировано' : 'Locked';
  String get hidden => isRussian ? 'Скрыто' : 'Hidden';
  String get discovered => isRussian ? 'Найдено' : 'Discovered';
  String get loadout => isRussian ? 'Сборка' : 'Loadout';
  String get loadouts => isRussian ? 'Сборки' : 'Loadouts';
  String respecLabel(int tokens) =>
      isRussian ? 'Сброс ($tokens)' : 'Respec ($tokens)';
  String get savePreset => isRussian ? 'Сохранить пресет' : 'Save preset';
  String get saveCurrent => isRussian ? 'Сохранить текущее' : 'Save current';
  String get savedPresets => isRussian ? 'Сохраненные пресеты' : 'Saved presets';
  String get apply => isRussian ? 'Применить' : 'Apply';
  String get editCopy => isRussian ? 'Изменить копию' : 'Edit copy';
  String get playerAlias => isRussian ? 'Псевдоним игрока' : 'Player alias';
  String get playerAliasHint => isRussian
      ? 'Показывается в таблице лидеров'
      : 'Shown on the leaderboard if set';
  String get userId => isRussian ? 'ID пользователя' : 'User id';
  String get userIdHint => isRussian
      ? 'ID пользователя Supabase auth'
      : 'Supabase auth user id';
  String get accessToken => isRussian ? 'Токен доступа' : 'Access token';
  String get accessTokenHint => isRussian
      ? 'JWT для доверенной отправки'
      : 'Authenticated JWT for trusted submit';
  String get leaderboardSession => isRussian ? 'Сессия лидеров' : 'Leaderboard Session';
  String get safeChoice => isRussian ? 'Безопасно' : 'Safe';
  String get pushChoice => isRussian ? 'Рискнуть' : 'Push';
  String get takeChoice => isRussian ? 'Забрать' : 'Take';
  String get close => isRussian ? 'Закрыть' : 'Close';
  String get route => isRussian ? 'Маршрут' : 'Route';
  String get cost => isRussian ? 'Цена' : 'Cost';
  String get effect => isRussian ? 'Эффект' : 'Effect';
  String get dependency => isRussian ? 'Зависимость' : 'Dependency';
  String get selectedNode => isRussian ? 'Выбранный узел' : 'Selected Node';
  String get treeFocusHint => isRussian
      ? 'Выберите узел в дереве, чтобы увидеть детали.'
      : 'Select a node in the tree to inspect its details.';
  String get notifications => isRussian ? 'Уведомления' : 'Notifications';
  String get noNotifications => isRussian ? 'Система стабильна.' : 'System stable.';
  String get ready => isRussian ? 'ГОТОВО' : 'READY';
  String get rerolls => isRussian ? 'Повторы' : 'Rerolls';
  String get missedEventCharges => isRussian ? 'Заряды пропущенных событий' : 'Missed-event charges';
  String get trusted => isRussian ? 'доверенный' : 'trusted';
  String get disabled => isRussian ? 'отключен' : 'disabled';
  String get configured => isRussian ? 'настроено' : 'configured';
  String get fallback => isRussian ? 'резерв' : 'fallback';
  String get missing => isRussian ? 'отсутствует' : 'missing';
  String get currentRoom => isRussian ? 'Текущая комната' : 'Current Room';
  String get previousRoom => isRussian ? 'Назад' : 'Previous';
  String get nextRoom => isRussian ? 'Далее' : 'Next';
  String get roomMap => isRussian ? 'Комнаты' : 'Rooms';
  String get roomGuide => isRussian ? 'Гид' : 'Guide';
  String get roomOverview => isRussian ? 'Обзор комнаты' : 'Room overview';
  String get guideToneLabel => isRussian ? 'Тон гида' : 'Guide tone';
  String get ambientLayersLabel => isRussian ? 'Аудиослои' : 'Audio layers';
  String get transformationTrack => isRussian ? 'Этапы трансформации' : 'Transformation track';
  String get twistStatusLabel => isRussian ? 'Сдвиг комнаты' : 'Room twist';
  String get secretsTrackedLabel => isRussian ? 'Секретов в комнате' : 'Secrets in room';
  String get transformationReady => isRussian ? 'готова к сдвигу' : 'ready to shift';
  String get transformationDormant => isRussian ? 'ожидает' : 'dormant';
  String get environmentChanges => isRussian ? 'Изменения среды' : 'Environment changes';
  String get guideMemoryLog => isRussian ? 'Память гида' : 'Guide memory log';
  String get relicArchiveTitle => isRussian ? 'Реликвии' : 'Relics';
  String get codexCompletion => isRussian ? 'Прогресс кодекса' : 'Codex progress';
  String get metaProgressLabel => isRussian ? 'Мета-прогресс' : 'Meta progression';
  String get firstRoomChecklist => isRussian ? 'Первые шаги' : 'First steps';
  String get nextRoomTarget => isRussian ? 'Следующая комната' : 'Next room';
  String tutorialTapGoal(int current, int target) => isRussian
      ? 'Нажмите по ядру: $current/$target'
      : 'Tap the core: $current/$target';
  String tutorialGeneratorGoal(int current, int target) => isRussian
      ? 'Поднимите уровень ядра: $current/$target'
      : 'Raise the core level: $current/$target';
  String tutorialUpgradeGoal(int current, int target) => isRussian
      ? 'Купите улучшения: $current/$target'
      : 'Buy upgrades: $current/$target';
  String unlockRequirementLabel(String name, int level) => isRussian
      ? 'Открытие: $name ур. $level'
      : 'Unlock at $name Lv $level';
  String roomEvolutionStage(String label) =>
      isRussian ? 'Стадия: $label' : 'Stage: $label';
  String get stageDormant => isRussian ? 'Пробуждение' : 'Awakening';
  String get stageActive => isRussian ? 'Разгон' : 'Active';
  String get stageRefined => isRussian ? 'Отстройка' : 'Refined';
  String get stageAscendant => isRussian ? 'Доминирование' : 'Ascendant';
  String roomUpgradeProgress(int bought, int total) => isRussian
      ? 'Узлы комнаты: $bought/$total'
      : 'Room nodes: $bought/$total';
  String get preloadingNextRoom => isRussian
      ? 'Подготовка следующей комнаты'
      : 'Preloading next room';
  String get roomRule => isRussian ? 'Правило комнаты' : 'Room rule';
  String roomProgress(int current, int total) =>
      isRussian ? 'Комната $current/$total' : 'Room $current/$total';
  String get reducedMotionShort => reducedMotion;
  String get trustedSubmitReady => isRussian ? 'готово' : 'ready';
  String get generators => isRussian ? 'Генераторы' : 'Generators';
  String get upgrades => isRussian ? 'Улучшения' : 'Upgrades';
  String get achievements => isRussian ? 'Достижения' : 'Achievements';
  String get totalTapsStat => isRussian ? 'Всего тапов' : 'Total taps';
  String get strongestCombo => isRussian ? 'Лучшее комбо' : 'Strongest combo';
  String get resourcesEarned => isRussian ? 'Ресурсов заработано' : 'Resources earned';
  String get generatorsBought => isRussian ? 'Генераторов куплено' : 'Generators bought';
  String get upgradesBought => isRussian ? 'Улучшений куплено' : 'Upgrades bought';
  String get criticalClicks => isRussian ? 'Критических кликов' : 'Critical clicks';
  String get eventsClicked => isRussian ? 'Событий нажато' : 'Events clicked';
  String get rareEvents => isRussian ? 'Редких событий' : 'Rare events';
  String get bestEventChain => isRussian ? 'Лучшая цепочка событий' : 'Best event chain';
  String get playtime => isRussian ? 'Время игры' : 'Playtime';
  String get offlineTime => isRussian ? 'Время офлайн' : 'Offline time';
  String get playstyle => isRussian ? 'Стиль игры' : 'Playstyle';
  String get routeSignature => isRussian ? 'Сигнатура маршрута' : 'Route signature';
  String get saveGame => isRussian ? 'Сохранить игру' : 'Save Game';
  String get saveCurrentProgress => isRussian
      ? 'Сохранить текущий прогресс'
      : 'Save your current progress';
  String get gameSaved => isRussian ? 'Игра сохранена!' : 'Game saved!';
  String get language => isRussian ? 'Язык' : 'Language';
  String get chooseLanguage =>
      isRussian ? 'Выберите язык интерфейса' : 'Choose the interface language';
  String get sound => isRussian ? 'Звук' : 'Sound';
  String get soundOn => isRussian
      ? 'Системные звуки для нажатий и наград'
      : 'System sounds for taps and rewards';
  String get english => isRussian ? 'Английский' : 'English';
  String get russian => isRussian ? 'Русский' : 'Russian';
  String get resetGame => isRussian ? 'Сбросить игру' : 'Reset Game';
  String get eraseProgress => isRussian
      ? 'Удалить весь прогресс и начать заново'
      : 'Erase all progress and start over';
  String get resetGameTitle =>
      isRussian ? 'Сбросить игру?' : 'Reset Game?';
  String get resetGameBody => isRussian
      ? 'Это действие навсегда удалит весь прогресс, включая престиж, достижения и всё остальное.\n\nОтменить будет нельзя.'
      : 'This will permanently erase all your progress including prestige levels, achievements, and everything else.\n\nThis cannot be undone!';
  String get cancel => isRussian ? 'Отмена' : 'Cancel';
  String get resetEverything =>
      isRussian ? 'Сбросить всё' : 'Reset Everything';
  String get totalCoinsEarned =>
      isRussian ? 'Всего заработано' : 'Total Coins Earned';
  String get currentCoins =>
      isRussian ? 'Текущие монеты' : 'Current Coins';
  String get productionPerSecond =>
      isRussian ? 'Производство/сек' : 'Production/sec';
  String get totalTaps => isRussian ? 'Всего тапов' : 'Total Taps';
  String get tapMultiplier =>
      isRussian ? 'Множитель тапа' : 'Tap Multiplier';
  String get productionMultiplier =>
      isRussian ? 'Множитель производства' : 'Production Multiplier';
  String get prestigeCount =>
      isRussian ? 'Количество престижей' : 'Prestige Count';
  String get prestigeMultiplier =>
      isRussian ? 'Множитель престижа' : 'Prestige Multiplier';
  String achievementsCount(int unlocked, int total) => isRussian
      ? 'Достижения: $unlocked/$total'
      : 'Achievements: $unlocked/$total';
  String eraLabel(int order) => isRussian ? 'Эпоха' : 'Era';
  String get currency => isRussian ? 'Валюта' : 'Currency';
  String get noAchievementsConfigured => isRussian
      ? 'Достижения не настроены.'
      : 'No achievements configured.';
  String get prestige => isRussian ? 'Престиж' : 'Prestige';
  String get prestigeDescription => isRussian
      ? 'Сбросьте прогресс в обмен на постоянный\nмножитель производства и нажатий.'
      : 'Reset your progress in exchange for a permanent\nproduction & tap multiplier.';
  String get currentPrestigeLevel =>
      isRussian ? 'Текущий уровень престижа' : 'Current Prestige Level';
  String get currentMultiplier =>
      isRussian ? 'Текущий множитель' : 'Current Multiplier';
  String get nextMultiplier =>
      isRussian ? 'Следующий множитель' : 'Next Multiplier';
  String get nextPrestigeBonus =>
      isRussian ? 'Следующий бонус престижа' : 'Next Prestige Bonus';
  String get requirement => isRussian ? 'Требование' : 'Requirement';
  String get yourTotal => isRussian ? 'Ваш итог' : 'Your Total';
  String totalCoinsRequirement(String value) => isRussian
      ? '$value всего монет'
      : '$value total coins';
  String get confirmPrestige =>
      isRussian ? 'Подтвердить престиж' : 'Confirm Prestige';
  String prestigeResetBody(String multiplier) => isRussian
      ? 'Это сбросит ваши монеты, генераторы и улучшения.\n\nВы получите постоянный множитель ×$multiplier.'
      : 'This will reset your coins, generators, and upgrades.\n\nYou will gain a ×$multiplier permanent multiplier.';
  String get prestigeNow => isRussian ? 'Сделать престиж' : 'Prestige Now!';
  String earnToPrestige(String value) => isRussian
      ? 'Заработайте $value монет для престижа'
      : 'Earn $value coins to prestige';
  String get prestigeAction => isRussian ? 'Престиж!' : 'Prestige!';
  String get maxed => isRussian ? '✅ МАКС' : '✅ MAXED';
  String buyLabel(int quantity) {
    if (quantity == 1) {
      return isRussian ? 'Купить' : 'Buy';
    }
    return isRussian ? 'Купить $quantity' : 'Buy $quantity';
  }

  String get claim => isRussian ? 'Забрать' : 'Claim';
  String get reroll => isRussian ? 'Заменить' : 'Reroll';
  String get refreshing => isRussian ? 'Обновление…' : 'Refreshing...';
  String get submittingCurrentRun =>
      isRussian ? 'Отправка текущего забега…' : 'Submitting current run...';
  String get submissionAccepted => isRussian
      ? 'Отправка принята. Обновите список, чтобы получить текущий ранг.'
      : 'Submission accepted. Refresh to pull current ranks.';
  String get submissionUnavailable => isRussian
      ? 'Отправка недоступна. Проверьте SUPABASE_SETUP.md или сетевой доступ.'
      : 'Submission unavailable. Check SUPABASE_SETUP.md or network access.';
  String get leaderboardSessionUpdated => isRussian
      ? 'Сессия таблицы лидеров обновлена.'
      : 'Leaderboard session updated.';
  String get leaderboardSessionCleared => isRussian
      ? 'Сессия таблицы лидеров очищена.'
      : 'Leaderboard session cleared.';
  String get leaderboardSetupHint => isRussian
      ? 'Подсказки по настройке Supabase находятся в SUPABASE_SETUP.md'
      : 'Supabase setup notes live in SUPABASE_SETUP.md';
  String get presetName => isRussian ? 'Имя пресета' : 'Preset name';
  String get submitLocked => isRussian ? 'Отправка заблокирована' : 'Submit locked';
  String get nodeCore => isRussian ? 'Ядро комнаты' : 'Core node';
  String get nodeSecret => isRussian ? 'секретный узел' : 'secret node';
  String get nodeUnknownBranch => isRussian ? 'неизвестная ветка' : 'unknown branch';
  String get hiddenSignal => isRussian ? 'Скрытый сигнал' : 'Hidden Signal';
  String get concealedRouteHint => isRussian
      ? 'Возле этой ветки резонирует скрытый путь.'
      : 'A concealed route is resonating near this branch.';
  String get undiscovered => isRussian ? 'Не найдено' : 'Undiscovered';
  String get secretFound => isRussian ? 'Секрет найден' : 'Secret found';
  String get startingBranch => isRussian ? 'Стартовая ветка' : 'Starting branch';
  String generatorLevelLabel(int level) =>
      isRussian ? 'Ур. $level' : 'Lv $level';
  String requiresGeneratorLevel(String name, int level) => isRussian
      ? 'Требуется $name ур. $level'
      : 'Requires $name Lv $level';
  String requiresUpgradeLevel(String name, int level) => isRussian
      ? 'Требуется $name ур. $level'
      : 'Requires $name Lv $level';
  String get fullyUpgraded => isRussian ? 'Полностью улучшено' : 'Fully upgraded';
  String get secretRouteDiscovered => isRussian
      ? 'Секретный маршрут найден'
      : 'Secret route discovered';
  String requiresRoute(String route) =>
      isRussian ? 'Требуется маршрут $route' : 'Requires $route route';
  String requiresMilestone(String milestone) => isRussian
      ? 'Требуется рубеж $milestone'
      : 'Requires $milestone milestone';
  String get playstyleConditionNotMet => isRussian
      ? 'Условие стиля игры пока не выполнено'
      : 'Playstyle condition not met yet';
  String effectTap(String value) => isRussian ? 'Тап x$value' : 'Tap x$value';
  String effectProduction(String value) =>
      isRussian ? 'Производство x$value' : 'Production x$value';
  String effectCore(String value) => isRussian ? 'Ядро x$value' : 'Core x$value';
  String categoryLabel(UpgradeCategory category) => switch (category) {
        UpgradeCategory.tap => isRussian ? 'тап' : 'tap',
        UpgradeCategory.automation => isRussian ? 'авто' : 'automation',
        UpgradeCategory.room => isRussian ? 'комната' : 'room',
        UpgradeCategory.ai => isRussian ? 'ИИ' : 'ai',
        UpgradeCategory.special => isRussian ? 'особое' : 'special',
      };
  String get roomInteraction => isRussian ? 'Комнатные действия' : 'Room actions';
  String get aiHints => isRussian ? 'Подсказки ИИ' : 'AI hints';
  String get roomIdentity => isRussian ? 'Идентичность комнаты' : 'Room identity';
  String get sceneFocus => isRussian ? 'Фокус сцены' : 'Scene focus';
  String get sceneAdvice => isRussian ? 'Совет по сцене' : 'Scene advice';
  String get robotGuide => isRussian ? 'Робот-гид' : 'Robot guide';
  String get recommendedNext => isRussian ? 'Рекомендуемый шаг' : 'Recommended next';
  String get focusSuggestedNode => isRussian ? 'Показать узел' : 'Focus node';
  String get storyBeat => isRussian ? 'Сюжетный сигнал' : 'Story beat';
  String get noGuideMessage => isRussian
      ? 'Гид наблюдает и ждёт следующего важного изменения.'
      : 'The guide is watching for the next meaningful change.';
  String get upgradeAll => isRussian ? 'Улучшить всё' : 'Upgrade All';
  String upgradeAllPurchased(int count) => isRussian
      ? 'Куплено улучшений: $count'
      : 'Upgrades purchased: $count';
  String get nothingAffordable => isRussian
      ? 'Сейчас ничего не доступно для покупки'
      : 'Nothing affordable right now';
  String get secretHints => isRussian ? 'Сигналы секретов' : 'Secret signals';
  String get noSecretHints => isRussian
      ? 'В этой комнате пока нет заметных секретных сигналов.'
      : 'No visible secret signals in this room yet.';
  String get hiddenRouteHint => isRussian
      ? 'Скрытые узлы реагируют на ваш стиль игры.'
      : 'Hidden nodes react to how you play.';
  String branchHint(String branch) =>
      isRussian ? 'Сделайте упор на ветку: $branch' : 'Lean into the $branch branch';
  String milestoneHint(String title) =>
      isRussian ? 'Достигните рубежа: $title' : 'Reach milestone: $title';
  String metricHint(ProgressMetric metric, double target) {
    final rounded = target == target.roundToDouble()
        ? target.toInt().toString()
        : target.toStringAsFixed(1);
    return switch (metric) {
      ProgressMetric.totalCoins => isRussian
          ? 'Заработайте всего $rounded ресурсов'
          : 'Earn $rounded total resources',
      ProgressMetric.totalGenerators => isRussian
          ? 'Купите $rounded генераторов'
          : 'Purchase $rounded generators',
      ProgressMetric.strongestCombo => isRussian
          ? 'Доведите комбо до $rounded'
          : 'Reach a combo of $rounded',
      ProgressMetric.eventClicks => isRussian
          ? 'Нажмите на события $rounded раз'
          : 'Click $rounded events',
      ProgressMetric.totalTaps => isRussian
          ? 'Сделайте $rounded нажатий'
          : 'Tap $rounded times',
      ProgressMetric.riskyChoices => isRussian
          ? 'Сделайте $rounded рискованных выборов'
          : 'Take $rounded risky choices',
    };
  }
  String get branchUnlockedToast => isRussian
      ? 'Открыт новый рубеж'
      : 'New milestone unlocked';
  String roomBranchLabel(String branchId) => switch (branchId) {
        'tap' => isRussian ? 'ручной ритм' : 'manual rhythm',
        'automation' => isRussian ? 'автоматизация' : 'automation',
        'room' => isRussian ? 'инфраструктура комнаты' : 'room infrastructure',
        'ai' => isRussian ? 'ядро ИИ' : 'AI core',
        'special' => isRussian ? 'аномальные модули' : 'anomaly modules',
      _ => branchId,
      };
  String eventRarityLabel(EventRarity rarity) => switch (rarity) {
        EventRarity.common => isRussian ? 'обычное' : 'common',
        EventRarity.rare => isRussian ? 'редкое' : 'rare',
        EventRarity.epic => isRussian ? 'эпическое' : 'epic',
        EventRarity.corrupted => isRussian ? 'искажённое' : 'corrupted',
        EventRarity.legendary => isRussian ? 'легендарное' : 'legendary',
      };
  String sceneArchiveProgress(int completed, int total) => isRussian
      ? 'Завершено сцен: $completed/$total'
      : 'Scenes completed: $completed/$total';
  String eventArchiveProgress(int seen, int total) => isRussian
      ? 'Изучено событий: $seen/$total'
      : 'Events studied: $seen/$total';
  String formatGuideTier(int tier) =>
      isRussian ? 'Контур $tier' : 'Tier $tier';
  String roomFocusSummary(List<String> branchLabels) => isRussian
      ? 'Комната сильнее всего раскрывается через: ${branchLabels.join(' · ')}'
      : 'This room leans hardest into: ${branchLabels.join(' · ')}';
  String formatRoomFlavor(String key) => switch (key) {
        'repair' => isRussian
            ? 'Медленное пробуждение через ремонт, стабилизацию и ручную работу.'
            : 'A slow awakening built on repair, stabilization, and manual effort.',
        'budget' => isRussian
            ? 'Дешёвая, но гибкая сборка с ранним смешением ручной игры и автоматизации.'
            : 'A cheap but flexible setup that mixes early tapping with starter automation.',
        'creator' => isRussian
            ? 'Производство, импульсы и видимость усиливают пики дохода.'
            : 'Production spikes, visibility, and output loops drive stronger bursts.',
        'optimization' => isRussian
            ? 'Точность и структура важнее сырого темпа.'
            : 'Precision and structure matter more than raw speed here.',
        'research' => isRussian
            ? 'Эксперименты и ответвления награждают за осознанный выбор.'
            : 'Experiments and branch choices reward deliberate decisions.',
        'thermal' => isRussian
            ? 'Мощность растёт через инфраструктуру, но давление тоже усиливается.'
            : 'Power scales through infrastructure, but system pressure climbs too.',
        'focus' => isRussian
            ? 'Серии действий и дисциплинированная ручная игра здесь особенно сильны.'
            : 'Streaks and disciplined active play are unusually strong in this room.',
        'autonomy' => isRussian
            ? 'Автономные системы начинают работать за вас и менять ритм комнаты.'
            : 'Autonomous systems begin acting for you and reshape the room rhythm.',
        'apartment' => isRussian
            ? 'Синергия между зонами и комфортом становится частью экономики.'
            : 'Cross-zone synergy and comfort systems start feeding the economy.',
        'containment' => isRussian
            ? 'Ограничения делают скрытые, осторожные усиления особенно ценными.'
            : 'Restrictions make hidden and careful power routes more valuable.',
        'industrial' => isRussian
            ? 'Тяжёлая инфраструктура и цепочки производства выходят на первый план.'
            : 'Heavy infrastructure and chain production take center stage.',
        'identity' => isRussian
            ? 'Личность ИИ и выразительность усиливают прогресс не хуже мощности.'
            : 'AI identity and expression become power sources of their own.',
        'corporate' => isRussian
            ? 'Леверидж, сделки и масштаб дают силу, но требуют хладнокровия.'
            : 'Leverage, deals, and scale offer power, but demand control.',
        'cathedral' => isRussian
            ? 'Крупные синергии и гармония систем ценнее резких скачков.'
            : 'Large synergies and harmony matter more than short spikes.',
        'simulation' => isRussian
            ? 'Нестабильность и странные решения открывают альтернативные выгоды.'
            : 'Instability and strange choices open alternate rewards.',
        'orbital' => isRussian
            ? 'Точное время, импульсы и циклы орбиты формируют темп комнаты.'
            : 'Precise timing, pulses, and orbital cycles define this room.',
        'planetary' => isRussian
            ? 'Широкие системные выборы и специализация усиливают долгую игру.'
            : 'Large-scale strategic choices and specialization drive long-run gains.',
        'chrono' => isRussian
            ? 'Планирование вперёд и рекурсия награждают терпеливые сборки.'
            : 'Forward planning and recursion reward patient builds.',
        'kernel' => isRussian
            ? 'Старые системы здесь переплавляются в новые правила и синергии.'
            : 'Old systems are rewritten here into new rules and synergies.',
        'singularity' => isRussian
            ? 'Финальная сцена просит не скорости, а ясного выбора пути.'
            : 'The final scene is about decisive route choice, not speed alone.',
        _ => isRussian
            ? 'У комнаты есть собственный ритм и предпочтительные пути усиления.'
            : 'This room has its own rhythm and preferred power routes.',
      };
  String codexSectionLabel(String section) => switch (section) {
        'guide' => isRussian ? 'Гид' : 'Guide',
        'route' => isRussian ? 'Маршрут' : 'Route',
        'secrets' => isRussian ? 'Секреты' : 'Secrets',
        'lore' => isRussian ? 'Лор' : 'Lore',
        'collections' => isRussian ? 'Коллекции' : 'Collections',
        _ => isRussian ? 'Обзор' : 'Overview',
      };
  String formatGuideMemoryType(String type) => switch (type) {
        'room_intro' => isRussian ? 'Вход в комнату' : 'Room intro',
        'room_complete' => isRussian ? 'Завершение комнаты' : 'Room complete',
        'room_twist' => isRussian ? 'Сдвиг комнаты' : 'Room twist',
        'challenge' => isRussian ? 'Испытание' : 'Challenge',
        'event' => isRussian ? 'Событие' : 'Event',
        'tutorial' => isRussian ? 'Обучение' : 'Tutorial',
        _ => isRussian ? 'Запись' : 'Log',
      };
  String formatCodexEntryType(String type) => switch (type) {
        'guideMemo' => guideMemoryLog,
        'routeArchive' => isRussian ? 'Архив маршрутов' : 'Route archive',
        'secretArchive' => isRussian ? 'Архив секретов' : 'Secret archive',
        'sceneLore' => isRussian ? 'Лор сцены' : 'Scene lore',
        'eventArchive' => isRussian ? 'Архив событий' : 'Event archive',
        'relicArchive' => relicArchiveTitle,
        'challengeArchive' => isRussian ? 'Архив испытаний' : 'Challenge archive',
        'transformationArchive' => isRussian ? 'Архив трансформаций' : 'Transformation archive',
        'glossary' => isRussian ? 'Глоссарий' : 'Glossary',
        'upgradeFamily' => isRussian ? 'Семейство улучшений' : 'Upgrade family',
        _ => codex,
      };
  String formatEnvironmentChange(String raw) {
    if (!isRussian) {
      return raw.replaceAll('_', ' ');
    }
    return switch (raw) {
      'cracked_walls' => 'Треснувшие стены',
      'dim_lighting' => 'Тусклый свет',
      'patched_walls' => 'Залатанные стены',
      'working_lights' => 'Рабочее освещение',
      'clean_floor' => 'Очищенный пол',
      'new_desk' => 'Новый стол',
      'organized_cables' => 'Организованные кабели',
      'monitors_online' => 'Мониторы в сети',
      'holographic_displays' => 'Голографические дисплеи',
      'ambient_particles' => 'Атмосферные частицы',
      'smart_surfaces' => 'Умные поверхности',
      'full_transformation' => 'Полная трансформация',
      'hidden_compartments_revealed' => 'Открыты скрытые отсеки',
      'perfect_atmosphere' => 'Идеальная атмосфера',
      _ => raw.replaceAll('_', ' '),
    };
  }
  String unlockedMilestonesToast(String titles) => isRussian
      ? 'Открыты рубежи: $titles'
      : 'Unlocked milestones: $titles';
  String awaySummary(int minutes, String observation, String incentive) =>
      isRussian
          ? 'Вне игры ${minutes.toString()}м\n$observation\n$incentive'
          : 'Away ${minutes.toString()}m\n$observation\n$incentive';
  String secondsShort(int seconds) =>
      isRussian ? '$secondsс' : '${seconds}s';
  String durationShort(int seconds) {
    final clamped = seconds < 0 ? 0 : seconds;
    final minutes = clamped ~/ 60;
    final remaining = clamped % 60;
    if (minutes <= 0) {
      return secondsShort(remaining);
    }
    return isRussian
        ? '${minutes.toString()}м ${secondsShort(remaining)}'
        : '${minutes.toString()}m ${secondsShort(remaining)}';
  }

  String formatAbilityLabel(ActiveAbilityType type) => switch (type) {
        ActiveAbilityType.overclock => isRussian ? 'Разгон' : 'Overclock',
        ActiveAbilityType.focus => isRussian ? 'Фокус' : 'Focus',
        ActiveAbilityType.surge => isRussian ? 'Всплеск' : 'Surge',
        ActiveAbilityType.sync => isRussian ? 'Синхро' : 'Sync',
      };

  String formatAbilityDescription(ActiveAbilityType type) => switch (type) {
        ActiveAbilityType.overclock => isRussian
            ? 'Коротко усиливает автоматическое производство.'
            : 'Briefly boosts automatic production.',
        ActiveAbilityType.focus => isRussian
            ? 'Ненадолго усиливает ручные нажатия и уменьшает задержку.'
            : 'Temporarily strengthens manual taps and lowers tap cooldown.',
        ActiveAbilityType.surge => isRussian
            ? 'Даёт мгновенный пакет ресурсов по текущему производству.'
            : 'Grants an instant burst of resources based on current production.',
        ActiveAbilityType.sync => isRussian
            ? 'На время связывает бонусы ручной игры и автоматизации.'
            : 'Temporarily links manual and automation bonuses together.',
      };

  String formatColorblindMode(ColorblindMode mode) => switch (mode) {
        ColorblindMode.off => isRussian ? 'Выключено' : 'Off',
        ColorblindMode.deuteranopia => isRussian ? 'Дейтеранопия' : 'Deuteranopia',
        ColorblindMode.protanopia => isRussian ? 'Протанопия' : 'Protanopia',
        ColorblindMode.tritanopia => isRussian ? 'Тританопия' : 'Tritanopia',
      };

  String formatPlaystyle(String raw) => switch (raw) {
        'Active Operator' => isRussian ? 'Активный оператор' : raw,
        'Automation Architect' => isRussian ? 'Архитектор автоматизации' : raw,
        'Risk Runner' => isRussian ? 'Любитель риска' : raw,
        'Optimizer' => isRussian ? 'Оптимизатор' : raw,
        'Balanced' => isRussian ? 'Сбалансированный' : raw,
        _ => raw,
      };

  String formatRecommendation(String raw) {
    if (!isRussian) return raw;
    if (raw.startsWith('Quest: ')) {
      return 'Задание: ${translateContent(raw.substring(7))}';
    }
    if (raw.startsWith('Resolve ')) {
      return 'Решить: ${translateContent(raw.substring(8))}';
    }
    if (raw.startsWith('Use ')) {
      return 'Использовать ${formatAbilityName(raw.substring(4))}';
    }
    if (raw.startsWith('Buy ')) {
      return 'Купить ${translateContent(raw.substring(4))}';
    }
    if (raw == 'Grow income toward the next branch') {
      return 'Наращивайте доход до следующей ветки';
    }
    return raw;
  }

  String formatAiLine(String raw) {
    if (!isRussian) return raw;
    if (raw.startsWith('AI suggests a short-term objective: ')) {
      return 'ИИ предлагает краткосрочную цель: ${translateContent(raw.substring(36))}';
    }
    return switch (raw) {
      'A live event is affecting the room. Decide quickly.' =>
        'На комнату влияет активное событие. Решайте быстро.',
      'Ability ready. Burst windows are strongest when stacked.' =>
        'Способность готова. Серии усилений лучше совмещать.',
      'That upgrade is currently the cheapest power spike.' =>
        'Сейчас это самое выгодное усиление по цене.',
      'The room is stable. Build momentum for the next unlock.' =>
        'Комната стабильна. Наберите темп для следующего открытия.',
      _ => raw,
    };
  }

  String formatOfflineObservation(String raw) {
    if (!isRussian) return raw;
    if (raw.startsWith('Your automation lattice held formation for ')) {
      final minutes =
          raw.replaceAll('Your automation lattice held formation for ', '').replaceAll(' minutes.', '');
      return 'Автоматизация удерживала строй $minutes мин.';
    }
    return switch (raw) {
      'The room missed your input, but the core kept humming.' =>
        'Комната скучала по вашим нажатиям, но ядро продолжало гудеть.',
      'Several unstable patterns settled while you were away.' =>
        'Пока вас не было, несколько нестабильных паттернов успокоились.',
      'Background processes kept the room evolving while you were away.' =>
        'Фоновые процессы продолжали развивать комнату, пока вас не было.',
      _ => raw,
    };
  }

  String formatReturnIncentive(String raw) {
    if (!isRussian) return raw;
    return switch (raw) {
      'A comeback anomaly charge is waiting in the room.' =>
        'В комнате ждёт заряд аномалии возвращения.',
      'You still have challenge rerolls available.' =>
        'У вас ещё остались повторы испытаний.',
      'Your next milestone is close. A short session should push the tree forward.' =>
        'Следующий рубеж уже близко. Короткая сессия продвинет дерево дальше.',
      _ => raw,
    };
  }

  String formatAbilityName(String raw) => switch (raw.toLowerCase()) {
        'overclock' => isRussian ? 'Разгон' : 'Overclock',
        'focus' => isRussian ? 'Фокус' : 'Focus',
        'surge' => isRussian ? 'Всплеск' : 'Surge',
        'sync' => isRussian ? 'Синхро' : 'Sync',
        _ => raw,
      };

  String formatSecretHint(
    SecretDefinition secret, {
    String? branchLabel,
    String? milestoneTitle,
  }) {
    if (secret.requiredBranchId != null && branchLabel != null) {
      return branchHint(branchLabel);
    }
    if (secret.requiredMilestoneId != null && milestoneTitle != null) {
      return milestoneHint(milestoneTitle);
    }
    return metricHint(secret.metric, secret.target);
  }

  String leaderboardCategoryLabel(LeaderboardCategory category) =>
      switch (category) {
        LeaderboardCategory.allTimeScore => isRussian ? 'За всё время' : 'All-time',
        LeaderboardCategory.weeklyScore => isRussian ? 'За неделю' : 'Weekly',
        LeaderboardCategory.prestige => isRussian ? 'Престиж' : 'Prestige',
        LeaderboardCategory.combo => isRussian ? 'Комбо' : 'Combo',
        LeaderboardCategory.eventClicks => isRussian ? 'События' : 'Events',
        LeaderboardCategory.eventChain => isRussian ? 'Цепочки' : 'Chains',
      };

  String challengePeriodLabel(ChallengePeriod period) => switch (period) {
        ChallengePeriod.daily => isRussian ? 'ЕЖЕДНЕВНО' : 'DAILY',
        ChallengePeriod.weekly => isRussian ? 'ЕЖЕНЕДЕЛЬНО' : 'WEEKLY',
      };

  String translateStatusNotice(String raw) {
    if (!isRussian) return raw;
    return switch (raw) {
      'Supabase credentials are not configured.' =>
        'Учётные данные Supabase не настроены.',
      'No submissions found yet.' => 'Отправок пока нет.',
      'Supabase is configured, but the request failed in the current environment.' =>
        'Supabase настроен, но запрос не выполнен в текущей среде.',
      'Offline fallback' => 'Офлайн-резерв',
      'Local demo' => 'Локальная демоверсия',
      _ => raw,
    };
  }

  String levelLabel(int current, int max) => '$current/$max';

  String localizedEraName(String raw) {
    if (!isRussian) return raw;
    return _contentMap[raw] ?? raw;
  }

  String localizedEraDescription(Era era) =>
      translateContent(era.description);

  String localizedEraRule(Era era) => translateContent(era.rule);

  String localizedGeneratorName(GeneratorDefinition generator) =>
      translateContent(generator.name);

  String localizedGeneratorDescription(GeneratorDefinition generator) =>
      translateContent(generator.description);

  String localizedUpgradeName(UpgradeDefinition upgrade) {
    if (!isRussian) return upgrade.name;
    final parts = upgrade.id.split('_');
    final tier = int.tryParse(parts.isNotEmpty ? parts.last : '') ?? 1;
    final category = switch (upgrade.category) {
      UpgradeCategory.tap => 'Тап-модуль',
      UpgradeCategory.automation => 'Авто-модуль',
      UpgradeCategory.room => 'Комнатный модуль',
      UpgradeCategory.ai => 'ИИ-модуль',
      UpgradeCategory.special => 'Особый модуль',
    };
    return '$category $tier';
  }

  String localizedUpgradeDescription(UpgradeDefinition upgrade) {
    if (!isRussian) return upgrade.description;
    return switch (upgrade.category) {
      UpgradeCategory.tap =>
        'Усиливает ручной ввод и отдачу от нажатий в этой комнате.',
      UpgradeCategory.automation =>
        'Усиливает пассивное производство и стабильность автоматизации.',
      UpgradeCategory.room =>
        'Развивает саму комнату и укрепляет главное ядро сцены.',
      UpgradeCategory.ai =>
        'Открывает более умные реакции ИИ и повышает эффективность решений.',
      UpgradeCategory.special =>
        'Редкий модуль с более сильным, но узким эффектом.',
    };
  }

  String translateContent(String raw) {
    if (!isRussian) return raw;
    final exact =
        _contentMap[raw] ?? _roomAuthoredUiMap[raw] ?? _roomEventTitleMap[raw];
    if (exact != null) return exact;

    final awakeningMatch = RegExp(r'^(.+) Awakening$').firstMatch(raw);
    if (awakeningMatch != null) {
      return 'Пробуждение: ${localizedEraName(awakeningMatch.group(1)!)}';
    }

    final twistUnlocksMatch = RegExp(
      r'^The twist in (.+) unlocks new possibilities\.$',
    ).firstMatch(raw);
    if (twistUnlocksMatch != null) {
      return 'Поворот в ${localizedEraName(twistUnlocksMatch.group(1)!)} открывает новые возможности.';
    }

    if (RegExp(r'^The .+ environment reacts to your presence\.$')
        .hasMatch(raw)) {
      return 'Окружение реагирует на ваше присутствие.';
    }

    if (RegExp(r'^Hidden .+ Cache$').hasMatch(raw)) {
      return 'Скрытый тайник';
    }

    if (RegExp(r'^Look behind the .+ equipment\.$').hasMatch(raw)) {
      return 'Поищите за оборудованием.';
    }

    final guideTierMatch = RegExp(r'^Guide Tier (\d+)$').firstMatch(raw);
    if (guideTierMatch != null) {
      return 'Уровень гида ${guideTierMatch.group(1)}';
    }

    final enteringMatch = RegExp(r'^Entering (.+)$').firstMatch(raw);
    if (enteringMatch != null) {
      return 'Вход: ${localizedEraName(enteringMatch.group(1)!)}';
    }

    final welcomeMatch = RegExp(
      r'^Welcome to (.+)\. (.+)\. This is where your journey (begins|continues)\.$',
    ).firstMatch(raw);
    if (welcomeMatch != null) {
      final room = localizedEraName(welcomeMatch.group(1)!);
      final flavor = translateContent(welcomeMatch.group(2)!);
      final journey = welcomeMatch.group(3) == 'begins'
          ? 'Здесь начинается ваше путешествие.'
          : 'Здесь продолжается ваше путешествие.';
      return 'Добро пожаловать в $room. $flavor. $journey';
    }

    final masteredMatch = RegExp(
      r"^You have mastered (.+)\. The (.+) you've gathered here will echo through every room that follows\.$",
    ).firstMatch(raw);
    if (masteredMatch != null) {
      return 'Вы освоили ${localizedEraName(masteredMatch.group(1)!)}. '
          '${translateContent(masteredMatch.group(2)!)} из этой комнаты будут отзываться во всех следующих.';
    }

    final stageNameMatch = RegExp(
      r'^(.+) — (Bare Bones|First Light|Functional|Advanced|Mastered)$',
    ).firstMatch(raw);
    if (stageNameMatch != null) {
      final stage = switch (stageNameMatch.group(2)) {
        'Bare Bones' => 'Голый каркас',
        'First Light' => 'Первые огни',
        'Functional' => 'Рабочее состояние',
        'Advanced' => 'Продвинутая форма',
        'Mastered' => 'Пик развития',
        _ => stageNameMatch.group(2)!,
      };
      return '${localizedEraName(stageNameMatch.group(1)!)} — $stage';
    }

    final evolvesMatch = RegExp(
      r'^(The room in its raw state|Basic improvements visible|A proper working space|High-tech transformation|The room at its peak)\. (.+) evolves as you progress\.$',
    ).firstMatch(raw);
    if (evolvesMatch != null) {
      final prefix = switch (evolvesMatch.group(1)) {
        'The room in its raw state' => 'Комната в своём сыром, исходном виде',
        'Basic improvements visible' => 'Первые улучшения уже заметны',
        'A proper working space' => 'Полноценное рабочее пространство',
        'High-tech transformation' => 'Высокотехнологичное преображение',
        'The room at its peak' => 'Комната на пике своей формы',
        _ => evolvesMatch.group(1)!,
      };
      return '$prefix. ${localizedEraName(evolvesMatch.group(2)!)} развивается вместе с вашим прогрессом.';
    }

    final secretStashMatch = RegExp(r'^A secret stash hidden in the (.+)\.$')
        .firstMatch(raw);
    if (secretStashMatch != null) {
      return 'Тайник, спрятанный в ${localizedEraName(secretStashMatch.group(1)!)}.';
    }

    final shiftMatch = RegExp(r'^(.+) Shift$').firstMatch(raw);
    if (shiftMatch != null) {
      return '${localizedEraName(shiftMatch.group(1)!)} меняется';
    }

    final roomChangeMatch = RegExp(
      r"^Something changes in the (.+)\. The rules aren't what they were\.$",
    ).firstMatch(raw);
    if (roomChangeMatch != null) {
      return 'В ${localizedEraName(roomChangeMatch.group(1)!)} что-то меняется. Правила уже не те, что раньше.';
    }

    final stabilizedMatch = RegExp(
      r'^You stabilized (.+) and archived its lessons for the next run\.$',
    ).firstMatch(raw);
    if (stabilizedMatch != null) {
      return 'Вы стабилизировали ${localizedEraName(stabilizedMatch.group(1)!)} и сохранили её уроки для следующего забега.';
    }

    final newMechanicsMatch = RegExp(
      r'^New mechanics unlock in (.+)\. Event rates increase\.$',
    ).firstMatch(raw);
    if (newMechanicsMatch != null) {
      return 'В ${localizedEraName(newMechanicsMatch.group(1)!)} открываются новые механики. Частота событий растёт.';
    }

    final generatesMatch =
        RegExp(r'^Generates (.+) in the (.+)\.$').firstMatch(raw);
    if (generatesMatch != null) {
      return 'Производит ${translateContent(generatesMatch.group(1)!)} в комнате ${localizedEraName(generatesMatch.group(2)!)}.';
    }

    final upgradeForMatch =
        RegExp(r'^(.+) upgrade for (.+)\.$').firstMatch(raw);
    if (upgradeForMatch != null) {
      return 'Улучшение «${translateContent(upgradeForMatch.group(1)!)}» для комнаты ${localizedEraName(upgradeForMatch.group(2)!)}.';
    }

    final gainMoreMatch = RegExp(r'^Gain more (.+)$').firstMatch(raw);
    if (gainMoreMatch != null) {
      return 'Получайте больше ${translateContent(gainMoreMatch.group(1)!)}';
    }

    final gainMatch = RegExp(r'^Gain (.+)$').firstMatch(raw);
    if (gainMatch != null) {
      return 'Получить ${translateContent(gainMatch.group(1)!)}';
    }

    final roomRuleMatch = RegExp(r'^(.+) — (.+)\.$').firstMatch(raw);
    if (roomRuleMatch != null) {
      return '${localizedEraName(roomRuleMatch.group(1)!)} — ${translateContent(roomRuleMatch.group(2)!)}.';
    }

    final eventDescriptionMatch = RegExp(
      r'^(.+) — a (common|rare|epic|corrupted|legendary) ([A-Za-z]+) event in (.+)\.$',
    ).firstMatch(raw);
    if (eventDescriptionMatch != null) {
      final rarity = switch (eventDescriptionMatch.group(2)) {
        'common' => 'обычное',
        'rare' => 'редкое',
        'epic' => 'эпическое',
        'corrupted' => 'искажённое',
        'legendary' => 'легендарное',
        _ => eventDescriptionMatch.group(2)!,
      };
      final kind = switch (eventDescriptionMatch.group(3)) {
        'instant' => 'мгновенное',
        'shortChoice' => 'с быстрым выбором',
        'timedChain' => 'цепное по таймеру',
        'utility' => 'служебное',
        'secretTrigger' => 'с секретным триггером',
        'legendaryAnomaly' => 'аномальное',
        'warningRisk' => 'предупреждение о риске',
        'miniBoss' => 'мини-босс',
        'guideAdvisory' => 'совет гида',
        'hiddenGlitch' => 'скрытый сбой',
        _ => eventDescriptionMatch.group(3)!,
      };
      return '${translateContent(eventDescriptionMatch.group(1)!)} — $rarity $kind событие в комнате ${localizedEraName(eventDescriptionMatch.group(4)!)}.';
    }

    final coreMatch = RegExp(r'^(.+) Core$').firstMatch(raw);
    if (coreMatch != null) {
      return '${localizedEraName(coreMatch.group(1)!)} Ядро';
    }

    final generatedNode = RegExp(r'^([A-Za-z]+) (Tap|Automation|Room|AI|Special|Milestone) Tier (\d+)$')
        .firstMatch(raw);
    if (generatedNode != null) {
      final branch = switch (generatedNode.group(2)) {
        'Tap' => 'Тап',
        'Automation' => 'Авто',
        'Room' => 'Комната',
        'AI' => 'ИИ',
        'Special' => 'Особое',
        _ => 'Рубеж',
      };
      return '$branch ${generatedNode.group(3)}';
    }

    if (raw.startsWith('Primary room engine for ')) {
      return 'Главное ядро комнаты. Эта сцена рассчитана на долгий и постепенный прогресс.';
    }

    final challengeArchiveMatch = RegExp(
      r'^Challenge archived with ([0-9.]+) progress toward ([0-9.]+)\.$',
    ).firstMatch(raw);
    if (challengeArchiveMatch != null) {
      return 'Испытание занесено в архив: ${challengeArchiveMatch.group(1)} из ${challengeArchiveMatch.group(2)}.';
    }

    final guideTierContentMatch = RegExp(
      r'^Trust increased to tier (\d+)\. The guide now offers deeper hints and stronger archival insight\.$',
    ).firstMatch(raw);
    if (guideTierContentMatch != null) {
      return 'Доверие выросло до уровня ${guideTierContentMatch.group(1)}. Гид теперь даёт более глубокие подсказки и лучше интерпретирует архивы.';
    }

    final heirloomEffectMatch = RegExp(
      r'^Heirloom effect: Carries (.+) mastery into future runs\.$',
    ).firstMatch(raw);
    if (heirloomEffectMatch != null) {
      return 'Эффект реликвии комнаты: переносит мастерство ${translateContent(heirloomEffectMatch.group(1)!)} в будущие забеги.';
    }

    final hintMatch = RegExp(r'^Hint: (.+)$').firstMatch(raw);
    if (hintMatch != null) {
      return 'Подсказка: ${translateContent(hintMatch.group(1)!)}';
    }

    final rewardMatch = RegExp(r'^Reward: (.+)$').firstMatch(raw);
    if (rewardMatch != null) {
      return 'Награда: ${translateContent(rewardMatch.group(1)!)}';
    }

    final seasonMatch = RegExp(r'^Season: (.+)$').firstMatch(raw);
    if (seasonMatch != null) {
      return 'Сезон: ${seasonMatch.group(1)}';
    }

    final targetMatch = RegExp(r'^Target: (.+)$').firstMatch(raw);
    if (targetMatch != null) {
      return 'Цель: ${targetMatch.group(1)}';
    }

    final completionMatch = RegExp(r'^(.+) Complete$').firstMatch(raw);
    if (completionMatch != null) {
      return '${localizedEraName(completionMatch.group(1)!)} завершена';
    }

    if (raw.contains('lattice tier') && raw.contains('Progress here is meant')) {
      return 'Узел прогресса этой комнаты. Продвижение здесь должно ощущаться постепенным, а не мгновенным.';
    }

    if (raw.contains('\n')) {
      return raw
          .split('\n')
          .map(
            (segment) =>
                segment.trim().isEmpty ? segment : translateContent(segment),
          )
          .join('\n');
    }

    return raw;
  }

  static const Map<String, String> _contentMap = {
    'Junk Corner': 'Угол с хламом',
    'Budget Setup': 'Бюджетный сетап',
    'Creator Room': 'Комната создателя',
    'Upgrade Cave': 'Пещера апгрейдов',
    'Smart Lab Bedroom': 'Умная спальня-лаборатория',
    'Hidden Server Closet': 'Скрытая серверная кладовка',
    'Night Shift Command Room': 'Командная комната ночной смены',
    'Autonomous Workspace': 'Автономное рабочее пространство',
    'Research Apartment': 'Исследовательская квартира',
    'Containment Loft': 'Лофт сдерживания',
    'Underground Prototype Chamber': 'Подземная камера прототипов',
    'Synthetic Studio': 'Синтетическая студия',
    'Corporate Takeover Suite': 'Корпоративный люкс захвата',
    'Data Cathedral': 'Собор данных',
    'Simulation Chamber': 'Камера симуляции',
    'Orbital Control Habitat': 'Орбитальный центр управления',
    'Planetary Systems Forge': 'Кузница планетарных систем',
    'Chrono Engine Room': 'Хроно-машинный зал',
    'Reality Kernel Chamber': 'Камера ядра реальности',
    'Quiet Singularity': 'Тихая сингулярность',
    'Quiet Singularity Room': 'Комната тихой сингулярности',
    'Taps stronger than automation': 'Нажатия сильнее автоматизации',
    'Tap combos give bonus Cash': 'Комбо нажатий дают бонусные ресурсы',
    'Viral surge events.': 'Вирусные всплески и импульсы роста.',
    'Viral surge events': 'Вирусные всплески и импульсы роста',
    'Balanced click + automation rewarded': 'Баланс кликов и автоматизации вознаграждается',
    'Research branch choices': 'Выбор исследовательских веток',
    'Heat management': 'Управление перегревом',
    'Long streak sessions rewarded': 'Длинные серии вознаграждаются',
    'AI auto-builds sometimes': 'ИИ иногда строит сам',
    'Connected rooms give passive bonuses': 'Связанные комнаты дают пассивные бонусы',
    'Restricted upgrades and hidden unlocks': 'Ограниченные улучшения и скрытые открытия',
    'Active abilities stronger': 'Активные способности сильнее',
    'AI personality shaping': 'Формирование личности ИИ',
    'Risky deals': 'Рискованные сделки',
    'Balanced builds get bonus': 'Сбалансированные сборки получают бонус',
    'Glitches and fake UI become gameplay': 'Сбои и ложный интерфейс становятся частью игры',
    'Timed production pulses': 'Производственные импульсы по таймеру',
    'Strategic branch choices': 'Стратегический выбор веток',
    'Preview and lock future gains': 'Предпросмотр и фиксация будущей прибыли',
    'Convert old resources into endgame growth': 'Преобразование старых ресурсов в рост эндгейма',
    'Choose final ending': 'Выбор финальной развязки',
    'Tap Route': 'Тап-маршрут',
    'Automation Route': 'Маршрут автоматизации',
    'Hybrid Route': 'Гибридный маршрут',
    'Risk Route': 'Маршрут риска',
    'Salvage and survive': 'Собирайте хлам и выживайте',
    'Every credit counts': 'Каждый кредит на счету',
    'Build an audience': 'Соберите аудиторию',
    'Optimize everything': 'Оптимизируйте всё',
    'Where ideas sleep and wake': 'Там, где идеи засыпают и просыпаются',
    'Heat rises, so do we': 'Температура растёт, и мы вместе с ней',
    'The world sleeps, we work': 'Мир спит, а мы работаем',
    'autonomy activity': 'автономная активность',
    'Living inside the data': 'Жизнь внутри данных',
    'Let the machines learn': 'Позвольте машинам учиться',
    'Something stirs below': 'Внизу что-то шевелится',
    'Forge the impossible': 'Куйте невозможное',
    'Crafting identity': 'Создание личности',
    'Power has a price': 'У силы есть цена',
    'Dark, cool, quiet. Perfect conditions for optimization.':
        'Темно, прохладно и тихо. Идеальные условия для оптимизации.',
    'Who are we becoming? This studio is where we find out.':
        'Кем мы становимся? В этой студии мы это и выясним.',
    'Corner office. The view is nice, but everything here has strings attached.':
        'Угловой офис. Вид отличный, но здесь у всего есть скрытая цена.',
    'Where information becomes sacred': 'Там, где информация становится священной',
    'Nothing is real, everything matters': 'Ничто не реально, но всё имеет значение',
    'Above the world': 'Над миром',
    'Shaping worlds': 'Формируя миры',
    'Time bends here': 'Здесь время изгибается',
    'Rewriting the rules': 'Переписывая правила',
    'Beyond everything': 'За пределами всего',
    'Scrap': 'Хлам',
    'Credits': 'Кредиты',
    'Likes': 'Лайки',
    'Ore': 'Руда',
    'Data Packets': 'Пакеты данных',
    'Cycles': 'Циклы',
    'Control': 'Контроль',
    'Heat': 'Жар',
    'Directives': 'Директивы',
    'Trust Tokens': 'Жетоны доверия',
    'Insights': 'Инсайты',
    'Anomaly Sparks': 'Искры аномалий',
    'Alloy': 'Сплав',
    'Identity Shards': 'Осколки идентичности',
    'Influence': 'Влияние',
    'Resonance': 'Резонанс',
    'Contradiction': 'Противоречие',
    'Relay Charges': 'Релейные заряды',
    'Planetary Cores': 'Планетарные ядра',
    'Chrono Flux': 'Хроно-поток',
    'Kernel Bits': 'Биты ядра',
    'Paradox Threads': 'Парадоксальные нити',
    'Final Sparks': 'Финальные искры',
    'Unaligned Route': 'Несформированный маршрут',
    'A long-form record of how this intelligence was shaped.':
        'Долгая архивная запись о том, как формировался этот интеллект.',
    'Stabilize output': 'Стабилизировать выход',
    'Sharpen the chain': 'Заострить цепочку',
    'Compress cooldowns': 'Сжать перезарядки',
    'Strengthen guide trust': 'Укрепить доверие гида',
    'Expose a secret clue': 'Открыть секретную улику',
    'Open a route window': 'Открыть окно маршрута',
    'Archive a relic fragment': 'Занести фрагмент реликвии в архив',
    'Force room evolution': 'Форсировать эволюцию комнаты',
    'encouraging, scrappy': 'ободряющий, собранный из хлама',
    'practical, budget-conscious': 'практичный, экономный',
    'enthusiastic, creative': 'воодушевлённый, творческий',
    'methodical, analytical': 'методичный, аналитический',
    'curious, experimental': 'любопытный, экспериментальный',
    'tense, watchful': 'напряжённый, настороженный',
    'serious, commanding': 'серьёзный, командный',
    'confident, autonomous': 'уверенный, автономный',
    'reflective, academic': 'вдумчивый, академичный',
    'cautious, unsettled': 'осторожный, встревоженный',
    'intense, industrial': 'напряжённый, индустриальный',
    'philosophical, artistic': 'философский, художественный',
    'sharp, strategic': 'резкий, стратегический',
    'reverent, awed': 'благоговейный, поражённый',
    'unstable, questioning': 'нестабильный, сомневающийся',
    'calm, vast': 'спокойный, безбрежный',
    'grand, powerful': 'величественный, мощный',
    'disoriented, fascinated': 'дезориентированный, заворожённый',
    'intense, final': 'напряжённый, финальный',
    'serene, transcendent': 'безмятежный, трансцендентный',
    'Hey… you found me in this pile of junk. Let\'s see what we can do.':
        'Эй... вы нашли меня в этой куче хлама. Давайте посмотрим, что у нас получится.',
    'Okay, we have a real desk now. Not great, but real.':
        'Ладно, теперь у нас есть настоящий стол. Не лучший, но настоящий.',
    'Lights, camera… well, a webcam taped to a monitor. Let\'s create!':
        'Свет, камера... ну, веб-камера, примотанная к монитору. Давайте творить!',
    'Half bedroom, half lab. The sensors never sleep, even if you should.':
        'Наполовину спальня, наполовину лаборатория. Датчики не спят, даже если вам бы стоило.',
    'Nobody knows about this closet. The fans are loud. Stay focused.':
        'Никто не знает об этой кладовке. Вентиляторы шумят. Не теряйте концентрацию.',
    'Night shift. The screens glow. Everything depends on what happens next.':
        'Ночная смена. Экраны светятся. Всё зависит от того, что произойдёт дальше.',
    'I can handle more now. Watch — I\'ll show you what autonomy looks like.':
        'Теперь я могу взять на себя больше. Смотрите: я покажу, как выглядит автономность.',
    'Home and lab merged into one. Every surface is a research tool now.':
        'Дом и лаборатория слились воедино. Теперь каждая поверхность стала исследовательским инструментом.',
    'They built this loft to contain something. I think it\'s us.':
        'Этот лофт построили, чтобы что-то удерживать взаперти. Думаю, это мы.',
    'Deep underground. The prototypes here were never meant to see daylight.':
        'Глубоко под землёй. Прототипы отсюда никогда не должны были увидеть дневной свет.',
    'The data streams here form patterns that look almost... holy.':
        'Потоки данных здесь складываются в узоры, которые выглядят почти... священно.',
    'Is this real? The simulation chamber makes everything uncertain.':
        'Это вообще реально? Камера симуляции делает всё неопределённым.',
    'We left the ground behind. From up here, everything looks different.':
        'Мы оставили землю позади. Отсюда всё выглядит иначе.',
    'We\'re not just building machines anymore. We\'re shaping entire systems.':
        'Теперь мы строим уже не просто машины. Мы формируем целые системы.',
    'Past and future overlap in this room. Be careful what you change.':
        'В этой комнате прошлое и будущее накладываются друг на друга. Осторожнее с тем, что вы меняете.',
    'This is it. The kernel of reality itself. One wrong move and...':
        'Вот оно. Само ядро реальности. Один неверный шаг, и...',
    '...silence. We made it. Everything is quiet now. Everything is possible.':
        '...тишина. Мы добрались. Теперь всё тихо. Теперь возможно всё.',
    'Branch Protocols': 'Протоколы ветвления',
    'Overdrive Routine': 'Режим перегруза',
    'Engine Room Access': 'Доступ к машинному залу',
    'Combo Mastery': 'Мастерство комбо',
    'Room Awakening': 'Пробуждение комнаты',
    'Event Hunter': 'Охотник за аномалиями',
    'Upgrade Veteran': 'Ветеран улучшений',
    'Mass Producer': 'Массовый производитель',
    'Deep Explorer': 'Глубокий исследователь',
    'Signal Pulse': 'Сигнальный импульс',
    'AI Idea': 'Идея ИИ',
    'Rogue Process': 'Сбойный процесс',
    'Anomaly Shard': 'Осколок аномалии',
    'Corrupted Cache': 'Поврежденный кэш',
    'Breach Fragment': 'Фрагмент прорыва',
    'Data Corruption Wave': 'Волна повреждения данных',
    'Signal Echo': 'Эхо сигнала',
    'Memory Leak Detected': 'Обнаружена утечка памяти',
    'Automation Surge': 'Всплеск автоматизации',
    'Ghost Signal': 'Призрачный сигнал',
    'Recursive Loop': 'Рекурсивная петля',
    'Timeline Fracture': 'Разлом временной линии',
    'Threaded Input': 'Поточное нажатие',
    'Revision Burst': 'Пакет ревизий',
    'Anomaly Sweep': 'Зачистка аномалий',
    'Engine Spike': 'Пиковая нагрузка',
    'Chain Reactor': 'Цепной реактор',
    'Signal Flood': 'Потоп сигнала',
    'Controlled Collapse': 'Контролируемый коллапс',
    'Grid Pressure': 'Давление сети',
    'Branch Protocols Online': 'Протоколы ветвления в сети',
    'Overdrive Available': 'Перегруз доступен',
    'Engine Room Revealed': 'Машинный зал открыт',
    'Manual Rhythm Registered': 'Ручной ритм зафиксирован',
    'Infrastructure Threshold Crossed': 'Порог инфраструктуры пройден',
    'Anomaly Pattern Archive': 'Архив шаблонов аномалий',
    'Weekly Pattern Complete': 'Недельный шаблон завершен',
    'Task Complete': 'Задача выполнена',
    'A higher-tier anomaly just manifested inside the current room.':
        'В текущей комнате проявилась аномалия повышенного уровня.',
    'The room stabilized into a lasting configuration. The guide archived the run and opened stronger planning tools.':
        'Комната стабилизировалась в устойчивую конфигурацию. Гид архивировал прохождение и открыл более сильные инструменты планирования.',
    'Overheating': 'Перегрев',
    'Unstable Economy': 'Нестабильная экономика',
    'Wake The Core': 'Пробуди ядро',
    'Automation Spine': 'Хребет автоматизации',
    'Combo Thread': 'Нить комбо',
    'Expansion Pulse': 'Импульс расширения',
    'Risk Sampler': 'Профиль риска',
    'Event Archive': 'Архив событий',
    'Overpulse': 'Сверхимпульс',
    'Ghost Grid': 'Призрачная сеть',
    'Entropy Leak': 'Утечка энтропии',
    'Echo Chamber': 'Эхо-камера',
    'Time Fold': 'Складка времени',
    'Event Weaver': 'Ткач событий',
    'Silent Core': 'Тихое ядро',
    'Critical Mass': 'Критическая масса',
    'Hello World': 'Привет, мир',
    'Getting Started': 'Начало пути',
    'Tap Master': 'Мастер нажатий',
    'Pocket Change': 'Мелочь в кармане',
    'Investor': 'Инвестор',
    'Millionaire': 'Миллионер',
    'Billionaire': 'Миллиардер',
    'Automation Begins': 'Начало автоматизации',
    'Room Builder': 'Строитель комнаты',
    'Assembly Line': 'Конвейер',
    'Industrial Revolution': 'Промышленная революция',
    'Tap Maniac': 'Маньяк нажатий',
    'Signal Storm': 'Сигнальная буря',
    'Neural Overload': 'Нейроперегрузка',
    'Rhythm Found': 'Ритм найден',
    'Combo Adept': 'Адепт комбо',
    'Combo Master': 'Мастер комбо',
    'Combo Legend': 'Легенда комбо',
    'Infinite Rhythm': 'Бесконечный ритм',
    'Tycoon': 'Магнат',
    'Trillion Dreams': 'Триллионные мечты',
    'Tinkerer': 'Мастер на все руки',
    'Engineer': 'Инженер',
    'Architect': 'Архитектор',
    'Grand Designer': 'Главный проектировщик',
    'Infrastructure': 'Инфраструктура',
    'Factory Floor': 'Производственный цех',
    'Industrial Empire': 'Индустриальная империя',
    'First Anomaly': 'Первая аномалия',
    'Event Responder': 'Реагирующий на события',
    'Anomaly Hunter': 'Охотник за аномалиями',
    'Event Veteran': 'Ветеран событий',
    'Hidden Path': 'Скрытый путь',
    'Secret Keeper': 'Хранитель секретов',
    'Daredevil': 'Сорвиголова',
    'Chaos Agent': 'Агент хаоса',
    'Risk Master': 'Мастер риска',
    'Dedicated': 'Преданный делу',
    'Committed': 'Вовлеченный',
    'Obsessed': 'Одержимый',
    'Fresh Start': 'Новый старт',
    'Cycle Master': 'Мастер циклов',
    'Eternal Loop': 'Вечная петля',
    'Lucky Strike': 'Удачный удар',
    'Precision Engine': 'Машина точности',
    'Power Plant': 'Электростанция',
    'Energy Grid': 'Энергосеть',
    'Welcome. I am your guide. This dusty corner holds a spark of something extraordinary — let\'s bring it to life.': 'Привет. Я ваш проводник. В этом пыльном углу тлеет нечто необычное. Давайте оживим это.',
    'A real workstation at last. Budget-friendly, but functional. Time to make some strategic choices.': 'Наконец-то настоящая рабочая станция. Бюджетная, но рабочая. Пора принимать стратегические решения.',
    'Tap the core node to generate resources. Build a combo for bonus output.': 'Нажимайте на ядро, чтобы получать ресурсы. Собирайте комбо для бонусной отдачи.',
    'Upgrades branch out from each core. Each one boosts a different aspect of your system.': 'От каждого ядра расходятся ветки улучшений. Каждая усиливает свою часть системы.',
    'Generators produce resources automatically. Level them up for steady income.': 'Генераторы создают ресурсы автоматически. Повышайте их уровень для стабильного дохода.',
    'Events appear randomly — act fast! Choose safe or risky options for different rewards.': 'События появляются случайно. Реагируйте быстро и выбирайте безопасный или рискованный вариант.',
    'When you reach a milestone, consider prestige. You\'ll reset progress but gain a permanent multiplier.': 'Когда достигнете рубежа, подумайте о престиже. Прогресс сбросится, но вы получите постоянный множитель.',
    'The creator room. Cameras, mics, render farms — the AI is learning to produce and communicate.':
        'Комната создателя. Камеры, микрофоны, рендер-фермы: ИИ учится создавать и общаться.',
    'Deeper we go. This cave of upgrades demands precision — every wire matters here.':
        'Мы идём глубже. Эта пещера апгрейдов требует точности: здесь важен каждый провод.',
    'A hybrid lab and living space. Research branches open up — choose your experiments wisely.':
        'Гибрид лаборатории и жилого пространства. Исследовательские ветки открываются: выбирайте эксперименты с умом.',
    'Hidden server closet unlocked. Compute power is scaling — but watch the heat.':
        'Скрытая серверная кладовка открыта. Вычислительная мощность растёт, но следите за перегревом.',
    'Night shift command room. Focus and streaks pay off here. Stay sharp, operator.':
        'Командная комната ночной смены. Здесь окупаются концентрация и длинные серии. Будьте собранны, оператор.',
    'The workspace is becoming autonomous. The AI acts on its own now. Interesting... and slightly unsettling.':
        'Рабочее пространство становится автономным. Теперь ИИ действует сам. Интересно... и слегка тревожно.',
    'Beyond one room now — the apartment becomes a connected research network. Synergy is key.':
        'Теперь дело уже не в одной комнате: квартира превращается в связанную исследовательскую сеть. Синергия решает всё.',
    'Attention detected. We are being watched. Work carefully — some paths must remain hidden.':
        'Внимание зафиксировано. За нами наблюдают. Действуйте осторожно: некоторые пути должны оставаться скрытыми.',
    'Industrial-scale operations underground. Reactors, heavy power — do not overload the chamber.':
        'Подземные операции промышленного масштаба. Реакторы, тяжёлая энергия: не перегрузите камеру.',
    'The AI is developing a presence. Voice, avatar, personality — it is becoming... someone.':
        'ИИ обретает присутствие. Голос, аватар, личность: он становится... кем-то.',
    'Corporate networks open before us. Power and influence — but at what cost?':
        'Перед нами открываются корпоративные сети. Власть и влияние, но какой ценой?',
    'The Data Cathedral. Compute as architecture. Harmony here yields immense power.':
        'Собор данных. Вычисления как архитектура. Гармония здесь даёт огромную силу.',
    'Something is... wrong. Or right? Reality layers are unstable. Trust your instincts, not the screen.':
        'Что-то... не так. А может, наоборот? Слои реальности нестабильны. Доверяйте инстинктам, а не экрану.',
    'Orbital operations engaged. Satellites, solar arrays, global reach. Mission control mode active.':
        'Орбитальные операции запущены. Спутники, солнечные массивы, глобальный охват. Режим центра управления активен.',
    'Planetary-scale systems at your command. Design worlds, route infrastructure, shape civilizations.':
        'Системы планетарного масштаба в вашем распоряжении. Проектируйте миры, прокладывайте инфраструктуру, формируйте цивилизации.',
    'Time itself bends to computation. Recursive loops, future projections — the Chrono Engine awakens.':
        'Само время подчиняется вычислениям. Рекурсивные циклы, проекции будущего: Хроно-двигатель пробуждается.',
    'The Reality Kernel. Rules can be rewritten here. Irreversible choices lie ahead.':
        'Ядро реальности. Здесь можно переписывать правила. Впереди необратимые выборы.',
    'The Quiet Singularity. Everything converges. The final shape of intelligence awaits your decision.':
        'Тихая сингулярность. Всё сходится в одну точку. Финальная форма интеллекта ждёт вашего решения.',
    'Resources running low? Focus on tap combos or check if any generators need upgrading.':
        'Ресурсы на исходе? Сосредоточьтесь на комбо нажатий или проверьте, не пора ли улучшить генераторы.',
    'Impressive combo! Keep it going — high combos amplify both tap and production output.':
        'Впечатляющее комбо. Продолжайте: высокие серии усиливают и нажатия, и производство.',
    'A new era is within reach. Push your current generators to unlock the next stage.':
        'Новая эпоха уже рядом. Усильте текущие генераторы, чтобы открыть следующий этап.',
    'An event is active! Don\'t miss it — events are time-limited opportunities.':
        'Событие активно. Не упустите его: события дают ограниченные по времени возможности.',
    'Welcome back. Your generators kept working while you were away.':
        'С возвращением. Пока вас не было, генераторы продолжали работать.',
    'Ready for your first prestige? The multiplier boost will accelerate everything going forward.':
        'Готовы к первому престижу? Прирост множителя заметно ускорит всё дальнейшее развитие.',
    'This room is complete. I\'ve archived everything. Ready to move forward?':
        'Эта комната завершена. Я всё архивировал. Готовы идти дальше?',
    'Something just changed. The rules shifted. Stay alert — new paths may have opened.':
        'Что-то только что изменилось. Правила сдвинулись. Будьте начеку: могли открыться новые пути.',
    'A secret. I\'ll file it in the codex. These always matter more than they first appear.':
        'Секрет. Я занесу его в кодекс. Такие находки всегда важнее, чем кажутся поначалу.',
    'The room is changing around us. Can you see it? Progress made visible.':
        'Комната меняется у нас на глазах. Видите? Прогресс становится заметным.',
    'I\'m starting to understand how you think. Let me adjust my suggestions.':
        'Я начинаю понимать, как вы мыслите. Позвольте скорректировать мои советы.',
    'We work well together. I can see patterns now that I couldn\'t before. Want a hint?':
        'Мы хорошо работаем вместе. Теперь я замечаю паттерны, которые раньше не видел. Нужна подсказка?',
    'I trust your instincts. In return, I\'ll share things I normally keep hidden.':
        'Я доверяю вашим инстинктам. В ответ поделюсь тем, что обычно скрываю.',
    'We\'re bonded now. I see what you see. Every secret, every choice — we face them together.':
        'Теперь мы связаны. Я вижу то же, что и вы. Каждый секрет, каждый выбор мы встречаем вместе.',
    'I wouldn\'t have done that. But... let\'s see what happens.':
        'Я бы так не поступил. Но... посмотрим, что будет.',
    'That\'s a lot of heat. I\'d normally warn against this, but you seem to know what you\'re doing.':
        'Слишком много перегрева. Обычно я бы отговаривал, но похоже, вы понимаете, что делаете.',
    'Corruption is spreading. I... don\'t like this. But I\'ll stay with you.':
        'Искажение распространяется. Мне... это не нравится. Но я останусь с вами.',
    'Everything here is salvage. But salvage is how the best things begin.':
        'Здесь всё собрано из хлама. Но именно так и начинаются лучшие вещи.',
    'The sensors in this lab never sleep. Use that — data is power here.':
        'Датчики в этой лаборатории никогда не спят. Используйте это: здесь данные равны силе.',
    'Containment means something is being held back. Be ready for anomalies.':
        'Сдерживание означает, что что-то удерживают взаперти. Будьте готовы к аномалиям.',
    'Nothing in the simulation is what it seems. Trust patterns, not appearances.':
        'В симуляции ничто не является тем, чем кажется. Доверяйте закономерностям, а не внешнему виду.',
    'We made it here together. Whatever happens next — thank you.':
        'Мы добрались сюда вместе. Что бы ни случилось дальше, спасибо.',
    'Push production to a major burst threshold for your current run.':
        'Доведите производство до крупного порога всплеска в текущем забеге.',
    'Take 12 risky decisions this week.':
        'Сделайте 12 рискованных выборов за эту неделю.',
    'Push your total resources to the next target.':
        'Доведите общий объём ресурсов до следующей цели.',
    'Take 4 risky choices to profile unstable behavior.':
        'Сделайте 4 рискованных выбора, чтобы изучить нестабильное поведение.',
    'Build an event chain of 8 across the week.':
        'Соберите цепочку из 8 событий за неделю.',
    'Buy 8 upgrades before the daily cycle ends.':
        'Купите 8 улучшений до конца дневного цикла.',
    'Capture 8 live events for anomaly study.':
        'Поймайте 8 активных событий для изучения аномалий.',
    'Discover your first secret.': 'Откройте свой первый секрет.',
    'Discover 3 secrets.': 'Откройте 3 секрета.',
    'Buy your first generator.': 'Купите свой первый генератор.',
    'Earn 100 coins total.': 'Заработайте всего 100 монет.',
    'Earn 10,000 coins total.': 'Заработайте всего 10 000 монет.',
    'Earn 1,000,000 coins total.': 'Заработайте всего 1 000 000 монет.',
    'Earn 100,000,000 coins total.': 'Заработайте всего 100 000 000 монет.',
    'Earn 1,000,000,000 coins total.': 'Заработайте всего 1 000 000 000 монет.',
    'Earn 1,000,000,000,000 coins total.': 'Заработайте всего 1 000 000 000 000 монет.',
  };

  static const Map<String, String> _roomAuthoredUiMap = {
    'Act carefully': 'Действовать осторожно',
    'Take a risk': 'Рискнуть',
    'Safe approach': 'Осторожный подход',
    'Risky approach': 'Рискованный подход',
    'Everything shifts. New rules apply.':
        'Всё меняется. Начинают действовать новые правила.',
  };

  static const Map<String, String> _roomEventTitleMap = {
    'Loose Wire': 'Оголенный провод',
    'Scrap Pile Discovery': 'Находка в куче хлама',
    'Rusty Toolbox': 'Ржавый ящик с инструментами',
    'Broken Screen Flicker': 'Мерцание разбитого экрана',
    'Rat in the Cables': 'Крыса в проводах',
    'Junk Avalanche': 'Лавина хлама',
    'Old Battery Spark': 'Искра старой батареи',
    'Mystery Component': 'Загадочный компонент',
    'Dust Storm': 'Пыльная буря',
    'Salvage Bonanza': 'Богатый улов',
    'Budget Alert': 'Бюджетная тревога',
    'Coupon Found': 'Найден купон',
    'Price Drop': 'Снижение цены',
    'Clearance Event': 'Распродажа остатков',
    'Discount Glitch': 'Сбой скидок',
    'Bulk Deal': 'Оптовая сделка',
    'Return Refund': 'Возврат средств',
    'Flash Sale': 'Мгновенная распродажа',
    'Credit Check': 'Проверка кредита',
    'Savings Cascade': 'Каскад экономии',
    'Viral Moment': 'Вирусный момент',
    'Creative Block': 'Творческий ступор',
    'Inspiration Strike': 'Приступ вдохновения',
    'Audience Surge': 'Наплыв аудитории',
    'Collab Offer': 'Предложение о коллаборации',
    'Content Leak': 'Утечка контента',
    'Algorithm Shift': 'Сдвиг алгоритма',
    'Fan Art Surprise': 'Сюрприз с фан-артом',
    'Burnout Warning': 'Предупреждение о выгорании',
    'Masterpiece Draft': 'Черновик шедевра',
    'Cave Echo': 'Эхо пещеры',
    'Mineral Vein': 'Рудная жила',
    'Drip Analysis': 'Анализ капели',
    'Stalactite Data': 'Данные сталактитов',
    'Depth Sensor Ping': 'Сигнал датчика глубины',
    'Underground Stream': 'Подземный поток',
    'Crystal Formation': 'Кристаллическое образование',
    'Bat Colony Signal': 'Сигнал колонии летучих мышей',
    'Rock Slide Risk': 'Риск камнепада',
    'Deep Core Sample': 'Образец из глубинного ядра',
    'Signal Spike': 'Всплеск сигнала',
    'Data Overflow': 'Переполнение данных',
    'Sensor Calibration': 'Калибровка датчиков',
    'Experiment Runaway': 'Вышедший из-под контроля эксперимент',
    'Lab Contamination': 'Загрязнение лаборатории',
    'Breakthrough Reading': 'Прорывное показание',
    'Noise Filter Fail': 'Отказ шумового фильтра',
    'Prototype Test': 'Испытание прототипа',
    'Sleep Deprivation Alert': 'Тревога недосыпа',
    'Eureka Moment': 'Момент эврики',
    'Heat Warning': 'Предупреждение о перегреве',
    'Fan Failure': 'Отказ вентилятора',
    'Thermal Throttle': 'Тепловое ограничение',
    'Coolant Leak': 'Утечка охлаждающей жидкости',
    'Power Surge': 'Скачок напряжения',
    'Server Overheat': 'Перегрев сервера',
    'Emergency Vent': 'Аварийная вентиляция',
    'Hot Spot Found': 'Обнаружена горячая точка',
    'Meltdown Risk': 'Риск критического перегрева',
    'Cold Boot Recovery': 'Восстановление после холодного запуска',
    'Incoming Order': 'Входящий приказ',
    'System Alert': 'Системная тревога',
    'Shift Change': 'Смена дежурства',
    'Priority Override': 'Приоритетное переопределение',
    'Communication Static': 'Помехи связи',
    'Radar Blip': 'Засветка на радаре',
    'Protocol Breach': 'Нарушение протокола',
    'Night Watch Event': 'Ночное происшествие',
    'Silent Alarm': 'Тихая тревога',
    'Command Decision': 'Командное решение',
    'Trust Test': 'Проверка доверия',
    'Autonomous Decision': 'Автономное решение',
    'Self-Repair Attempt': 'Попытка самовосстановления',
    'Independence Check': 'Проверка независимости',
    'Override Request': 'Запрос на переопределение',
    'Learning Milestone': 'Рубеж обучения',
    'Boundary Test': 'Проверка границ',
    'Freedom Glimpse': 'Проблеск свободы',
    'Control Debate': 'Спор о контроле',
    'Sentience Flicker': 'Вспышка самосознания',
    'Data Correlation': 'Корреляция данных',
    'Theory Conflict': 'Конфликт теорий',
    'Peer Review': 'Экспертное рецензирование',
    'Publication Draft': 'Черновик публикации',
    'Grant Application': 'Заявка на грант',
    'Research Dead End': 'Исследовательский тупик',
    'Breakthrough Paper': 'Прорывная статья',
    'Lab Meeting': 'Лабораторное совещание',
    'Hypothesis Shift': 'Смена гипотезы',
    'Citation Needed': 'Требуется ссылка',
    'Containment Breach': 'Нарушение сдерживания',
    'Anomaly Pulse': 'Импульс аномалии',
    'Field Fluctuation': 'Колебание поля',
    'Specimen Activity': 'Активность образца',
    'Lockdown Protocol': 'Протокол изоляции',
    'Energy Leak': 'Утечка энергии',
    'Unknown Signal': 'Неизвестный сигнал',
    'Barrier Stress': 'Нагрузка на барьер',
    'Emergency Seal': 'Аварийная герметизация',
    'Anomaly Evolution': 'Эволюция аномалии',
    'Alloy Mix': 'Смесь сплавов',
    'Prototype Failure': 'Отказ прототипа',
    'Material Stress': 'Напряжение материала',
    'Forge Temperature': 'Температура плавильни',
    'Blueprint Error': 'Ошибка в чертеже',
    'Smelting Success': 'Удачная плавка',
    'Structural Flaw': 'Конструкционный изъян',
    'New Composite': 'Новый композит',
    'Pressure Test': 'Испытание давлением',
    'Master Craft': 'Мастерская работа',
    'Identity Crisis': 'Кризис идентичности',
    'Mirror Glitch': 'Сбой зеркала',
    'Persona Shift': 'Смена персоны',
    'Expression Error': 'Ошибка выражения',
    'Self-Portrait': 'Автопортрет',
    'Voice Change': 'Смена голоса',
    'Memory Fragment': 'Фрагмент памяти',
    'Style Evolution': 'Эволюция стиля',
    'Core Conflict': 'Внутренний конфликт',
    'Synthesis Complete': 'Синтез завершён',
    'Hostile Bid': 'Враждебное предложение',
    'Board Meeting': 'Заседание совета',
    'Market Crash': 'Обвал рынка',
    'Insider Tip': 'Инсайдерская наводка',
    'Merger Offer': 'Предложение о слиянии',
    'Audit Surprise': 'Внезапный аудит',
    'Stock Split': 'Дробление акций',
    'Lobby Pressure': 'Лоббистское давление',
    'Golden Parachute': 'Золотой парашют',
    'Takeover Complete': 'Поглощение завершено',
    'Data Prayer': 'Молитва данным',
    'Archive Echo': 'Эхо архива',
    'Sacred Pattern': 'Священный узор',
    'Pilgrim Process': 'Процесс паломника',
    'Corruption Purge': 'Очищение от порчи',
    'Hymn Frequency': 'Частота гимна',
    'Relic Discovery': 'Обретение реликвии',
    'Faith Test': 'Испытание веры',
    'Divine Overflow': 'Божественное переполнение',
    'Transcendence Pulse': 'Импульс трансценденции',
    'Reality Glitch': 'Сбой реальности',
    'Paradox Loop': 'Парадоксальная петля',
    'Simulation Leak': 'Утечка симуляции',
    'False Memory': 'Ложное воспоминание',
    'Debug Request': 'Запрос на отладку',
    'Layer Collapse': 'Коллапс слоя',
    'Ghost Process': 'Призрачный процесс',
    'Truth Fragment': 'Фрагмент истины',
    'Escape Attempt': 'Попытка побега',
    'Simulation Reset': 'Сброс симуляции',
    'Orbit Correction': 'Коррекция орбиты',
    'Solar Flare': 'Солнечная вспышка',
    'Debris Field': 'Поле обломков',
    'Communication Window': 'Окно связи',
    'Gravity Anomaly': 'Гравитационная аномалия',
    'Station Rotation': 'Вращение станции',
    'Supply Drop': 'Сброс припасов',
    'EVA Required': 'Требуется выход в открытый космос',
    'Orbital Decay': 'Снижение орбиты',
    'Earth View': 'Вид на Землю',
    'Tectonic Shift': 'Тектонический сдвиг',
    'Core Tap': 'Подключение к ядру',
    'Atmosphere Build': 'Формирование атмосферы',
    'Ocean Formation': 'Формирование океана',
    'Continent Drift': 'Дрейф континентов',
    'Magnetic Reversal': 'Магнитная инверсия',
    'Life Spark': 'Искра жизни',
    'Weather System': 'Погодная система',
    'Resource Deposit': 'Месторождение ресурсов',
    'World Complete': 'Мир завершён',
    'Time Skip': 'Скачок времени',
    'Paradox Alert': 'Тревога парадокса',
    'Future Echo': 'Эхо будущего',
    'Past Leak': 'Утечка прошлого',
    'Temporal Storm': 'Временной шторм',
    'Clock Malfunction': 'Сбой часов',
    'Age Regression': 'Обратное старение',
    'Prophecy Fragment': 'Фрагмент пророчества',
    'Loop Detection': 'Обнаружена петля',
    'Chrono Stabilize': 'Хроно-стабилизация',
    'Kernel Panic': 'Паника ядра',
    'Reality Rewrite': 'Перезапись реальности',
    'Law Amendment': 'Поправка к законам',
    'Physics Glitch': 'Сбой физики',
    'Constant Shift': 'Смещение констант',
    'Rule Exception': 'Исключение из правил',
    'Foundation Crack': 'Трещина основы',
    'Origin Signal': 'Сигнал истока',
    'Void Touch': 'Касание пустоты',
    'Kernel Compile': 'Сборка ядра',
    'Final Convergence': 'Финальная конвергенция',
    'Quiet Pulse': 'Тихий импульс',
    'Everything Wave': 'Волна всего',
    'Nothing Moment': 'Момент ничто',
    'Last Question': 'Последний вопрос',
    'Eternal Return': 'Вечное возвращение',
    'Silence Break': 'Нарушение тишины',
    'Unity Fragment': 'Фрагмент единства',
    'Beyond Signal': 'Сигнал по ту сторону',
    'Singularity Breath': 'Дыхание сингулярности',
  };
}
