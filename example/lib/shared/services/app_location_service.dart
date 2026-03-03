import 'dart:async';
import 'dart:developer' as developer;

import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

/// Wrapper service for location management with caching.
class AppLocationService {
  final LocationService _locationService = LocationService();
  StreamSubscription<LocationData>? _locationSubscription;
  LocationData? _lastLocationData;
  Coordinates? _lastUserLocation;
  bool _locating = false;

  /// Whether location is currently being fetched.
  bool get isLocating => _locating;

  /// Last known user location.
  Coordinates? get lastUserLocation => _lastUserLocation;

  /// Last known location data with accuracy and timestamp.
  LocationData? get lastLocationData => _lastLocationData;

  /// The underlying location service.
  LocationService get locationService => _locationService;

  /// Stream of location updates when tracking is active.
  Stream<LocationData> get locationStream => _locationService.locationStream;

  /// Disposes the service and cancels any active tracking.
  void dispose() {
    _locationSubscription?.cancel();
    _locationService.dispose();
    _log('AppLocationService disposed');
  }

  /// Loads cached location from SharedPreferences.
  /// Returns the cached coordinates or null if not found.
  Future<Coordinates?> loadCachedLocation() async {
    _log('Loading cached location');
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(AppConstants.cachedLatKey);
    final lon = prefs.getDouble(AppConstants.cachedLonKey);

    if (lat != null && lon != null) {
      final cached = Coordinates(lat: lat, lon: lon);
      _log('Cached location found', {'lat': lat, 'lon': lon});
      return cached;
    }

    _log('No cached location found');
    return null;
  }

