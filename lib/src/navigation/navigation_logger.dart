import 'dart:developer' as developer;

/// Log level for navigation system.
/// Levels are ordered by severity - higher levels include all lower levels.
enum NavigationLogLevel {
  /// No logging.
  none,

  /// Only errors (critical failures).
  error,

  /// Errors and warnings (potential issues).
  warn,

  /// Errors, warnings, and info (important events).
  info,

  /// All logs including debug (verbose tracing).
  debug,
}

/// Configurable logger for navigation system.
///
/// Provides consistent logging throughout navigation code with:
/// - Configurable log levels
/// - Structured data support
/// - Tag-based filtering
/// - Component-based filtering (enable/disable by component name)
/// - Performance-safe (no-op when level is below threshold)
///
/// Available components:
/// - `VoiceGuidance` - Voice announcements and TTS queue
/// - `NavigationController` - Step progression, route following
/// - `Camera` - Camera position updates
/// - `Location` - GPS location updates
/// - `Route` - Route calculations and display
///
/// Usage:
/// ```dart
/// // Set log level
/// NavigationLogger.level = NavigationLogLevel.debug;
///
/// // Enable only specific components
/// NavigationLogger.enableComponent('VoiceGuidance');
///
/// // Disable noisy components
/// NavigationLogger.disableComponent('Camera');
///
/// // Log with component tag
/// NavigationLogger.debug('VoiceGuidance', 'Speaking step', {'stepIndex': 0});
/// ```
class NavigationLogger {
  /// Current log level. Messages below this level are ignored.
  static NavigationLogLevel level = NavigationLogLevel.info;

  /// Optional callback for custom log handling (e.g., analytics, file logging).
  static void Function(NavigationLogLevel level, String tag, String message,
      Map<String, dynamic>? data)? onLog;

  /// Tags to filter (if empty, all tags are logged).
  /// @deprecated Use [enabledComponents] and [disabledComponents] instead.
  static Set<String> filterTags = {};

  /// Components explicitly enabled for logging.
  /// If empty, all components are enabled (unless in [disabledComponents]).
  /// If non-empty, ONLY these components will log.
  static final Set<String> _enabledComponents = {};

  /// Components explicitly disabled from logging.
  /// These components will never log, regardless of [_enabledComponents].
  static final Set<String> _disabledComponents = {};

  /// Enable logging for a specific component.
  ///
  /// When [_enabledComponents] is non-empty, only enabled components will log.
  /// Call [enableAllComponents] to reset to default (all enabled).
  static void enableComponent(String component) {
    _disabledComponents.remove(component);
    _enabledComponents.add(component);
  }

  /// Disable logging for a specific component.
  ///
  /// Disabled components never log, even if in [_enabledComponents].
  static void disableComponent(String component) {
    _enabledComponents.remove(component);
    _disabledComponents.add(component);
  }

  /// Check if a component is enabled for logging.
  static bool isComponentEnabled(String component) {
    // Disabled always takes precedence
    if (_disabledComponents.contains(component)) return false;
    // If enabled set is empty, all are enabled
    if (_enabledComponents.isEmpty) return true;
    // Otherwise, must be in enabled set
    return _enabledComponents.contains(component);
  }

  /// Enable all components (clear both enabled and disabled sets).
  static void enableAllComponents() {
    _enabledComponents.clear();
    _disabledComponents.clear();
  }

  /// Get set of currently enabled components (for debugging).
  static Set<String> get enabledComponents => Set.unmodifiable(_enabledComponents);

  /// Get set of currently disabled components (for debugging).
  static Set<String> get disabledComponents => Set.unmodifiable(_disabledComponents);

  /// Log a debug message (verbose tracing).
  ///
  /// Use for: position updates, prediction calculations, buffer states,
  /// interpolation details, frame-by-frame data.
  static void debug(String tag, String message, [Map<String, dynamic>? data]) {
    _log(NavigationLogLevel.debug, tag, message, data);
  }

  /// Log an info message (important events).
  ///
  /// Use for: navigation start/stop, route changes, mode switches,
  /// arrival, reroute triggers.
  static void info(String tag, String message, [Map<String, dynamic>? data]) {
    _log(NavigationLogLevel.info, tag, message, data);
  }

  /// Log a warning message (potential issues).
  ///
  /// Use for: off-route detection, low GPS accuracy, prediction fallbacks,
  /// configuration issues.
  static void warn(String tag, String message, [Map<String, dynamic>? data]) {
    _log(NavigationLogLevel.warn, tag, message, data);
  }

