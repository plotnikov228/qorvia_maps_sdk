import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

import '../../../core/localization/app_localizations.dart';

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
  /// Use [localizedName] with context for proper localization.
  String get displayName {
    switch (this) {
      case TravelMode.car:
        return 'Car';
      case TravelMode.foot:
        return 'Walk';
      case TravelMode.bike:
        return 'Bike';
    }
  }

  /// Returns the localized name for this travel mode using context.
  String localizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case TravelMode.car:
        return l10n.car;
      case TravelMode.foot:
        return l10n.foot;
      case TravelMode.bike:
        return l10n.bike;
    }
  }
}
