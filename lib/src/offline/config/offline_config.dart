/// Configuration for offline mode features.
///
/// Controls caching behavior, TTL for different data types,
/// and storage limits for offline support.
///
/// ## Example
///
/// ```dart
/// await QorviaMapsSDK.init(
///   apiKey: 'your_api_key',
///   offlineConfig: OfflineConfig(
///     enabled: true,
///     geocodeTtl: Duration(hours: 48),
///     routeTtl: Duration(hours: 2),
///   ),
/// );
/// ```
class OfflineConfig {
  /// Whether offline mode is enabled.
  ///
  /// When enabled, API responses are cached and used when offline.
  final bool enabled;

  /// Time-to-live for geocoding cache entries.
  ///
  /// Geocoding results change infrequently, so a longer TTL is recommended.
  /// Default: 24 hours.
  final Duration geocodeTtl;

  /// Time-to-live for routing cache entries.
  ///
  /// Routes can change due to traffic, so a shorter TTL is recommended.
  /// Default: 1 hour.
  final Duration routeTtl;

  /// Time-to-live for reverse geocoding cache entries.
  ///
  /// Default: 6 hours.
  final Duration reverseTtl;

  /// Time-to-live for smart search cache entries.
  ///
  /// Default: 12 hours.
  final Duration smartSearchTtl;

  /// Maximum number of geocoding entries to cache.
  ///
  /// Oldest entries are removed when limit is exceeded (LRU).
  /// Default: 100.
  final int maxGeocodeEntries;

  /// Maximum number of routing entries to cache.
  ///
  /// Default: 50.
  final int maxRouteEntries;

  /// Maximum number of reverse geocoding entries to cache.
  ///
  /// Default: 200.
  final int maxReverseEntries;

  /// Maximum number of smart search entries to cache.
  ///
  /// Default: 100.
  final int maxSmartSearchEntries;

  /// Whether to clean up expired entries on startup.
  ///
  /// When enabled, the SDK will remove expired cache entries during
  /// initialization. This keeps the cache size manageable.
  /// Default: true.
  final bool cleanupOnStartup;

  /// Custom path for the cache database.
  ///
  /// If null, the default application documents directory is used.
  final String? customDatabasePath;

  const OfflineConfig({
    this.enabled = true,
    this.geocodeTtl = const Duration(hours: 24),
    this.routeTtl = const Duration(hours: 1),
    this.reverseTtl = const Duration(hours: 6),
    this.smartSearchTtl = const Duration(hours: 12),
    this.maxGeocodeEntries = 100,
    this.maxRouteEntries = 50,
    this.maxReverseEntries = 200,
    this.maxSmartSearchEntries = 100,
    this.cleanupOnStartup = true,
    this.customDatabasePath,
  });

  /// Creates a disabled offline config.
  ///
  /// Use this when you want to explicitly disable offline mode.
  const OfflineConfig.disabled() : this(enabled: false);

  /// Creates a config with extended TTLs for better offline experience.
  ///
  /// Useful for applications that expect users to be offline frequently.
  const OfflineConfig.extended()
      : this(
          enabled: true,
          geocodeTtl: const Duration(days: 7),
          routeTtl: const Duration(hours: 6),
          reverseTtl: const Duration(days: 1),
          smartSearchTtl: const Duration(days: 1),
          maxGeocodeEntries: 500,
          maxRouteEntries: 100,
          maxReverseEntries: 500,
          maxSmartSearchEntries: 200,
        );

  OfflineConfig copyWith({
    bool? enabled,
    Duration? geocodeTtl,
    Duration? routeTtl,
    Duration? reverseTtl,
    Duration? smartSearchTtl,
    int? maxGeocodeEntries,
    int? maxRouteEntries,
    int? maxReverseEntries,
    int? maxSmartSearchEntries,
    bool? cleanupOnStartup,
    String? customDatabasePath,
  }) {
    return OfflineConfig(
      enabled: enabled ?? this.enabled,
      geocodeTtl: geocodeTtl ?? this.geocodeTtl,
      routeTtl: routeTtl ?? this.routeTtl,
      reverseTtl: reverseTtl ?? this.reverseTtl,
      smartSearchTtl: smartSearchTtl ?? this.smartSearchTtl,
      maxGeocodeEntries: maxGeocodeEntries ?? this.maxGeocodeEntries,
      maxRouteEntries: maxRouteEntries ?? this.maxRouteEntries,
      maxReverseEntries: maxReverseEntries ?? this.maxReverseEntries,
      maxSmartSearchEntries:
          maxSmartSearchEntries ?? this.maxSmartSearchEntries,
      cleanupOnStartup: cleanupOnStartup ?? this.cleanupOnStartup,
      customDatabasePath: customDatabasePath ?? this.customDatabasePath,
    );
  }

  @override
  String toString() {
    return 'OfflineConfig('
        'enabled: $enabled, '
        'geocodeTtl: ${geocodeTtl.inHours}h, '
        'routeTtl: ${routeTtl.inMinutes}m, '
        'reverseTtl: ${reverseTtl.inHours}h, '
        'smartSearchTtl: ${smartSearchTtl.inHours}h, '
        'maxGeocodeEntries: $maxGeocodeEntries, '
        'maxRouteEntries: $maxRouteEntries, '
        'maxReverseEntries: $maxReverseEntries, '
        'maxSmartSearchEntries: $maxSmartSearchEntries, '
        'cleanupOnStartup: $cleanupOnStartup'
        ')';
  }
}
