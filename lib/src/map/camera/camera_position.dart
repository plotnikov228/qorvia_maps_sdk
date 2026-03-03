import 'package:equatable/equatable.dart';
import '../../models/coordinates.dart';

/// Represents the position of the map camera.
class CameraPosition extends Equatable {
  /// Center coordinates of the camera.
  final Coordinates center;

  /// Zoom level (0-22).
  final double zoom;

  /// Tilt angle in degrees (0-60).
  /// 0 = looking straight down, 60 = looking toward horizon.
  final double tilt;

  /// Bearing/rotation in degrees (0-360).
  /// 0 = north up, 90 = east up.
  final double bearing;

  const CameraPosition({
    required this.center,
    this.zoom = 14,
    this.tilt = 0,
    this.bearing = 0,
  })  : assert(zoom >= 0 && zoom <= 22, 'Zoom must be between 0 and 22'),
        assert(tilt >= 0 && tilt <= 60, 'Tilt must be between 0 and 60'),
        assert(bearing >= 0 && bearing < 360, 'Bearing must be between 0 and 360');

  /// Creates a camera position for navigation mode.
  factory CameraPosition.navigation({
    required Coordinates center,
    double zoom = 17,
    double bearing = 0,
  }) {
    return CameraPosition(
      center: center,
      zoom: zoom,
      tilt: 55,
      bearing: bearing,
    );
  }

  CameraPosition copyWith({
    Coordinates? center,
    double? zoom,
    double? tilt,
    double? bearing,
  }) {
    return CameraPosition(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      tilt: tilt ?? this.tilt,
      bearing: bearing ?? this.bearing,
    );
  }

  @override
  List<Object?> get props => [center, zoom, tilt, bearing];

  @override
  String toString() =>
      'CameraPosition(center: $center, zoom: $zoom, tilt: $tilt, bearing: $bearing)';
}

/// Describes a camera update/animation.
class CameraUpdate {
  final CameraPosition? _position;
  final Coordinates? _center;
  final double? _zoom;
  final double? _tilt;
  final double? _bearing;
  final List<Coordinates>? _bounds;
  final double? _boundsPadding;

  const CameraUpdate._({
    CameraPosition? position,
    Coordinates? center,
    double? zoom,
    double? tilt,
    double? bearing,
    List<Coordinates>? bounds,
    double? boundsPadding,
  })  : _position = position,
        _center = center,
        _zoom = zoom,
        _tilt = tilt,
        _bearing = bearing,
        _bounds = bounds,
        _boundsPadding = boundsPadding;

  /// Creates an update to a specific camera position.
  factory CameraUpdate.newCameraPosition(CameraPosition position) {
    return CameraUpdate._(position: position);
  }

  /// Creates an update to move to new center coordinates.
  factory CameraUpdate.newLatLng(Coordinates center) {
    return CameraUpdate._(center: center);
  }

  /// Creates an update to move to new center with zoom.
  factory CameraUpdate.newLatLngZoom(Coordinates center, double zoom) {
    return CameraUpdate._(center: center, zoom: zoom);
  }

  /// Creates an update to change zoom level.
  factory CameraUpdate.zoomTo(double zoom) {
    return CameraUpdate._(zoom: zoom);
  }

  /// Creates an update to zoom in by 1 level.
  factory CameraUpdate.zoomIn() {
    return const CameraUpdate._(zoom: 1);
  }

  /// Creates an update to zoom out by 1 level.
  factory CameraUpdate.zoomOut() {
    return const CameraUpdate._(zoom: -1);
  }

  /// Creates an update to change bearing.
  factory CameraUpdate.bearingTo(double bearing) {
    return CameraUpdate._(bearing: bearing);
  }

  /// Creates an update to change tilt.
  factory CameraUpdate.tiltTo(double tilt) {
    return CameraUpdate._(tilt: tilt);
  }

  /// Creates an update to fit bounds with padding.
  factory CameraUpdate.newLatLngBounds(
    List<Coordinates> bounds, {
    double padding = 50,
  }) {
    return CameraUpdate._(bounds: bounds, boundsPadding: padding);
  }

  CameraPosition? get position => _position;
  Coordinates? get center => _center;
  double? get zoom => _zoom;
  double? get tilt => _tilt;
  double? get bearing => _bearing;
  List<Coordinates>? get bounds => _bounds;
  double? get boundsPadding => _boundsPadding;
}
