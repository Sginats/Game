import 'app_settings_service.dart';
import 'leaderboard_service.dart';
import '../../domain/models/progression_content.dart';
import '../../domain/models/gameplay_extensions.dart';
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
  String get challenges => isRussian ? 'Испытания' : 'Challenges';
  String get reducedMotion => isRussian ? 'Меньше анимации' : 'Reduced motion';
  String get reducedMotionDescription => isRussian
      ? 'Смягчает интенсивные анимации и движение интерфейса.'
      : 'Tones down movement-heavy effects.';
  String get uiScale => isRussian ? 'Масштаб UI' : 'UI scale';
  String get musicLayer => isRussian ? 'Музыкальный слой' : 'Music layer';
  String get sfxVolume => isRussian ? 'Громкость SFX' : 'SFX volume';
  String get colorClarity => isRussian ? 'Цветовая ясность' : 'Color clarity';
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
      return 'Задание: ${raw.substring(7)}';
    }
    if (raw.startsWith('Resolve ')) {
      return 'Решить: ${raw.substring(8)}';
    }
    if (raw.startsWith('Use ')) {
      return 'Использовать ${formatAbilityName(raw.substring(4))}';
    }
    if (raw.startsWith('Buy ')) {
      return 'Купить ${raw.substring(4)}';
    }
    if (raw == 'Grow income toward the next branch') {
      return 'Наращивайте доход до следующей ветки';
    }
    return raw;
  }

  String formatAiLine(String raw) {
    if (!isRussian) return raw;
    if (raw.startsWith('AI suggests a short-term objective: ')) {
      return 'ИИ предлагает краткосрочную цель: ${raw.substring(36)}';
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
}
