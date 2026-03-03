/// Accuracy level for location tracking.
enum LocationAccuracy {
  /// Low accuracy, minimal battery usage.
  low,

  /// Medium accuracy, balanced battery usage.
  medium,

  /// High accuracy, higher battery usage.
  high,

  /// Best available accuracy, highest battery usage.
  best,

  /// Optimized for navigation (high accuracy + frequent updates).
  navigation,
}

/// Settings for location tracking.
class LocationSettings {
  /// Desired accuracy level.
  final LocationAccuracy accuracy;

  /// Minimum distance (in meters) before an update is triggered.
  final int distanceFilter;

  /// Minimum time interval (in milliseconds) between updates.
  final int intervalMs;

  /// Whether to show location indicator even when app is in background.
  final bool allowBackgroundUpdates;

  const LocationSettings({
    this.accuracy = LocationAccuracy.best,
    this.distanceFilter = 10,
    this.intervalMs = 100,
    this.allowBackgroundUpdates = false,
  });

  /// Settings optimized for navigation.
  factory LocationSettings.navigation() {
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      intervalMs: 100, // ~10 updates/sec for smoother navigation
      allowBackgroundUpdates: true,
    );
  }

  /// Settings for general map usage (battery-friendly).
  factory LocationSettings.map() {
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 20,
      intervalMs: 3000,
      allowBackgroundUpdates: false,
    );
  }

  LocationSettings copyWith({
    LocationAccuracy? accuracy,
    int? distanceFilter,
    int? intervalMs,
    bool? allowBackgroundUpdates,
  }) {
    return LocationSettings(
      accuracy: accuracy ?? this.accuracy,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      intervalMs: intervalMs ?? this.intervalMs,
      allowBackgroundUpdates: allowBackgroundUpdates ?? this.allowBackgroundUpdates,
    );
  }
}
