import '../navigation/navigation_logger.dart';

/// Public logging configuration for Base Maps SDK.
///
/// Use this class to configure logging behavior throughout the SDK.
/// All SDK components use the same underlying logger, so changes here
/// affect logging globally.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';
///
/// // Production mode - only warnings and errors
/// SdkLogger.production();
///
/// // Debug everything
/// SdkLogger.debugAll();
///
/// // Debug only voice guidance
/// SdkLogger.debugVoiceOnly();
/// ```
///
/// ## Component-Based Filtering
///
/// You can enable/disable logging for specific components:
///
/// ```dart
/// // Disable noisy camera logs
/// SdkLogger.disableComponent('Camera');
///
/// // Only log VoiceGuidance and NavigationController
/// SdkLogger.disableAll();
/// SdkLogger.enableComponent('VoiceGuidance');
/// SdkLogger.enableComponent('NavigationController');
/// ```
///
/// ## Available Components
///
/// - `VoiceGuidance` - Voice announcements and TTS queue
/// - `NavigationController` - Step progression, route following
/// - `Camera` - Camera position updates
/// - `Location` - GPS location updates
/// - `Route` - Route calculations and display
///
/// ## Custom Log Handler
///
/// You can add a custom handler for log events:
///
/// ```dart
/// SdkLogger.onLog = (level, tag, message, data) {
///   // Send to analytics, file, etc.
/// };
/// ```
class SdkLogger {
  SdkLogger._();

  // ============================================================
  // Log Level Configuration
  // ============================================================

  /// Current log level. Messages below this level are ignored.
  ///
  /// Levels in order of severity:
  /// - `none` - No logging
  /// - `error` - Only errors
  /// - `warn` - Errors and warnings
  /// - `info` - Errors, warnings, and info (default)
  /// - `debug` - All logs including verbose debug
  static NavigationLogLevel get level => NavigationLogger.level;
  static set level(NavigationLogLevel value) => NavigationLogger.level = value;

  /// Optional callback for custom log handling.
  ///
  /// Use this to send logs to analytics, file, or remote service.
  static void Function(
    NavigationLogLevel level,
    String tag,
    String message,
    Map<String, dynamic>? data,
  )? get onLog => NavigationLogger.onLog;
  static set onLog(
    void Function(
      NavigationLogLevel level,
      String tag,
      String message,
      Map<String, dynamic>? data,
    )? value,
  ) =>
      NavigationLogger.onLog = value;

  // ============================================================
  // Component Filtering
  // ============================================================

  /// Enable logging for a specific component.
  ///
  /// When using `enableComponent`, only enabled components will log
  /// (unless you call `enableAll` first).
  static void enableComponent(String component) {
    NavigationLogger.enableComponent(component);
  }

  /// Disable logging for a specific component.
  ///
  /// Disabled components never log, even if in the enabled set.
  static void disableComponent(String component) {
    NavigationLogger.disableComponent(component);
  }

  /// Check if a component is currently enabled.
  static bool isComponentEnabled(String component) {
    return NavigationLogger.isComponentEnabled(component);
  }

  /// Enable all components (clear both enabled and disabled sets).
  static void enableAll() {
    NavigationLogger.enableAllComponents();
  }

  /// Disable all components except those you explicitly enable later.
  ///
  /// After calling this, you must use `enableComponent()` to enable
  /// specific components.
  static void disableAll() {
    // Add all known components to disabled set
    NavigationLogger.disableComponent('VoiceGuidance');
    NavigationLogger.disableComponent('NavigationController');
    NavigationLogger.disableComponent('Camera');
    NavigationLogger.disableComponent('Location');
    NavigationLogger.disableComponent('Route');
  }

  /// Get set of currently enabled components (for debugging).
  static Set<String> get enabledComponents => NavigationLogger.enabledComponents;

  /// Get set of currently disabled components (for debugging).
  static Set<String> get disabledComponents => NavigationLogger.disabledComponents;

  // ============================================================
  // Convenience Methods for Specific Components
  // ============================================================

  /// Enable voice guidance logging.
  static void enableVoiceGuidance() => enableComponent('VoiceGuidance');

  /// Disable voice guidance logging.
  static void disableVoiceGuidance() => disableComponent('VoiceGuidance');

  /// Enable navigation controller logging.
  static void enableNavigation() => enableComponent('NavigationController');

  /// Disable navigation controller logging.
  static void disableNavigation() => disableComponent('NavigationController');

  /// Enable camera logging.
  static void enableCamera() => enableComponent('Camera');

  /// Disable camera logging.
  static void disableCamera() => disableComponent('Camera');

  /// Enable location logging.
  static void enableLocation() => enableComponent('Location');

  /// Disable location logging.
  static void disableLocation() => disableComponent('Location');

  // ============================================================
  // Presets
  // ============================================================

  /// Production mode: only warnings and errors.
  ///
  /// Use this for release builds to minimize log noise.
  static void production() {
    NavigationLogger.production();
  }

  /// Debug all components at debug level.
  ///
  /// Use this for development to see all logs.
  static void debugAll() {
    NavigationLogger.enableVerbose();
  }

  /// Debug only voice guidance logs.
  ///
  /// Useful when troubleshooting voice announcement issues.
  static void debugVoiceOnly() {
    NavigationLogger.debugVoiceOnly();
  }

  /// Debug only navigation controller logs.
  ///
  /// Useful when troubleshooting step progression or route following.
  static void debugNavigationOnly() {
    NavigationLogger.debugNavigationOnly();
  }

  /// Disable all logging.
  ///
  /// Use this to completely silence SDK logs.
  static void disable() {
    NavigationLogger.disable();
  }

  /// Reset to default configuration.
  ///
  /// Sets level to `info` and enables all components.
  static void reset() {
    NavigationLogger.reset();
  }
}
