import 'dart:math';
import '../models/coordinates.dart';
import 'location_data.dart';

/// Kalman фильтр для сглаживания GPS данных.
/// Уменьшает шум и выбросы в данных геолокации.
class LocationFilter {
  // Состояние фильтра
  double? _lat;
  double? _lon;
  double? _altitude;
  double? _speed;
  double? _heading;

  // Ковариация (неопределённость)
  double _variance = double.maxFinite;

  // Параметры фильтра
  final double _processNoise; // Q - шум процесса (м²)
  final double _minAccuracyThreshold; // Минимальная точность для принятия данных
  final double _maxSpeedThreshold; // Максимальная разумная скорость (м/с)
  final double _maxAccelerationThreshold; // Макс. ускорение (м/с²)

  DateTime? _lastTimestamp;
  LocationData? _lastLocation;

  // Ограничения для предотвращения деградации фильтра
  static const double _maxVariance = 10000.0; // ~100м максимальная неопределённость
  static const double _minVariance = 1.0; // ~1м минимальная неопределённость
  static const Duration _staleThreshold = Duration(seconds: 60); // Порог устаревания
  static const Duration _longPauseThreshold = Duration(seconds: 10); // Порог длинной паузы

  LocationFilter({
    double processNoise = 3.0,
    double minAccuracyThreshold = 100.0, // Отбрасываем данные с accuracy > 100м
    double maxSpeedThreshold = 70.0, // ~250 км/ч
    double maxAccelerationThreshold = 15.0, // ~1.5g
  })  : _processNoise = processNoise,
        _minAccuracyThreshold = minAccuracyThreshold,
        _maxSpeedThreshold = maxSpeedThreshold,
        _maxAccelerationThreshold = maxAccelerationThreshold;

  /// Фильтрует входящие данные геолокации.
  /// Возвращает null если данные должны быть отброшены.
  LocationData? filter(LocationData raw) {
    // 0. Проверка на устаревание фильтра - если долго не было данных,
    // сбрасываем состояние чтобы избежать ложных отклонений
    if (_lastTimestamp != null) {
      final timeSinceLastUpdate = raw.timestamp.difference(_lastTimestamp!);
      if (timeSinceLastUpdate > _staleThreshold) {
        // Фильтр устарел - полный сброс
        reset();
      } else if (timeSinceLastUpdate > _longPauseThreshold) {
        // Длинная пауза - ослабляем фильтр (увеличиваем variance)
        _variance = (_variance * 2).clamp(_minVariance, _maxVariance);
      }
    }

    // 1. Проверка accuracy - отбрасываем очень неточные данные
    if (raw.accuracy > _minAccuracyThreshold) {
      return null;
    }

    // 2. Проверка на выброс по скорости (ослаблена после длинной паузы)
    if (!_isValidSpeed(raw)) {
      return null;
    }

    // 3. Проверка на телепортацию (резкий скачок координат)
    if (!_isValidJump(raw)) {
      return null;
    }

    // 4. Применяем Kalman фильтр
    final filtered = _applyKalmanFilter(raw);

    _lastLocation = filtered;
    _lastTimestamp = raw.timestamp;

    return filtered;
  }

  bool _isValidSpeed(LocationData data) {
    final speed = data.speed;
    if (speed == null) return true;

    // Отбрасываем нереалистичную скорость
    if (speed > _maxSpeedThreshold) {
      return false;
    }

    // Проверка ускорения с адаптивным порогом
    if (_lastLocation != null && _lastTimestamp != null) {
      final lastSpeed = _lastLocation!.speed ?? 0;
      final dt = data.timestamp.difference(_lastTimestamp!).inMilliseconds / 1000.0;

      if (dt > 0) {
        final acceleration = (speed - lastSpeed).abs() / dt;

        // Адаптивный порог ускорения:
        // - При низкой скорости (< 2 м/с) разрешаем большее ускорение (GPS шум)
        // - При высокой скорости используем строгий порог
        final isLowSpeed = speed < 2.0 && lastSpeed < 2.0;
        final effectiveThreshold = isLowSpeed
            ? _maxAccelerationThreshold * 2.0 // Более мягкий порог при низкой скорости
            : _maxAccelerationThreshold;

        if (acceleration > effectiveThreshold) {
          return false;
        }
      }
    }

    return true;
  }

  bool _isValidJump(LocationData data) {
    if (_lastLocation == null || _lastTimestamp == null) {
      return true;
    }

    final dt = data.timestamp.difference(_lastTimestamp!).inMilliseconds / 1000.0;
    if (dt <= 0) return true;

    // После длинной паузы разрешаем большие скачки -
    // пользователь мог реально переместиться
    final isLongPause = dt > _longPauseThreshold.inSeconds;
    if (isLongPause) {
      return true; // Не проверяем телепортацию после длинной паузы
    }

    final distance = data.coordinates.distanceTo(_lastLocation!.coordinates);
    final impliedSpeed = distance / dt;

    // Если "скорость перемещения" нереалистична - это выброс
    if (impliedSpeed > _maxSpeedThreshold * 1.5) {
      return false;
    }

    return true;
  }

