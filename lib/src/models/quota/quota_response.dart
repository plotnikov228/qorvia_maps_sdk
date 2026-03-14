import 'package:equatable/equatable.dart';

/// Response from the quota API.
class QuotaResponse extends Equatable {
  /// Request identifier for tracking.
  final String requestId;

  /// Current plan name.
  final String plan;

  /// Requests per minute limit.
  final int rateLimit;

  /// Daily units limit.
  final int dailyLimit;

  /// Daily units used.
  final int dailyUsed;

  /// Daily units remaining.
  final int dailyRemaining;

  /// Monthly units limit.
  final int monthlyLimit;

  /// Monthly units used.
  final int monthlyUsed;

  /// Monthly units remaining.
  final int monthlyRemaining;

  const QuotaResponse({
    required this.requestId,
    required this.plan,
    required this.rateLimit,
    required this.dailyLimit,
    required this.dailyUsed,
    required this.dailyRemaining,
    required this.monthlyLimit,
    required this.monthlyUsed,
    required this.monthlyRemaining,
  });

  factory QuotaResponse.fromJson(Map<String, dynamic> json) {
    return QuotaResponse(
      requestId: json['request_id'] as String? ?? '',
      plan: json['plan'] as String? ?? 'unknown',
      rateLimit: _parseInt(json['rate_limit']),
      dailyLimit: _parseInt(json['daily_limit']),
      dailyUsed: _parseInt(json['daily_used']),
      dailyRemaining: _parseInt(json['daily_remaining']),
      monthlyLimit: _parseInt(json['monthly_limit']),
      monthlyUsed: _parseInt(json['monthly_used']),
      monthlyRemaining: _parseInt(json['monthly_remaining']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'plan': plan,
        'rate_limit': rateLimit,
        'daily_limit': dailyLimit,
        'daily_used': dailyUsed,
        'daily_remaining': dailyRemaining,
        'monthly_limit': monthlyLimit,
        'monthly_used': monthlyUsed,
        'monthly_remaining': monthlyRemaining,
      };

  /// Percentage of daily quota used (0-100).
  double get dailyUsagePercent => (dailyUsed / dailyLimit) * 100;

  /// Percentage of monthly quota used (0-100).
  double get monthlyUsagePercent => (monthlyUsed / monthlyLimit) * 100;

  /// Returns true if daily limit is nearly exhausted (>90%).
  bool get isDailyLimitNear => dailyUsagePercent > 90;

  /// Returns true if monthly limit is nearly exhausted (>90%).
  bool get isMonthlyLimitNear => monthlyUsagePercent > 90;

  @override
  List<Object?> get props => [
        requestId,
        plan,
        rateLimit,
        dailyLimit,
        dailyUsed,
        dailyRemaining,
        monthlyLimit,
        monthlyUsed,
        monthlyRemaining,
      ];
}
