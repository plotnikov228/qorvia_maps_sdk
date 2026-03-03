import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';
import '../models/coordinates.dart';
import 'location_data.dart';
import 'location_filter.dart';
import 'location_settings.dart';

/// Service for handling device location.
class LocationService {
  StreamSubscription<geo.Position>? _positionSubscription;
  final _locationController = StreamController<LocationData>.broadcast();
  LocationData? _lastLocation;
  bool _isTracking = false;
  static const bool _debugLocationLogs = true;
  DateTime? _lastLocationLogAt;

  // Kalman фильтр для сглаживания GPS данных
  LocationFilter? _locationFilter;
  LocationFilterSettings _filterSettings = const LocationFilterSettings();

  // Watchdog для обнаружения зависания потока
  Timer? _watchdogTimer;
  DateTime? _lastLocationReceivedAt;
  static const Duration _watchdogInterval = Duration(seconds: 30);
  static const Duration _staleThreshold = Duration(seconds: 45);
  int _restartAttempts = 0;
  static const int _maxRestartAttempts = 3;

  // Сохранённые настройки для перезапуска
  LocationSettings? _currentSettings;

  /// Callback при восстановлении потока после зависания.
  void Function()? onStreamRecovered;

  /// Callback при обнаружении проблемы с потоком.
  void Function(String reason)? onStreamProblem;

  // Метрики для диагностики
  int _locationsReceived = 0;
  int _locationsFiltered = 0;
  int _streamRestarts = 0;

  /// Stream of location updates.
  Stream<LocationData> get locationStream => _locationController.stream;

  /// Last known location.
  LocationData? get lastLocation => _lastLocation;

  /// Whether location tracking is active.
  bool get isTracking => _isTracking;

  /// Время последнего успешного получения локации.
  DateTime? get lastLocationReceivedAt => _lastLocationReceivedAt;

  /// Количество полученных локаций за сессию.
  int get locationsReceived => _locationsReceived;

  /// Количество отфильтрованных (отброшенных) локаций за сессию.
  int get locationsFiltered => _locationsFiltered;

  /// Количество перезапусков потока за сессию.
  int get streamRestarts => _streamRestarts;

  /// Проверяет здоровье сервиса геолокации.
  /// Возвращает объект с диагностической информацией.
  LocationServiceHealth checkHealth() {
    final now = DateTime.now();
    Duration? timeSinceLastUpdate;
    bool isStale = false;

    if (_lastLocationReceivedAt != null) {
      timeSinceLastUpdate = now.difference(_lastLocationReceivedAt!);
      isStale = timeSinceLastUpdate > _staleThreshold;
    }

    return LocationServiceHealth(
      isTracking: _isTracking,
      isStale: isStale,
      timeSinceLastUpdate: timeSinceLastUpdate,
      locationsReceived: _locationsReceived,
      locationsFiltered: _locationsFiltered,
      streamRestarts: _streamRestarts,
      filterEstimatedAccuracy: _locationFilter?.estimatedAccuracy,
    );
  }

  /// Сбрасывает метрики (для начала новой сессии).
  void resetMetrics() {
    _locationsReceived = 0;
    _locationsFiltered = 0;
    _streamRestarts = 0;
  }