  /// Saves location to SharedPreferences cache.
  Future<void> saveLocationToCache(Coordinates coordinates) async {
    _log('Saving location to cache', {
      'lat': coordinates.lat,
      'lon': coordinates.lon,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.cachedLatKey, coordinates.lat);
    await prefs.setDouble(AppConstants.cachedLonKey, coordinates.lon);
  }

  /// Initializes location with permission handling.
  /// Returns the current location or null if unavailable.
  /// [onPermissionDenied] is called when permission is denied.
  /// [onServiceDisabled] is called when location service is disabled.
  Future<LocationData?> initLocation({
    void Function(String message)? onPermissionDenied,
    void Function(String message)? onServiceDisabled,
  }) async {
    if (_locating) {
      _log('Already locating, returning null');
      return null;
    }

    _locating = true;
    _log('Starting location initialization');

    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _log('Location service disabled');
        onServiceDisabled?.call('Включите геолокацию на устройстве');
        await _locationService.openLocationSettings();
        return null;
      }

      var permission = await _locationService.checkPermission();
      _log('Current permission status', {'permission': permission.toString()});

      if (permission == LocationPermissionStatus.denied) {
        _log('Permission denied, requesting');
        permission = await _locationService.requestPermission();
      }

      if (permission == LocationPermissionStatus.permanentlyDenied) {
        _log('Permission permanently denied');
        onPermissionDenied?.call('Разрешите доступ к геолокации в настройках');
        return null;
      }

      if (permission != LocationPermissionStatus.granted) {
        _log('Permission not granted', {'permission': permission.toString()});
        onPermissionDenied?.call('Доступ к геолокации не предоставлен');
        return null;
      }

      _log('Permission granted, resolving location');
      final location = await _resolveCurrentLocation();

      if (location != null) {
        _lastUserLocation = location.coordinates;
        _lastLocationData = location;
        await saveLocationToCache(location.coordinates);
        _log('Location resolved', {
          'lat': location.coordinates.lat,
          'lon': location.coordinates.lon,
          'accuracy': location.accuracy,
        });
      } else {
        _log('Failed to resolve location');
      }

      return location;
    } finally {
      _locating = false;
    }
  }

  /// Resolves current location using direct method or stream fallback.
  Future<LocationData?> _resolveCurrentLocation() async {
    _log('Resolving current location');

    // Try direct method first
    final direct = await _locationService.getCurrentLocation(
      accuracy: LocationAccuracy.high,
    );

    if (direct != null) {
      _log('Got location from direct method');
      _lastLocationData = direct;
      return direct;
    }

    _log('Direct method failed, trying stream');

    // Fallback to stream
    try {
      await _locationService.startTracking(
        const LocationSettings(
          accuracy: LocationAccuracy.high,
          intervalMs: 1000,
          distanceFilter: 0,
        ),
      );
    } catch (e) {
      _log('Failed to start tracking', {'error': e.toString()});
    }

    final completer = Completer<LocationData?>();
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.locationStream.listen((location) {
      _lastLocationData = location;
      if (!completer.isCompleted) {
        _log('Got location from stream');
        completer.complete(location);
      }
    });

    final result = await completer.future.timeout(
      AppConstants.locationTimeout,
      onTimeout: () {
        _log('Location stream timeout');
        return null;
      },
    );

    _locationService.stopTracking();
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    return result;
  }

  /// Updates location state from external source (e.g., navigation).
  void updateLocation(LocationData? data) {
    if (data != null) {
      _lastLocationData = data;
      _lastUserLocation = data.coordinates;
    }
  }

  /// Gets fresh location, bypassing any cached values.
  ///
  /// Use this when you need the actual current position, not a cached one
  /// (e.g., before entering navigation mode).
  ///
  /// Uses stream-based approach which is more reliable after navigation ends.
  ///
  /// Returns null only if no location source is available within timeout.
  Future<LocationData?> getFreshLocation({
    Duration timeout = const Duration(seconds: 5),
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    _log('getFreshLocation START', {
      'timeout': timeout.inSeconds,
      'accuracy': accuracy.toString(),
    });

    try {
      // Try direct GPS method first
      final directLocation = await _locationService
          .getCurrentLocation(accuracy: accuracy)
          .timeout(
        Duration(seconds: (timeout.inSeconds / 2).ceil()),
        onTimeout: () => null,
      );

      if (directLocation != null) {
        _lastLocationData = directLocation;
        _lastUserLocation = directLocation.coordinates;
        _log('getFreshLocation SUCCESS from direct GPS', {
          'lat': directLocation.coordinates.lat,
          'lon': directLocation.coordinates.lon,
          'accuracy': directLocation.accuracy,
        });
        return directLocation;
      }

      _log('getFreshLocation direct failed, trying stream');

      // Fallback: Use stream-based approach (more reliable after nav ends)
      final streamLocation = await _getLocationFromStream(
        timeout: Duration(seconds: (timeout.inSeconds / 2).ceil()),
        accuracy: accuracy,
      );

      if (streamLocation != null) {
        _lastLocationData = streamLocation;
        _lastUserLocation = streamLocation.coordinates;
        _log('getFreshLocation SUCCESS from stream', {
          'lat': streamLocation.coordinates.lat,
          'lon': streamLocation.coordinates.lon,
          'accuracy': streamLocation.accuracy,
        });
        return streamLocation;
      }

      // Last resort: Use service's last known location
      final serviceLastLocation = _locationService.lastLocation;
      if (serviceLastLocation != null) {
        _lastLocationData = serviceLastLocation;
        _lastUserLocation = serviceLastLocation.coordinates;
        _log('getFreshLocation FALLBACK to lastLocation', {
          'lat': serviceLastLocation.coordinates.lat,
          'lon': serviceLastLocation.coordinates.lon,
          'timestamp': serviceLastLocation.timestamp.toIso8601String(),
        });
        return serviceLastLocation;
      }

      _log('getFreshLocation FAILED - no location available');
      return null;
    } catch (e, stack) {
      _log('getFreshLocation ERROR', {
        'error': e.toString(),
        'stack': stack.toString().split('\n').take(3).join(' | '),
      });
      return _lastLocationData;
    }
  }

  /// Gets location from stream with timeout.
  Future<LocationData?> _getLocationFromStream({
    required Duration timeout,
    required LocationAccuracy accuracy,
  }) async {
    final completer = Completer<LocationData?>();
    StreamSubscription<LocationData>? subscription;

    try {
      // Start tracking temporarily
      await _locationService.startTracking(
        LocationSettings(
          accuracy: accuracy,
          intervalMs: 500,
          distanceFilter: 0,
        ),
      );

      subscription = _locationService.locationStream.listen((location) {
        if (!completer.isCompleted) {
          completer.complete(location);
        }
      });

      // Wait for first location or timeout
      final result = await completer.future.timeout(
        timeout,
        onTimeout: () => null,
      );

      return result;
    } catch (e) {
      _log('_getLocationFromStream error', {'error': e.toString()});
      return null;
    } finally {
      await subscription?.cancel();
      _locationService.stopTracking();
    }
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[AppLocationService] $message$dataStr');
  }
}
