import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

/// Travel mode options for routing.
enum TravelMode {
  car,
  foot,
  bike;

  /// Returns the corresponding SDK transport mode.
  TransportMode get transportMode {
    switch (this) {
      case TravelMode.car:
        return TransportMode.car;
      case TravelMode.foot:
        return TransportMode.foot;
      case TravelMode.bike:
        return TransportMode.bike;
    }
  }

  /// Returns the icon for this travel mode.
  IconData get icon {
    switch (this) {
      case TravelMode.car:
        return Icons.directions_car;
      case TravelMode.foot:
        return Icons.directions_walk;
      case TravelMode.bike:
        return Icons.directions_bike;
    }
  }

  /// Returns the localized name for this travel mode.
  String get displayName {
    switch (this) {
      case TravelMode.car:
        return 'Авто';
      case TravelMode.foot:
        return 'Пешком';
      case TravelMode.bike:
        return 'Вело';
    }
  }
}
