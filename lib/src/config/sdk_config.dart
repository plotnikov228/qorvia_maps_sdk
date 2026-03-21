import '../offline/config/offline_config.dart';

/// Configuration for the Qorvia Maps SDK.
class SdkConfig {
  /// API key for authentication.
  final String apiKey;

  /// Base URL of the API server.
  final String baseUrl;

  /// Bundle ID of the application (for X-Bundle-Id header).
  /// If null, the SDK will try to resolve it lazily at runtime.
  final String? bundleId;

  /// Request timeout in milliseconds.
  final int timeoutMs;

  /// Number of retry attempts for failed requests.
  final int maxRetries;

  /// Whether to enable debug logging.
  final bool enableLogging;

  /// Whether to smooth decoded routes automatically.
  final bool routeSmoothingEnabled;

  /// Minimum turn angle (degrees) to apply smoothing.
  final double routeSmoothingMinAngleDegrees;

  /// Smoothing radius in meters.
  final double routeSmoothingRadius;

  /// Number of points to generate per smoothed corner.
  final int routeSmoothingPointsPerCorner;

  /// Polyline precision factor used for decoding route polylines.
  ///
  /// - 1e5 (100000) for Google / ORS / standard format (default)
  /// - 1e6 (1000000) for OSRM / Valhalla / Mapbox format
  final double polylinePrecision;

  /// Whether to send time headers (X-Local-Time, X-Timezone-Offset, X-Is-Daytime).
  /// These headers enable automatic theme switching on the server side.
  /// Only sent when [autoTheme] is true.
  final bool sendTimeHeaders;

  /// Whether to automatically select map theme based on time of day.
  ///
  /// When `true` (default): Time headers are sent and server returns
  /// the appropriate style URL (day or night) in `tile_url`.
  ///
  /// When `false`: Time headers are NOT sent. Server returns both URLs:
  /// - `tile_url` - day style URL
  /// - `night_tile_url` - night style URL (may be null if unavailable)
  /// - `is_night_mode` - server's recommendation based on location/time
  ///
  /// Use `autoTheme: false` when you need manual control over theme switching.
  final bool autoTheme;

  /// Configuration for offline mode.
  ///
  /// If null, offline mode is disabled.
  /// Set to [OfflineConfig()] to enable with default settings.
  final OfflineConfig? offlineConfig;

  /// Whether offline mode is enabled.
  bool get isOfflineEnabled => offlineConfig?.enabled ?? false;

  const SdkConfig({
    required this.apiKey,
    this.bundleId,
    this.baseUrl = 'https://qorviamapkit.ru',
    this.timeoutMs = 30000,
    this.maxRetries = 3,
    this.enableLogging = false,
    this.routeSmoothingEnabled = true,
    this.routeSmoothingMinAngleDegrees = 25,
    this.routeSmoothingRadius = 10,
    this.routeSmoothingPointsPerCorner = 5,
    this.polylinePrecision = 1e5,
    this.sendTimeHeaders = true,
    this.autoTheme = true,
    this.offlineConfig,
  });

  SdkConfig copyWith({
    String? apiKey,
    String? bundleId,
    String? baseUrl,
    int? timeoutMs,
    int? maxRetries,
    bool? enableLogging,
    bool? routeSmoothingEnabled,
    double? routeSmoothingMinAngleDegrees,
    double? routeSmoothingRadius,
    int? routeSmoothingPointsPerCorner,
    double? polylinePrecision,
    bool? sendTimeHeaders,
    bool? autoTheme,
    OfflineConfig? offlineConfig,
  }) {
    return SdkConfig(
      apiKey: apiKey ?? this.apiKey,
      bundleId: bundleId ?? this.bundleId,
      baseUrl: baseUrl ?? this.baseUrl,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      maxRetries: maxRetries ?? this.maxRetries,
      enableLogging: enableLogging ?? this.enableLogging,
      routeSmoothingEnabled:
          routeSmoothingEnabled ?? this.routeSmoothingEnabled,
      routeSmoothingMinAngleDegrees:
          routeSmoothingMinAngleDegrees ?? this.routeSmoothingMinAngleDegrees,
      routeSmoothingRadius:
          routeSmoothingRadius ?? this.routeSmoothingRadius,
      routeSmoothingPointsPerCorner:
          routeSmoothingPointsPerCorner ?? this.routeSmoothingPointsPerCorner,
      polylinePrecision: polylinePrecision ?? this.polylinePrecision,
      sendTimeHeaders: sendTimeHeaders ?? this.sendTimeHeaders,
      autoTheme: autoTheme ?? this.autoTheme,
      offlineConfig: offlineConfig ?? this.offlineConfig,
    );
  }
}
