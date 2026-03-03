import 'package:equatable/equatable.dart';

/// Usage statistics by endpoint.
class EndpointUsage extends Equatable {
  final int requests;
  final int units;

  const EndpointUsage({
    required this.requests,
    required this.units,
  });

  factory EndpointUsage.fromJson(Map<String, dynamic> json) {
    return EndpointUsage(
      requests: json['requests'] as int,
      units: json['units'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'requests': requests,
        'units': units,
      };

  @override
  List<Object?> get props => [requests, units];
}

/// Daily usage statistics.
class DailyUsage extends Equatable {
  final String date;
  final int requests;
  final int units;

  const DailyUsage({
    required this.date,
    required this.requests,
    required this.units,
  });

  factory DailyUsage.fromJson(Map<String, dynamic> json) {
    return DailyUsage(
      date: json['date'] as String,
      requests: json['requests'] as int,
      units: json['units'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'requests': requests,
        'units': units,
      };

  @override
  List<Object?> get props => [date, requests, units];
}

/// Response from the usage API.
class UsageResponse extends Equatable {
  /// Request identifier for tracking.
  final String requestId;

  /// Period of the statistics.
  final String period;

  /// Total requests in the period.
  final int totalRequests;

  /// Total units consumed in the period.
  final int totalUnits;

  /// Usage breakdown by endpoint.
  final Map<String, EndpointUsage> byEndpoint;

  /// Usage breakdown by day.
  final List<DailyUsage> byDay;

  const UsageResponse({
    required this.requestId,
    required this.period,
    required this.totalRequests,
    required this.totalUnits,
    required this.byEndpoint,
    required this.byDay,
  });

  factory UsageResponse.fromJson(Map<String, dynamic> json) {
    final byEndpointJson = json['by_endpoint'] as Map<String, dynamic>;
    final byEndpoint = byEndpointJson.map(
      (key, value) => MapEntry(
        key,
        EndpointUsage.fromJson(value as Map<String, dynamic>),
      ),
    );

    return UsageResponse(
      requestId: json['request_id'] as String,
      period: json['period'] as String,
      totalRequests: json['total_requests'] as int,
      totalUnits: json['total_units'] as int,
      byEndpoint: byEndpoint,
      byDay: (json['by_day'] as List)
          .map((e) => DailyUsage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'period': period,
        'total_requests': totalRequests,
        'total_units': totalUnits,
        'by_endpoint': byEndpoint.map((k, v) => MapEntry(k, v.toJson())),
        'by_day': byDay.map((e) => e.toJson()).toList(),
      };

  /// Returns usage for a specific endpoint.
  EndpointUsage? getEndpointUsage(String endpoint) => byEndpoint[endpoint];

  @override
  List<Object?> get props => [
        requestId,
        period,
        totalRequests,
        totalUnits,
        byEndpoint,
        byDay,
      ];
}
