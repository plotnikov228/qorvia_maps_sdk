/// Transport mode for route calculation.
enum TransportMode {
  /// Car/automobile routing.
  car('car'),

  /// Bicycle routing.
  bike('bike'),

  /// Pedestrian/walking routing.
  foot('foot'),

  /// Truck routing (with height/weight restrictions).
  truck('truck');

  final String value;

  const TransportMode(this.value);

  /// Creates TransportMode from string value.
  static TransportMode fromString(String value) {
    return TransportMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => TransportMode.car,
    );
  }
}

/// Period for usage statistics.
enum UsagePeriod {
  /// Today's usage.
  today('today'),

  /// Last 7 days usage.
  week('week'),

  /// Last 30 days usage.
  month('month');

  final String value;

  const UsagePeriod(this.value);
}