  /// Checks if location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    return await geo.Geolocator.isLocationServiceEnabled();
  }

  /// Checks current permission status.
  Future<LocationPermissionStatus> checkPermission() async {
    final permission = await Permission.location.status;
    return _mapPermissionStatus(permission);
  }

  /// Requests location permission.
  Future<LocationPermissionStatus> requestPermission() async {
    final permission = await Permission.location.request();
    return _mapPermissionStatus(permission);
  }

  /// Requests background location permission (for navigation).
  Future<LocationPermissionStatus> requestBackgroundPermission() async {
    final foreground = await Permission.location.request();
    if (!foreground.isGranted) {
      return _mapPermissionStatus(foreground);
    }

    final background = await Permission.locationAlways.request();
    return _mapPermissionStatus(background);
  }

  LocationPermissionStatus _mapPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return LocationPermissionStatus.granted;
      case PermissionStatus.denied:
        return LocationPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return LocationPermissionStatus.permanentlyDenied;
      default:
        return LocationPermissionStatus.denied;
    }
  }

  /// Gets current location once.
  Future<LocationData?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services disabled.');
        return null;
      }

      final permission = await checkPermission();
      if (permission != LocationPermissionStatus.granted) {
        debugPrint('LocationService: Location permission not granted.');
        return null;
      }

      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: _mapAccuracy(accuracy),
      ).timeout(timeout);
      final locationData = _positionToLocationData(position);
      _lastLocation = locationData;
      return locationData;
    } on TimeoutException {
      debugPrint('LocationService: Timed out getting current location.');
      return null;
    } catch (e) {
      debugPrint('LocationService: Failed to get current location: $e');
      return null;
    }
  }

  /// Starts continuous location tracking.
  ///
  /// [settings] - настройки отслеживания
  /// [filterSettings] - настройки фильтрации (Kalman filter)
  Future<void> startTracking([
    LocationSettings settings = const LocationSettings(),
    LocationFilterSettings filterSettings = const LocationFilterSettings(),
  ]) async {
    if (_isTracking) return;

    // Сохраняем настройки для возможного перезапуска
    _currentSettings = settings;

    // Инициализируем фильтр
    _filterSettings = filterSettings;
    if (_filterSettings.enabled) {
      _locationFilter = LocationFilter(
        processNoise: _filterSettings.processNoise,
        minAccuracyThreshold: _filterSettings.minAccuracyThreshold,
        maxSpeedThreshold: _filterSettings.maxSpeedThreshold,
        maxAccelerationThreshold: _filterSettings.maxAccelerationThreshold,
      );
    } else {
      _locationFilter = null;
    }

    final geoSettings = _buildPlatformSettings(settings);

    _positionSubscription = geo.Geolocator.getPositionStream(
      locationSettings: geoSettings,
    ).listen(
      (position) {
        // Обновляем время последнего получения для watchdog
        _lastLocationReceivedAt = DateTime.now();
        _restartAttempts = 0; // Сбрасываем счётчик при успешном получении

        final rawLocation = _positionToLocationData(position);

        // Применяем фильтрацию если включена
        LocationData? locationData;
        if (_locationFilter != null) {
          locationData = _locationFilter!.filter(rawLocation);
          if (locationData == null) {
            // Данные отброшены фильтром (выброс или низкая точность)
            _locationsFiltered++;
            debugPrint('LocationService: Filtered out location (accuracy: ${rawLocation.accuracy}m)');
            return;
          }
        } else {
          locationData = rawLocation;
        }

        _locationsReceived++;
        _lastLocation = locationData;
        if (_debugLocationLogs) {
          final now = DateTime.now();
          if (_lastLocationLogAt == null ||
              now.difference(_lastLocationLogAt!) >=
                  const Duration(milliseconds: 500)) {
            _lastLocationLogAt = now;
            debugPrint(
              'NavLoc dt=${_lastLocation != null ? position.timestamp.toIso8601String() : "-"} '
              'acc=${locationData.accuracy.toStringAsFixed(1)} '
              'speed=${locationData.speed?.toStringAsFixed(2) ?? "-"} '
              'heading=${locationData.heading?.toStringAsFixed(1) ?? "-"} '
              'pos=(${locationData.coordinates.lat.toStringAsFixed(6)},${locationData.coordinates.lon.toStringAsFixed(6)})',
            );
          }
        }
        _locationController.add(locationData);
      },
      onError: (error) {
        debugPrint('LocationService: Stream error: $error');
        onStreamProblem?.call('Stream error: $error');
      },
      onDone: () {
        debugPrint('LocationService: Stream closed unexpectedly');
        if (_isTracking) {
          onStreamProblem?.call('Stream closed unexpectedly');
          _attemptRestart();
        }
      },
    );

    _isTracking = true;
    _startWatchdog();
  }

  geo.LocationSettings _buildPlatformSettings(LocationSettings settings) {
    final accuracy = _mapAccuracy(settings.accuracy);

    if (Platform.isAndroid) {
      return geo.AndroidSettings(
        accuracy: accuracy,
        distanceFilter: settings.distanceFilter,
        intervalDuration: Duration(milliseconds: settings.intervalMs),
        // Не форсируем LocationManager - FusedLocationProvider точнее
        // Используем MSL altitude для более точной высоты
      );
    }

    if (Platform.isIOS) {
      return geo.AppleSettings(
        accuracy: accuracy,
        distanceFilter: settings.distanceFilter,
        // Выбираем activity type в зависимости от режима
        activityType: _getActivityType(settings.accuracy),
        // Не приостанавливаем обновления автоматически
        pauseLocationUpdatesAutomatically: false,
        // Показываем индикатор в фоне для навигации
        showBackgroundLocationIndicator: settings.allowBackgroundUpdates,
        // Разрешаем отложенные обновления для экономии батареи (не для навигации)
        allowBackgroundLocationUpdates: settings.allowBackgroundUpdates,
      );
    }

    return geo.LocationSettings(
      accuracy: accuracy,
      distanceFilter: settings.distanceFilter,
    );
  }

  /// Определяет тип активности для iOS в зависимости от точности.
  geo.ActivityType _getActivityType(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.navigation:
        return geo.ActivityType.automotiveNavigation;
      case LocationAccuracy.best:
      case LocationAccuracy.high:
        return geo.ActivityType.otherNavigation;
      case LocationAccuracy.medium:
        return geo.ActivityType.fitness;
      case LocationAccuracy.low:
        return geo.ActivityType.other;
    }
  }

  /// Stops location tracking.
  void stopTracking() {
    _stopWatchdog();
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationFilter?.reset();
    _locationFilter = null;
    _isTracking = false;
    _restartAttempts = 0;
    _lastLocationReceivedAt = null;
  }

  /// Запускает watchdog таймер для мониторинга здоровья потока.
  void _startWatchdog() {
    _stopWatchdog();
    _lastLocationReceivedAt = DateTime.now();
    debugPrint('LocationService: Watchdog started (interval: ${_watchdogInterval.inSeconds}s)');

    _watchdogTimer = Timer.periodic(_watchdogInterval, (_) {
      _checkStreamHealth();
    });
  }

  /// Останавливает watchdog таймер.
  void _stopWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  /// Проверяет здоровье location stream.
  void _checkStreamHealth() {
    if (!_isTracking) return;

    final lastReceived = _lastLocationReceivedAt;
    if (lastReceived == null) {
      debugPrint('LocationService: Watchdog - no location ever received, attempting restart');
      _attemptRestart();
      return;
    }

    final elapsed = DateTime.now().difference(lastReceived);
    if (elapsed > _staleThreshold) {
      debugPrint('LocationService: Watchdog - stream stale (${elapsed.inSeconds}s without data)');
      onStreamProblem?.call('No location updates for ${elapsed.inSeconds}s');
      _attemptRestart();
    } else if (_debugLocationLogs && elapsed > const Duration(seconds: 15)) {
      debugPrint('LocationService: Watchdog - warning, ${elapsed.inSeconds}s since last update');
    }
  }

  /// Пытается перезапустить location stream.
  Future<void> _attemptRestart() async {
    if (_restartAttempts >= _maxRestartAttempts) {
      debugPrint('LocationService: Max restart attempts reached ($_maxRestartAttempts), giving up');
      onStreamProblem?.call('Failed to recover after $_maxRestartAttempts attempts');
      return;
    }

    _restartAttempts++;
    final delay = Duration(seconds: _restartAttempts * 2); // Exponential backoff: 2s, 4s, 6s
    debugPrint('LocationService: Attempting restart #$_restartAttempts after ${delay.inSeconds}s');

    await Future.delayed(delay);

    if (!_isTracking) return; // Остановлено пока ждали

    // Отменяем текущую подписку
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    // Сбрасываем фильтр для свежего старта
    _locationFilter?.reset();

    // Перезапускаем поток
    try {
      final settings = _currentSettings ?? const LocationSettings();
      final geoSettings = _buildPlatformSettings(settings);

      _positionSubscription = geo.Geolocator.getPositionStream(
        locationSettings: geoSettings,
      ).listen(
        (position) {
          _lastLocationReceivedAt = DateTime.now();
          _restartAttempts = 0;

          final rawLocation = _positionToLocationData(position);
          LocationData? locationData;

          if (_locationFilter != null) {
            locationData = _locationFilter!.filter(rawLocation);
            if (locationData == null) {
              _locationsFiltered++;
              return;
            }
          } else {
            locationData = rawLocation;
          }

          _locationsReceived++;
          _lastLocation = locationData;
          _locationController.add(locationData);
        },
        onError: (error) {
          debugPrint('LocationService: Stream error after restart: $error');
          onStreamProblem?.call('Stream error: $error');
        },
        onDone: () {
          if (_isTracking) {
            debugPrint('LocationService: Stream closed after restart');
            _attemptRestart();
          }
        },
      );

      _streamRestarts++;
      debugPrint('LocationService: Stream restarted successfully (total restarts: $_streamRestarts)');
      onStreamRecovered?.call();
    } catch (e) {
      debugPrint('LocationService: Failed to restart stream: $e');
      onStreamProblem?.call('Restart failed: $e');
    }
  }

  /// Текущая оценка точности после фильтрации (в метрах).
  double? get estimatedAccuracy => _locationFilter?.estimatedAccuracy;

  /// Opens device location settings.
  Future<bool> openLocationSettings() async {
    return await geo.Geolocator.openLocationSettings();
  }

  /// Opens app settings (for permission management).
  Future<bool> openAppSettings() async {
    return await Permission.location.shouldShowRequestRationale
        ? await openPermissionSettings()
        : await geo.Geolocator.openAppSettings();
  }

  /// Opens app permission settings.
  Future<bool> openPermissionSettings() async {
    return await openAppSettings();
  }

  geo.LocationAccuracy _mapAccuracy(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.low:
        return geo.LocationAccuracy.low;
      case LocationAccuracy.medium:
        return geo.LocationAccuracy.medium;
      case LocationAccuracy.high:
        return geo.LocationAccuracy.high;
      case LocationAccuracy.best:
        return geo.LocationAccuracy.best;
      case LocationAccuracy.navigation:
        // bestForNavigation использует Kalman filter на уровне ОС
        return geo.LocationAccuracy.bestForNavigation;
    }
  }

  LocationData _positionToLocationData(geo.Position position) {
    return LocationData(
      coordinates: Coordinates(
        lat: position.latitude,
        lon: position.longitude,
      ),
      altitude: position.altitude,
      heading: position.heading,
      speed: position.speed,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }

  /// Disposes the service and releases resources.
  void dispose() {
    stopTracking();
    _stopWatchdog();
    _locationController.close();
  }
}

