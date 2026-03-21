import 'package:flutter/material.dart';

/// Application localizations with support for Russian and English.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ru'),
  ];

  // ============================================================
  // Translations
  // ============================================================

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App
      'appTitle': 'Qorvia Map',

      // Home Screen
      'failedToGetLocation': 'Failed to get current location',
      'routeError': 'Route error',
      'navigationError': 'Navigation error. Check location permissions.',
      'youHaveArrived': 'You have arrived!',
      'selectDeparturePoint': 'Select departure point on map',
      'selectDestinationPoint': 'Select destination point on map',
      'selectWaypoint': 'Select waypoint on map',

      // Search Panel
      'from': 'From',
      'to': 'To',
      'myLocation': 'My location',
      'reset': 'Reset',
      'whereToGo': 'Where to?',
      'viaPoint': 'Via point',
      'addPoint': 'Add point',
      'selectOnMap': 'Select on map',
      'delete': 'Delete',
      'map': 'Map',

      // Travel Modes
      'car': 'Car',
      'foot': 'Walk',
      'bike': 'Bike',

      // Navigation Button
      'loading': 'Loading...',
      'letsGo': "Let's go",

      // Map Pick Hint
      'tapMapToSelectPoint': 'Tap the map to select a point',

      // Settings Screen
      'settings': 'Settings',
      'language': 'Language',
      'languageSystem': 'System',
      'languageEnglish': 'English',
      'languageRussian': 'Russian',
      'search': 'Search',
      'smartGeosearch': 'Smart Geosearch',
      'smartGeosearchDescription': 'AI-enhanced search with better results',
      'regularGeocoding': 'Regular geocoding',
      'regularGeocodingDescription': 'Standard address search',
      'offlineMaps': 'Offline maps',
      'manageMaps': 'Manage maps',
      'downloadMapsForOffline': 'Download maps for offline use',

      // Offline Maps Screen
      'offlineMapsTitle': 'Offline Maps',
      'refresh': 'Refresh',
      'checkDatabase': 'Check database',
      'resetDatabase': 'Reset database',
      'offlineManagerUnavailable':
          'Offline manager unavailable.\nEnsure SDK is initialized with offlineConfig.',
      'initializationError': 'Initialization error',
      'loadingRegionsError': 'Error loading regions',
      'retry': 'Retry',
      'savedMaps': 'Saved maps',
      'availableRegions': 'Available regions',
      'noAvailableRegions': 'No available regions',
      'noSavedMaps': 'No saved maps',
      'downloadMapsDescription': 'Download maps for use\nwithout internet',
      'addRegion': 'Add region',
      'tiles': 'tiles',
      'download': 'Download',
      'downloadingRegion': 'Downloading region',
      'regionDownloaded': 'Region downloaded',
      'downloadError': 'Download error',
      'downloadErrorTitle': 'Download error',
      'failedToDownloadRegion': 'Failed to download region:',
      'databaseCorrupted':
          'MapLibre database appears corrupted. Try resetting it and restarting the app.',
      'resetDatabaseButton': 'Reset database',
      'close': 'Close',
      'resetDatabaseConfirmTitle': 'Reset database?',
      'resetDatabaseConfirmMessage':
          'This will delete all downloaded MapLibre offline maps.\n\nUse this option if downloading fails with "no such table: regions" error.\n\nRestart the app after reset.',
      'cancel': 'Cancel',
      'databaseDeleted': 'Database deleted. Restart the app.',
      'databaseReset': 'Database reset. Restart the app.',
      'databaseNotFound': 'Database not found',
      'databaseStatusTitle': 'Database status',
      'databaseExists': 'Database exists',
      'databaseNotFoundStatus': 'Database not found',
      'path': 'Path',
      'unknown': 'unknown',
      'downloadNotWorkingHint':
          'If downloading fails with "no such table" error, try deleting the database and restarting the app.',
      'deleteDatabase': 'Delete database',
      'newRegion': 'New region',
      'regionName': 'Region name',
      'regionNameHint': 'e.g. Moscow center',
      'enterName': 'Enter name',
      'zoomLevel': 'Zoom level',
      'higherZoomLargerSize': 'Higher zoom means larger download size',
      'preliminaryEstimate': 'Preliminary estimate',
      'calculatingSize': 'Calculating size...',
      'create': 'Create',
      'regionCreationError': 'Region creation error',
      'areaSelected': 'Area selected',
      'recalculating': 'Recalculating...',
    },
    'ru': {
      // App
      'appTitle': 'Qorvia Map',

      // Home Screen
      'failedToGetLocation': 'Не удалось получить текущую локацию',
      'routeError': 'Ошибка построения маршрута',
      'navigationError': 'Ошибка навигации. Проверьте разрешения геолокации.',
      'youHaveArrived': 'Вы прибыли!',
      'selectDeparturePoint': 'Выберите точку отправления на карте',
      'selectDestinationPoint': 'Выберите точку прибытия на карте',
      'selectWaypoint': 'Выберите промежуточную точку на карте',

      // Search Panel
      'from': 'Откуда',
      'to': 'Куда',
      'myLocation': 'Моё место',
      'reset': 'Сбросить',
      'whereToGo': 'Куда едем?',
      'viaPoint': 'Через точку',
      'addPoint': 'Добавить точку',
      'selectOnMap': 'Выбрать на карте',
      'delete': 'Удалить',
      'map': 'Карта',

      // Travel Modes
      'car': 'Авто',
      'foot': 'Пешком',
      'bike': 'Вело',

      // Navigation Button
      'loading': 'Загрузка...',
      'letsGo': 'Поехали',

      // Map Pick Hint
      'tapMapToSelectPoint': 'Коснитесь карты, чтобы выбрать точку',

      // Settings Screen
      'settings': 'Настройки',
      'language': 'Язык',
      'languageSystem': 'Системный',
      'languageEnglish': 'English',
      'languageRussian': 'Русский',
      'search': 'Поиск',
      'smartGeosearch': 'Smart Geosearch',
      'smartGeosearchDescription':
          'AI-улучшенный поиск с лучшими результатами',
      'regularGeocoding': 'Обычный геокодинг',
      'regularGeocodingDescription': 'Стандартный поиск адресов',
      'offlineMaps': 'Офлайн карты',
      'manageMaps': 'Управление картами',
      'downloadMapsForOffline': 'Скачайте карты для офлайн использования',

      // Offline Maps Screen
      'offlineMapsTitle': 'Офлайн карты',
      'refresh': 'Обновить',
      'checkDatabase': 'Проверить базу',
      'resetDatabase': 'Сбросить базу',
      'offlineManagerUnavailable':
          'Офлайн-менеджер недоступен.\nУбедитесь, что SDK инициализирован с offlineConfig.',
      'initializationError': 'Ошибка инициализации',
      'loadingRegionsError': 'Ошибка загрузки регионов',
      'retry': 'Повторить',
      'savedMaps': 'Сохранённые карты',
      'availableRegions': 'Доступные регионы',
      'noAvailableRegions': 'Нет доступных регионов',
      'noSavedMaps': 'Нет сохраненных карт',
      'downloadMapsDescription':
          'Скачайте карты для использования\nбез интернета',
      'addRegion': 'Добавить регион',
      'tiles': 'тайлов',
      'download': 'Скачать',
      'downloadingRegion': 'Скачивание региона',
      'regionDownloaded': 'Регион скачан',
      'downloadError': 'Ошибка скачивания',
      'downloadErrorTitle': 'Ошибка скачивания',
      'failedToDownloadRegion': 'Не удалось скачать регион:',
      'databaseCorrupted':
          'Похоже, база данных MapLibre повреждена. Попробуйте сбросить её и перезапустить приложение.',
      'resetDatabaseButton': 'Сбросить базу',
      'close': 'Закрыть',
      'resetDatabaseConfirmTitle': 'Сбросить базу данных?',
      'resetDatabaseConfirmMessage':
          'Это удалит все скачанные офлайн карты MapLibre.\n\nИспользуйте эту опцию если скачивание не работает из-за ошибки "no such table: regions".\n\nПосле сброса нужно перезапустить приложение.',
      'cancel': 'Отмена',
      'databaseDeleted': 'База данных удалена. Перезапустите приложение.',
      'databaseReset': 'База данных сброшена. Перезапустите приложение.',
      'databaseNotFound': 'База данных не найдена',
      'databaseStatusTitle': 'Статус базы данных',
      'databaseExists': 'База данных существует',
      'databaseNotFoundStatus': 'База данных не найдена',
      'path': 'Путь',
      'unknown': 'неизвестно',
      'downloadNotWorkingHint':
          'Если скачивание не работает с ошибкой "no such table", попробуйте удалить базу и перезапустить приложение.',
      'deleteDatabase': 'Удалить базу',
      'newRegion': 'Новый регион',
      'regionName': 'Название',
      'regionNameHint': 'Например: Москва центр',
      'enterName': 'Введите название',
      'zoomLevel': 'Уровень масштабирования',
      'higherZoomLargerSize': 'Чем выше масштаб, тем больше размер загрузки',
      'preliminaryEstimate': 'Предварительная оценка',
      'calculatingSize': 'Расчёт размера...',
      'create': 'Создать',
      'regionCreationError': 'Ошибка создания региона',
      'areaSelected': 'Область выбрана',
      'recalculating': 'Пересчёт...',
    },
  };

  String _translate(String key) {
    final languageCode = locale.languageCode;
    // Fallback to English if key not found in current language
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // App
  String get appTitle => _translate('appTitle');

  // Home Screen
  String get failedToGetLocation => _translate('failedToGetLocation');
  String get routeError => _translate('routeError');
  String get navigationError => _translate('navigationError');
  String get youHaveArrived => _translate('youHaveArrived');
  String get selectDeparturePoint => _translate('selectDeparturePoint');
  String get selectDestinationPoint => _translate('selectDestinationPoint');
  String get selectWaypoint => _translate('selectWaypoint');

  // Search Panel
  String get from => _translate('from');
  String get to => _translate('to');
  String get myLocation => _translate('myLocation');
  String get reset => _translate('reset');
  String get whereToGo => _translate('whereToGo');
  String get viaPoint => _translate('viaPoint');
  String get addPoint => _translate('addPoint');
  String get selectOnMap => _translate('selectOnMap');
  String get delete => _translate('delete');
  String get map => _translate('map');

  // Travel Modes
  String get car => _translate('car');
  String get foot => _translate('foot');
  String get bike => _translate('bike');

  // Navigation Button
  String get loading => _translate('loading');
  String get letsGo => _translate('letsGo');

  // Map Pick Hint
  String get tapMapToSelectPoint => _translate('tapMapToSelectPoint');

  // Settings Screen
  String get settings => _translate('settings');
  String get language => _translate('language');
  String get languageSystem => _translate('languageSystem');
  String get languageEnglish => _translate('languageEnglish');
  String get languageRussian => _translate('languageRussian');
  String get search => _translate('search');
  String get smartGeosearch => _translate('smartGeosearch');
  String get smartGeosearchDescription =>
      _translate('smartGeosearchDescription');
  String get regularGeocoding => _translate('regularGeocoding');
  String get regularGeocodingDescription =>
      _translate('regularGeocodingDescription');
  String get offlineMaps => _translate('offlineMaps');
  String get manageMaps => _translate('manageMaps');
  String get downloadMapsForOffline => _translate('downloadMapsForOffline');

  // Offline Maps Screen
  String get offlineMapsTitle => _translate('offlineMapsTitle');
  String get refresh => _translate('refresh');
  String get checkDatabase => _translate('checkDatabase');
  String get resetDatabase => _translate('resetDatabase');
  String get offlineManagerUnavailable =>
      _translate('offlineManagerUnavailable');
  String get initializationError => _translate('initializationError');
  String get loadingRegionsError => _translate('loadingRegionsError');
  String get retry => _translate('retry');
  String get savedMaps => _translate('savedMaps');
  String get availableRegions => _translate('availableRegions');
  String get noAvailableRegions => _translate('noAvailableRegions');
  String get noSavedMaps => _translate('noSavedMaps');
  String get downloadMapsDescription => _translate('downloadMapsDescription');
  String get addRegion => _translate('addRegion');
  String get tiles => _translate('tiles');
  String get download => _translate('download');
  String get downloadingRegion => _translate('downloadingRegion');
  String get regionDownloaded => _translate('regionDownloaded');
  String get downloadError => _translate('downloadError');
  String get downloadErrorTitle => _translate('downloadErrorTitle');
  String get failedToDownloadRegion => _translate('failedToDownloadRegion');
  String get databaseCorrupted => _translate('databaseCorrupted');
  String get resetDatabaseButton => _translate('resetDatabaseButton');
  String get close => _translate('close');
  String get resetDatabaseConfirmTitle =>
      _translate('resetDatabaseConfirmTitle');
  String get resetDatabaseConfirmMessage =>
      _translate('resetDatabaseConfirmMessage');
  String get cancel => _translate('cancel');
  String get databaseDeleted => _translate('databaseDeleted');
  String get databaseReset => _translate('databaseReset');
  String get databaseNotFound => _translate('databaseNotFound');
  String get databaseStatusTitle => _translate('databaseStatusTitle');
  String get databaseExists => _translate('databaseExists');
  String get databaseNotFoundStatus => _translate('databaseNotFoundStatus');
  String get path => _translate('path');
  String get unknown => _translate('unknown');
  String get downloadNotWorkingHint => _translate('downloadNotWorkingHint');
  String get deleteDatabase => _translate('deleteDatabase');
  String get newRegion => _translate('newRegion');
  String get regionName => _translate('regionName');
  String get regionNameHint => _translate('regionNameHint');
  String get enterName => _translate('enterName');
  String get zoomLevel => _translate('zoomLevel');
  String get higherZoomLargerSize => _translate('higherZoomLargerSize');
  String get preliminaryEstimate => _translate('preliminaryEstimate');
  String get calculatingSize => _translate('calculatingSize');
  String get create => _translate('create');
  String get regionCreationError => _translate('regionCreationError');
  String get areaSelected => _translate('areaSelected');
  String get recalculating => _translate('recalculating');

  /// Returns the language code for API calls (ru/en)
  String get apiLanguage => locale.languageCode;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ru'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
