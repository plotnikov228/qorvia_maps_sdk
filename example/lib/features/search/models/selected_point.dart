import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

/// Represents a selected location point with coordinates and display label.
class SelectedPoint {
  final Coordinates coordinates;
  final String label;

  /// Whether the address is still being resolved via reverse geocoding.
  final bool isLoading;

  const SelectedPoint({
    required this.coordinates,
    required this.label,
    this.isLoading = false,
  });

  /// Creates an empty/unset point.
  factory SelectedPoint.empty() => const SelectedPoint(
        coordinates: Coordinates(lat: 0, lon: 0),
        label: '',
      );

  /// Whether this point has been set (has non-empty label).
  bool get isSet => label.isNotEmpty;

  /// Returns a copy with the given fields replaced.
  SelectedPoint copyWith({
    Coordinates? coordinates,
    String? label,
    bool? isLoading,
  }) {
    return SelectedPoint(
      coordinates: coordinates ?? this.coordinates,
      label: label ?? this.label,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() => 'SelectedPoint($label, ${coordinates.lat}, ${coordinates.lon})';
}
