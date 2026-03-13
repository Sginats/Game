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
    final exact = _contentMap[raw];
    if (exact != null) return exact;

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

    final completionMatch = RegExp(r'^(.+) Complete$').firstMatch(raw);
    if (completionMatch != null) {
      return '${localizedEraName(completionMatch.group(1)!)} завершена';
    }

    if (raw.contains('lattice tier') && raw.contains('Progress here is meant')) {
      return 'Узел прогресса этой комнаты. Продвижение здесь должно ощущаться постепенным, а не мгновенным.';
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
  };
}
