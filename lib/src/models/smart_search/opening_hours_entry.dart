import 'package:equatable/equatable.dart';

/// A single opening hours entry for a place.
///
/// Represents operating hours for a specific day.
class OpeningHoursEntry extends Equatable {
  /// Day of the week (e.g., "Пн", "Mon").
  final String day;

  /// Opening time in HH:MM format (e.g., "08:00").
  final String open;

  /// Closing time in HH:MM format (e.g., "22:00").
  final String close;

  const OpeningHoursEntry({
    required this.day,
    required this.open,
    required this.close,
  });

  factory OpeningHoursEntry.fromJson(Map<String, dynamic> json) {
    return OpeningHoursEntry(
      day: json['day'] as String,
      open: json['open'] as String,
      close: json['close'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'open': open,
        'close': close,
      };

  @override
  List<Object?> get props => [day, open, close];
}
