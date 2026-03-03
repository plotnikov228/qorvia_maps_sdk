import '../client/http_client.dart';
import '../models/quota/quota_response.dart';
import '../models/usage/usage_response.dart';
import '../config/transport_mode.dart';

/// Service for quota and usage information.
class QuotaService {
  final QorviaMapsHttpClient _client;

  QuotaService(this._client);

  /// Gets current quota information.
  ///
  /// Returns [QuotaResponse] with quota details.
  /// Throws [QorviaMapsException] on error.
  Future<QuotaResponse> getQuota() async {
    final data = await _client.get('/v1/mobile/quota');
    return QuotaResponse.fromJson(data);
  }

  /// Gets usage statistics for a period.
  ///
  /// [period] - Statistics period (default: today).
  ///
  /// Returns [UsageResponse] with usage details.
  /// Throws [QorviaMapsException] on error.
  Future<UsageResponse> getUsage({
    UsagePeriod period = UsagePeriod.today,
  }) async {
    final data = await _client.get('/v1/mobile/usage', queryParameters: {
      'period': period.value,
    });
    return UsageResponse.fromJson(data);
  }
}
