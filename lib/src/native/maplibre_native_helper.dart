import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native helper for MapLibre operations that aren't available in the plugin.
///
/// This class provides access to MapLibre's native offline database operations
/// to work around bugs and limitations in the maplibre_gl Flutter plugin.
///
/// ## Usage
///
/// ```dart
/// // Check if database exists
/// final exists = await MapLibreNativeHelper.checkDatabaseExists();
///
/// // Delete corrupted database
/// if (needsReset) {
///   await MapLibreNativeHelper.deleteOfflineDatabase();
/// }
/// ```
class MapLibreNativeHelper {
  static const _channel = MethodChannel('ru.qorviamapkit.maps_sdk/maplibre_helper');

  /// Deletes the MapLibre offline database file.
  ///
  /// This can fix "no such table: regions" errors caused by a corrupted database.
  ///
  /// **Important:** After calling this method, you must:
  /// 1. Restart the application
  /// 2. Display a map to create a new database
  /// 3. Then attempt offline downloads
  ///
  /// Returns `true` if the database was deleted, `false` if it didn't exist.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final deleted = await MapLibreNativeHelper.deleteOfflineDatabase();
  /// if (deleted) {
  ///   print('Database deleted. Please restart the app.');
  /// }
  /// ```
  static Future<bool> deleteOfflineDatabase() async {
    if (kIsWeb) return false;

    try {
      final result = await _channel.invokeMethod<bool>('deleteOfflineDatabase');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('MapLibreNativeHelper: Failed to delete offline database: ${e.message}');
      return false;
    } on MissingPluginException {
      debugPrint('MapLibreNativeHelper: Plugin not available on this platform');
      return false;
    }
  }

  /// Checks if the MapLibre offline database file exists.
  ///
  /// This can be used to verify if offline functionality has been initialized.
  ///
  /// Returns `true` if the database file exists.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final exists = await MapLibreNativeHelper.checkDatabaseExists();
  /// print('Database exists: $exists');
  /// ```
  static Future<bool> checkDatabaseExists() async {
    if (kIsWeb) return false;

    try {
      final result = await _channel.invokeMethod<bool>('checkDatabaseExists');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('MapLibreNativeHelper: Failed to check database: ${e.message}');
      return false;
    } on MissingPluginException {
      debugPrint('MapLibreNativeHelper: Plugin not available on this platform');
      return false;
    }
  }

  /// Gets the path to the MapLibre offline database file.
  ///
  /// This is useful for debugging and logging.
  ///
  /// Returns the absolute path to the database file, or `null` if unavailable.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final path = await MapLibreNativeHelper.getDatabasePath();
  /// print('Database path: $path');
  /// ```
  static Future<String?> getDatabasePath() async {
    if (kIsWeb) return null;

    try {
      final result = await _channel.invokeMethod<String>('getDatabasePath');
      return result;
    } on PlatformException catch (e) {
      debugPrint('MapLibreNativeHelper: Failed to get database path: ${e.message}');
      return null;
    } on MissingPluginException {
      debugPrint('MapLibreNativeHelper: Plugin not available on this platform');
      return null;
    }
  }

  /// Gets the size of the MapLibre offline database file in bytes.
  ///
  /// Returns the size in bytes, or 0 if the file doesn't exist.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final size = await MapLibreNativeHelper.getDatabaseSize();
  /// print('Database size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
  /// ```
  static Future<int> getDatabaseSize() async {
    if (kIsWeb) return 0;

    try {
      final result = await _channel.invokeMethod<int>('getDatabaseSize');
      return result ?? 0;
    } on PlatformException catch (e) {
      debugPrint('MapLibreNativeHelper: Failed to get database size: ${e.message}');
      return 0;
    } on MissingPluginException {
      debugPrint('MapLibreNativeHelper: Plugin not available on this platform');
      return 0;
    }
  }

  /// Gets database information as a formatted string.
  ///
  /// Useful for displaying in debug UI.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final info = await MapLibreNativeHelper.getDatabaseInfo();
  /// showDialog(
  ///   context: context,
  ///   builder: (_) => AlertDialog(content: Text(info)),
  /// );
  /// ```
  static Future<String> getDatabaseInfo() async {
    final exists = await checkDatabaseExists();
    final path = await getDatabasePath();
    final size = await getDatabaseSize();

    final sizeMb = (size / 1024 / 1024).toStringAsFixed(2);

    return '''
Database Info:
- Exists: $exists
- Path: ${path ?? 'unknown'}
- Size: $sizeMb MB ($size bytes)
''';
  }
}
