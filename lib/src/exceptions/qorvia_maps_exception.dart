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