/// Location permission status.
enum LocationPermissionStatus {
  /// Permission granted.
  granted,

  /// Permission denied (can request again).
  denied,

  /// Permission permanently denied (must open settings).
  permanentlyDenied,
}

/// Диагностическая информация о здоровье сервиса геолокации.
class LocationServiceHealth {
  /// Активно ли отслеживание.
  final bool isTracking;

  /// Данные устарели (не было обновлений дольше порога).
  final bool isStale;

  /// Время с последнего обновления локации.
  final Duration? timeSinceLastUpdate;

  /// Количество успешно полученных локаций.
  final int locationsReceived;

  /// Количество отфильтрованных локаций.
  final int locationsFiltered;

  /// Количество перезапусков потока.
  final int streamRestarts;

  /// Оценка точности фильтра (метры).
  final double? filterEstimatedAccuracy;

  const LocationServiceHealth({
    required this.isTracking,
    required this.isStale,
    this.timeSinceLastUpdate,
    required this.locationsReceived,
    required this.locationsFiltered,
    required this.streamRestarts,
    this.filterEstimatedAccuracy,
  });

  /// Здоров ли сервис (отслеживает и данные свежие).
  bool get isHealthy => isTracking && !isStale;

  /// Процент отфильтрованных локаций.
  double get filterRate {
    final total = locationsReceived + locationsFiltered;
    if (total == 0) return 0;
    return locationsFiltered / total;
  }

  @override
  String toString() {
    return 'LocationServiceHealth('
        'isTracking: $isTracking, '
        'isStale: $isStale, '
        'timeSinceLastUpdate: ${timeSinceLastUpdate?.inSeconds}s, '
        'received: $locationsReceived, '
        'filtered: $locationsFiltered, '
        'restarts: $streamRestarts, '
        'accuracy: ${filterEstimatedAccuracy?.toStringAsFixed(1)}m)';
  }
}
