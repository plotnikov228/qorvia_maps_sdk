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
  final bool sendTimeHeaders;

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
    );
  }
}
