/// Base exception for all SDK errors.
class QorviaMapsException implements Exception {
  /// Error message.
  final String message;

  /// Request ID for tracking.
  final String? requestId;

  /// HTTP status code if applicable.
  final int? statusCode;

  const QorviaMapsException({
    required this.message,
    this.requestId,
    this.statusCode,
  });

  @override
  String toString() => 'QorviaMapsException: $message (requestId: $requestId)';
}

/// 401 Unauthorized - Invalid or expired API key.
class AuthException extends QorviaMapsException {
  const AuthException({
    required super.message,
    super.requestId,
  }) : super(statusCode: 401);

  @override
  String toString() => 'AuthException: $message';
}

/// 403 Forbidden - Access denied to endpoint or resource.
class ForbiddenException extends QorviaMapsException {
  /// The endpoint or permission that was denied.
  final String? deniedPermission;

  const ForbiddenException({
    required super.message,
    super.requestId,
    this.deniedPermission,
  }) : super(statusCode: 403);

  @override
  String toString() => 'ForbiddenException: $message';
}

/// 429 Too Many Requests - Rate limit exceeded.
class RateLimitException extends QorviaMapsException {
  /// Seconds to wait before retrying.
  final int? retryAfter;

  const RateLimitException({
    required super.message,
    super.requestId,
    this.retryAfter,
  }) : super(statusCode: 429);

  @override
  String toString() => 'RateLimitException: $message (retry after: ${retryAfter}s)';
}

/// 400 Bad Request - Invalid request parameters.
class ValidationException extends QorviaMapsException {
  /// Field that failed validation.
  final String? field;

  const ValidationException({
    required super.message,
    super.requestId,
    this.field,
  }) : super(statusCode: 400);

  @override
  String toString() => 'ValidationException: $message';
}

/// 500 Internal Server Error - Server-side error.
class ServerException extends QorviaMapsException {
  const ServerException({
    required super.message,
    super.requestId,
  }) : super(statusCode: 500);

  @override
  String toString() => 'ServerException: $message';
}

/// Network error - No internet connection or timeout.
class NetworkException extends QorviaMapsException {
  const NetworkException({
    required super.message,
    super.requestId,
  }) : super(statusCode: null);

  @override
  String toString() => 'NetworkException: $message';
}

/// Offline error - No network and no cached data available.
class OfflineException extends QorviaMapsException {
  /// Type of data that was requested (e.g., 'geocode', 'route').
  final String? dataType;

  /// Search parameters that were used.
  final Map<String, dynamic>? searchParams;

  const OfflineException({
    required super.message,
    super.requestId,
    this.dataType,
    this.searchParams,
  }) : super(statusCode: null);

  @override
  String toString() =>
      'OfflineException: $message${dataType != null ? ' (type: $dataType)' : ''}';
}

/// Stale data warning - Data from cache is outdated but still returned.
///
/// This is not thrown as an exception, but can be used to indicate
/// that the returned data may be outdated.
class StaleDataInfo {
  /// Age of the cached data.
  final Duration age;

  /// When the data expires.
  final DateTime expiresAt;

  /// Whether the data has already expired.
  final bool isExpired;

  const StaleDataInfo({
    required this.age,
    required this.expiresAt,
    required this.isExpired,
  });

  @override
  String toString() =>
      'StaleDataInfo(age: ${age.inMinutes}min, expired: $isExpired)';
}
