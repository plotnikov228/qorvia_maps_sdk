import 'package:equatable/equatable.dart';
import '../models/coordinates.dart';
import 'marker_icon.dart';

/// A marker that can be placed on the map.
class Marker extends Equatable {
  /// Unique identifier for this marker.
  final String id;

  /// Position of the marker on the map.
  final Coordinates position;

  /// Icon to display for this marker.
  final MarkerIcon icon;

  /// Anchor point relative to the icon (0,0 = top-left, 1,1 = bottom-right).
  final MarkerAnchor anchor;

  /// Rotation angle in degrees (clockwise from north).
  final double rotation;

  /// Whether the marker should rotate with the map.
  final bool rotateWithMap;

  /// Whether the marker is draggable.
  final bool draggable;

  /// Whether the marker is visible.
  final bool visible;

  /// Optional z-index for stacking order.
  final int zIndex;

  /// Optional data associated with this marker.
  final dynamic data;

  const Marker({
    required this.id,
    required this.position,
    required this.icon,
    this.anchor = MarkerAnchor.bottom,
    this.rotation = 0,
    this.rotateWithMap = false,
    this.draggable = false,
    this.visible = true,
    this.zIndex = 0,
    this.data,
  });

  Marker copyWith({
    String? id,
    Coordinates? position,
    MarkerIcon? icon,
    MarkerAnchor? anchor,
    double? rotation,
    bool? rotateWithMap,
    bool? draggable,
    bool? visible,
    int? zIndex,
    dynamic data,
  }) {
    return Marker(
      id: id ?? this.id,
      position: position ?? this.position,
      icon: icon ?? this.icon,
      anchor: anchor ?? this.anchor,
      rotation: rotation ?? this.rotation,
      rotateWithMap: rotateWithMap ?? this.rotateWithMap,
      draggable: draggable ?? this.draggable,
      visible: visible ?? this.visible,
      zIndex: zIndex ?? this.zIndex,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [
        id,
        position,
        icon,
        anchor,
        rotation,
        rotateWithMap,
        draggable,
        visible,
        zIndex,
      ];
}

/// Anchor point for marker icons.
class MarkerAnchor {
  final double x;
  final double y;

  const MarkerAnchor(this.x, this.y);

  /// Anchor at the center of the icon.
  static const MarkerAnchor center = MarkerAnchor(0.5, 0.5);

  /// Anchor at the top-left corner.
  static const MarkerAnchor topLeft = MarkerAnchor(0, 0);

  /// Anchor at the top-center.
  static const MarkerAnchor top = MarkerAnchor(0.5, 0);

  /// Anchor at the top-right corner.
  static const MarkerAnchor topRight = MarkerAnchor(1, 0);

  /// Anchor at the center-left.
  static const MarkerAnchor left = MarkerAnchor(0, 0.5);

  /// Anchor at the center-right.
  static const MarkerAnchor right = MarkerAnchor(1, 0.5);

  /// Anchor at the bottom-left corner.
  static const MarkerAnchor bottomLeft = MarkerAnchor(0, 1);

  /// Anchor at the bottom-center (default for pin-style markers).
  static const MarkerAnchor bottom = MarkerAnchor(0.5, 1);

  /// Anchor at the bottom-right corner.
  static const MarkerAnchor bottomRight = MarkerAnchor(1, 1);
}
