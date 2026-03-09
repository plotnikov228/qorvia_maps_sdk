import 'package:drift/drift.dart';

/// Table for caching routing API responses.
///
/// Routes are cached by hash of origin, destination, waypoints, and transport mode.
class RouteCacheTable extends Table {
  @override
  String get tableName => 'route_cache';

  /// Auto-increment primary key
  IntColumn get id => integer().autoIncrement()();

  /// SHA-256 hash of route parameters for fast lookup
  TextColumn get routeHash => text().unique()();

  /// Origin latitude
  RealColumn get fromLat => real()();

  /// Origin longitude
  RealColumn get fromLon => real()();

  /// Destination latitude
  RealColumn get toLat => real()();

  /// Destination longitude
  RealColumn get toLon => real()();

  /// Serialized waypoints as JSON array (nullable if no waypoints)
  TextColumn get waypointsJson => text().nullable()();

  /// Transport mode (driving, walking, cycling, etc.)
  TextColumn get transportMode => text()();

  /// Serialized RouteResponse as JSON
  TextColumn get responseJson => text()();

  /// Timestamp when entry was created (milliseconds since epoch)
  IntColumn get createdAt => integer()();

  /// Timestamp when entry expires (milliseconds since epoch)
  IntColumn get expiresAt => integer()();
}
