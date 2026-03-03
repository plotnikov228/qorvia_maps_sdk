import '../models/models.dart';

/// Represents a selected address with coordinates and display label.
class SelectedAddress {
  /// The geographic coordinates of the address.
  final Coordinates coordinates;

  /// Human-readable label for the address.
  final String label;

  const SelectedAddress({
    required this.coordinates,
    required this.label,
  });

  /// Creates an empty/unset address.
  static const SelectedAddress empty = SelectedAddress(
    coordinates: Coordinates(lat: 0, lon: 0),
    label: '',
  );

  /// Whether this address has been set (has non-empty label).
  bool get isSet => label.isNotEmpty;

  /// Creates a copy with optional field overrides.
  SelectedAddress copyWith({
    Coordinates? coordinates,
    String? label,
  }) {
    return SelectedAddress(
      coordinates: coordinates ?? this.coordinates,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedAddress &&
          runtimeType == other.runtimeType &&
          coordinates == other.coordinates &&
          label == other.label;

  @override
  int get hashCode => coordinates.hashCode ^ label.hashCode;

  @override
  String toString() => 'SelectedAddress($label, $coordinates)';
}