  /// Log an error message (critical failures).
  ///
  /// Use for: exceptions, failed operations, invalid states.
  /// Note: Errors still respect component filtering but always print
  /// to console if an exception is provided.
  static void error(String tag, String message,
      [Object? error, StackTrace? stackTrace]) {
    if (level == NavigationLogLevel.none) return;
    // Check component filter for structured logging
    final componentEnabled = isComponentEnabled(tag);

    final data = <String, dynamic>{};
    if (error != null) {
      data['error'] = error.toString();
    }
    if (stackTrace != null) {
      data['stackTrace'] = stackTrace.toString();
    }

    // Only log if component is enabled
    if (componentEnabled) {
      _log(NavigationLogLevel.error, tag, message, data.isNotEmpty ? data : null);
    }

    // Always print actual exceptions to console regardless of component filter
    // This ensures critical errors are never silently swallowed
    if (error != null) {
      developer.log(
        '[$tag] ERROR: $message',
        error: error,
        stackTrace: stackTrace,
        name: 'Navigation',
        level: 1000, // Severe
      );
    }
  }

  /// Internal log method.
  static void _log(
    NavigationLogLevel msgLevel,
    String tag,
    String message,
    Map<String, dynamic>? data,
  ) {
    // Check if logging is enabled for this level
    if (level == NavigationLogLevel.none) return;
    if (msgLevel.index > level.index) return;

    // Check component filter (new system)
    if (!isComponentEnabled(tag)) return;

    // Check tag filter (legacy, deprecated)
    if (filterTags.isNotEmpty && !filterTags.contains(tag)) return;

    // Format the message
    final buffer = StringBuffer();
    buffer.write('[${_levelPrefix(msgLevel)}]');
    buffer.write('[$tag] ');
    buffer.write(message);

    if (data != null && data.isNotEmpty) {
      buffer.write(' ');
      buffer.write(_formatData(data));
    }

    final formattedMessage = buffer.toString();

    // Call custom handler if set
    onLog?.call(msgLevel, tag, message, data);

    // Print to console
    developer.log(
      formattedMessage,
      name: 'Navigation',
      level: _levelToInt(msgLevel),
    );
  }

  /// Get prefix for log level.
  static String _levelPrefix(NavigationLogLevel lvl) {
    switch (lvl) {
      case NavigationLogLevel.none:
        return '';
      case NavigationLogLevel.error:
        return 'ERROR';
      case NavigationLogLevel.warn:
        return 'WARN';
      case NavigationLogLevel.info:
        return 'INFO';
      case NavigationLogLevel.debug:
        return 'DEBUG';
    }
  }

  /// Convert level to int for developer.log.
  static int _levelToInt(NavigationLogLevel lvl) {
    switch (lvl) {
      case NavigationLogLevel.none:
        return 0;
      case NavigationLogLevel.error:
        return 1000; // Severe
      case NavigationLogLevel.warn:
        return 900; // Warning
      case NavigationLogLevel.info:
        return 800; // Info
      case NavigationLogLevel.debug:
        return 500; // Fine
    }
  }

  /// Format data map for logging.
  static String _formatData(Map<String, dynamic> data) {
    final parts = <String>[];
    for (final entry in data.entries) {
      final value = _formatValue(entry.value);
      parts.add('${entry.key}=$value');
    }
    return '{${parts.join(', ')}}';
  }

  /// Format a single value for logging.
  static String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is double) return value.toStringAsFixed(4);
    if (value is Duration) return '${value.inMilliseconds}ms';
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  /// Reset logger to defaults.
  static void reset() {
    level = NavigationLogLevel.info;
    onLog = null;
    filterTags = {};
    _enabledComponents.clear();
    _disabledComponents.clear();
  }

  /// Enable verbose logging (debug level, all components).
  static void enableVerbose() {
    level = NavigationLogLevel.debug;
    filterTags = {};
    _enabledComponents.clear();
    _disabledComponents.clear();
  }

  /// Disable all logging.
  static void disable() {
    level = NavigationLogLevel.none;
  }

  /// Production mode: only warnings and errors.
  static void production() {
    level = NavigationLogLevel.warn;
    _enabledComponents.clear();
    _disabledComponents.clear();
  }

  /// Debug only voice guidance logs.
  static void debugVoiceOnly() {
    level = NavigationLogLevel.debug;
    _enabledComponents.clear();
    _disabledComponents.clear();
    enableComponent('VoiceGuidance');
  }

  /// Debug only navigation controller logs.
  static void debugNavigationOnly() {
    level = NavigationLogLevel.debug;
    _enabledComponents.clear();
    _disabledComponents.clear();
    enableComponent('NavigationController');
  }
}

/// Extension for easy logging from any navigation class.
extension NavigationLogging on Object {
  /// Get tag name from class.
  String get _logTag => runtimeType.toString();

  /// Log debug message with auto tag.
  void logDebug(String message, [Map<String, dynamic>? data]) {
    NavigationLogger.debug(_logTag, message, data);
  }

  /// Log info message with auto tag.
  void logInfo(String message, [Map<String, dynamic>? data]) {
    NavigationLogger.info(_logTag, message, data);
  }

  /// Log warning message with auto tag.
  void logWarn(String message, [Map<String, dynamic>? data]) {
    NavigationLogger.warn(_logTag, message, data);
  }

  /// Log error message with auto tag.
  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    NavigationLogger.error(_logTag, message, error, stackTrace);
  }
}
