import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/sdk_config.dart';
import '../exceptions/qorvia_maps_exception.dart';

/// HTTP client wrapper with authentication and error handling.
class QorviaMapsHttpClient {
  final SdkConfig _config;
  late final Dio _dio;

  QorviaMapsHttpClient(this._config) {
    _dio = Dio(BaseOptions(
      baseUrl: _config.baseUrl,
      connectTimeout: Duration(milliseconds: _config.timeoutMs),
      receiveTimeout: Duration(milliseconds: _config.timeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_config.bundleId != null) 'X-Bundle-Id': _config.bundleId,
      },
    ));

    _dio.interceptors.add(_BundleIdInterceptor(_config.bundleId));
    _dio.interceptors.add(_AuthInterceptor(_config.apiKey));

    // Time headers are only sent when autoTheme is enabled.
    // When autoTheme=false, server returns both day and night URLs.
    if (_config.sendTimeHeaders && _config.autoTheme) {
      _dio.interceptors.add(_TimeHeaderInterceptor());
    }

    if (_config.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }

    _dio.interceptors.add(_ErrorInterceptor());
  }

  /// Performs a GET request.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return response.data!;
  }

  /// Performs a POST request.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return response.data!;
  }

  /// Downloads a file from the given URL to the specified path.
  ///
  /// [url] - The URL to download from (can be relative or absolute).
  /// [savePath] - The local file path to save the downloaded file.
  /// [onProgress] - Optional callback for progress updates.
  /// [cancelToken] - Optional token to cancel the download.
  ///
  /// Example:
  /// ```dart
  /// await client.downloadFile(
  ///   '/v1/tiles/download/moscow.mbtiles',
  ///   '/path/to/save/moscow.mbtiles',
  ///   onProgress: (received, total) {
  ///     print('Progress: ${(received / total * 100).toStringAsFixed(0)}%');
  ///   },
  /// );
  /// ```
  Future<void> downloadFile(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    await _dio.download(
      url,
      savePath,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  /// Closes the client and releases resources.
  void close() {
    _dio.close();
  }
}

class _BundleIdResolver {
  static String? _bundleId;
  static Future<String?>? _inFlight;

  static Future<String?> resolve() {
    if (_bundleId != null) {
      return Future.value(_bundleId);
    }
    if (_inFlight != null) {
      return _inFlight!;
    }

    _inFlight = () async {
      try {
        final info = await PackageInfo.fromPlatform();
        _bundleId = info.packageName;
      } catch (_) {
        _bundleId = null;
      } finally {
        _inFlight = null;
      }
      return _bundleId;
    }();

    return _inFlight!;
  }
}

/// Interceptor that adds bundle id to all requests.
class _BundleIdInterceptor extends Interceptor {
  String? _bundleId;

  _BundleIdInterceptor(this._bundleId);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    () async {
      if (_bundleId != null) {
        options.headers['X-Bundle-Id'] = _bundleId;
        return;
      }

      final resolved = await _BundleIdResolver.resolve();
      if (resolved != null) {
        _bundleId = resolved;
        options.headers['X-Bundle-Id'] = resolved;
      }
    }()
        .then((_) => handler.next(options))
        .catchError((_) => handler.next(options));
  }
}

/// Interceptor that adds Bearer token to all requests.
class _AuthInterceptor extends Interceptor {
  final String apiKey;

  _AuthInterceptor(this.apiKey);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer $apiKey';
    handler.next(options);
  }
}

/// Interceptor that adds local time headers to all requests.
///
/// Adds the following headers:
/// - `X-Local-Time`: Current local time in ISO 8601 format
/// - `X-Timezone-Offset`: Timezone offset from UTC in minutes
/// - `X-Is-Daytime`: Whether it's daytime (6:00-18:00) as "true"/"false"
///
/// These headers can be used by the server for automatic theme switching
/// (e.g., dark theme at night, light theme during the day).
class _TimeHeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final now = DateTime.now();
    final hour = now.hour;
    final isDaytime = hour >= 6 && hour < 18;

    options.headers['X-Local-Time'] = now.toIso8601String();
    options.headers['X-Timezone-Offset'] = now.timeZoneOffset.inMinutes.toString();
    options.headers['X-Is-Daytime'] = isDaytime.toString();

    handler.next(options);
  }
}

/// Interceptor that converts HTTP errors to SDK exceptions.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapError(err);
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: exception,
      type: err.type,
      response: err.response,
    ));
  }

  QorviaMapsException _mapError(DioException err) {
    // Network errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return const NetworkException(
        message: 'Connection timeout. Please check your internet connection.',
      );
    }

    if (err.type == DioExceptionType.connectionError) {
      return const NetworkException(
        message: 'No internet connection.',
      );
    }

    // HTTP errors
    final response = err.response;
    if (response == null) {
      return NetworkException(
        message: err.message ?? 'Unknown network error',
      );
    }

    final data = response.data;
    final message = data is Map ? data['message'] as String? : null;
    final requestId = data is Map ? data['request_id'] as String? : null;

    switch (response.statusCode) {
      case 400:
        return ValidationException(
          message: message ?? 'Invalid request parameters',
          requestId: requestId,
        );
      case 401:
        return AuthException(
          message: message ?? 'Invalid or expired API key',
          requestId: requestId,
        );
      case 403:
        return ForbiddenException(
          message: message ?? 'Access denied',
          requestId: requestId,
        );
      case 429:
        final retryAfter = data is Map ? data['retry_after'] as int? : null;
        return RateLimitException(
          message: message ?? 'Rate limit exceeded',
          requestId: requestId,
          retryAfter: retryAfter,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          message: message ?? 'Server error. Please try again later.',
          requestId: requestId,
        );
      default:
        return QorviaMapsException(
          message: message ?? 'Unknown error (${response.statusCode})',
          requestId: requestId,
          statusCode: response.statusCode,
        );
    }
  }
}