  LocationData _applyKalmanFilter(LocationData raw) {
    final accuracy = raw.accuracy;
    // Measurement noise = accuracy²
    final measurementNoise = accuracy * accuracy;

    if (_lat == null || _lon == null) {
      // Инициализация
      _lat = raw.coordinates.lat;
      _lon = raw.coordinates.lon;
      _altitude = raw.altitude;
      _speed = raw.speed;
      _heading = raw.heading;
      _variance = measurementNoise;
      return raw;
    }

    // Время с последнего обновления
    final dt = _lastTimestamp != null
        ? raw.timestamp.difference(_lastTimestamp!).inMilliseconds / 1000.0
        : 1.0;

    // Адаптивный шум процесса в зависимости от скорости:
    // - При низкой скорости (стоим) - меньше шума, доверяем GPS больше
    // - При высокой скорости - больше шума, фильтр более "забывчивый"
    final speed = raw.speed ?? 0;
    final adaptiveProcessNoise = speed < 1.0
        ? _processNoise * 0.5 // Стоим - более стабильный фильтр
        : speed < 5.0
            ? _processNoise // Пешком - нормальный фильтр
            : _processNoise * 1.5; // Быстро движемся - более отзывчивый

    // Predict step: увеличиваем неопределённость со временем
    // Ограничиваем рост чтобы фильтр не "забывал" состояние полностью
    _variance = (_variance + adaptiveProcessNoise * dt).clamp(_minVariance, _maxVariance);

    // Update step: Kalman gain
    final kalmanGain = _variance / (_variance + measurementNoise);

    // Обновляем координаты
    _lat = _lat! + kalmanGain * (raw.coordinates.lat - _lat!);
    _lon = _lon! + kalmanGain * (raw.coordinates.lon - _lon!);

    // Обновляем высоту (если есть)
    if (raw.altitude != null) {
      _altitude = _altitude != null
          ? _altitude! + kalmanGain * (raw.altitude! - _altitude!)
          : raw.altitude;
    }

    // Скорость и heading обновляем напрямую (они уже фильтруются GPS чипом)
    _speed = raw.speed;
    _heading = _smoothHeading(raw.heading);

    // Обновляем ковариацию с ограничением
    _variance = ((1 - kalmanGain) * _variance).clamp(_minVariance, _maxVariance);

    return LocationData(
      coordinates: Coordinates(lat: _lat!, lon: _lon!),
      altitude: _altitude,
      heading: _heading,
      speed: _speed,
      accuracy: sqrt(_variance), // Новая оценка точности
      timestamp: raw.timestamp,
    );
  }

  double? _smoothHeading(double? newHeading) {
    if (newHeading == null) return _heading;
    if (_heading == null) return newHeading;

    // Сглаживание heading с учётом перехода через 360°
    var diff = newHeading - _heading!;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    // Плавное сглаживание (0.3 = коэффициент сглаживания)
    var smoothed = _heading! + 0.3 * diff;
    if (smoothed < 0) smoothed += 360;
    if (smoothed >= 360) smoothed -= 360;

    return smoothed;
  }

  /// Сбрасывает состояние фильтра.
  void reset() {
    _lat = null;
    _lon = null;
    _altitude = null;
    _speed = null;
    _heading = null;
    _variance = double.maxFinite;
    _lastTimestamp = null;
    _lastLocation = null;
  }

  /// Возвращает текущую оценку точности после фильтрации.
  double get estimatedAccuracy => sqrt(_variance);
}

/// Расширенные настройки фильтрации.
class LocationFilterSettings {
  /// Шум процесса для Kalman фильтра (меньше = более плавно, больше = более отзывчиво).
  final double processNoise;

  /// Отбрасывать данные с accuracy выше этого порога (метры).
  final double minAccuracyThreshold;

  /// Максимальная допустимая скорость (м/с).
  final double maxSpeedThreshold;

  /// Максимальное допустимое ускорение (м/с²).
  final double maxAccelerationThreshold;

  /// Включить фильтрацию.
  final bool enabled;

  const LocationFilterSettings({
    this.processNoise = 3.0,
    this.minAccuracyThreshold = 100.0,
    this.maxSpeedThreshold = 70.0,
    this.maxAccelerationThreshold = 15.0,
    this.enabled = true,
  });

  /// Настройки для навигации (более агрессивная фильтрация).
  factory LocationFilterSettings.navigation() {
    return const LocationFilterSettings(
      processNoise: 2.0,
      minAccuracyThreshold: 50.0, // Строже для навигации
      maxSpeedThreshold: 70.0,
      maxAccelerationThreshold: 10.0,
      enabled: true,
    );
  }

  /// Настройки для пешеходов.
  factory LocationFilterSettings.walking() {
    return const LocationFilterSettings(
      processNoise: 1.5,
      minAccuracyThreshold: 30.0,
      maxSpeedThreshold: 10.0, // ~36 км/ч макс для пешехода/бегуна
      maxAccelerationThreshold: 5.0,
      enabled: true,
    );
  }
}
