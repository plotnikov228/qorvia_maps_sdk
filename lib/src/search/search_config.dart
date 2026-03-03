import 'package:flutter/material.dart';

/// Configuration for [AddressSearchField].
class AddressSearchFieldConfig {
  /// Label text displayed in the field.
  final String label;

  /// Hint text when field is empty.
  final String? hint;

  /// Whether to show the "select on map" button.
  final bool showMapSelectButton;

  /// Text for the map select button.
  final String mapSelectButtonText;

  /// Debounce duration for search.
  final Duration searchDebounce;

  /// Border radius of the field container.
  final double borderRadius;

  /// Background color of the field.
  final Color? backgroundColor;

  /// Border color of the field.
  final Color? borderColor;

  const AddressSearchFieldConfig({
    required this.label,
    this.hint,
    this.showMapSelectButton = true,
    this.mapSelectButtonText = 'На карте',
    this.searchDebounce = const Duration(milliseconds: 450),
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderColor,
  });

  AddressSearchFieldConfig copyWith({
    String? label,
    String? hint,
    bool? showMapSelectButton,
    String? mapSelectButtonText,
    Duration? searchDebounce,
    double? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return AddressSearchFieldConfig(
      label: label ?? this.label,
      hint: hint ?? this.hint,
      showMapSelectButton: showMapSelectButton ?? this.showMapSelectButton,
      mapSelectButtonText: mapSelectButtonText ?? this.mapSelectButtonText,
      searchDebounce: searchDebounce ?? this.searchDebounce,
      borderRadius: borderRadius ?? this.borderRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }
}

/// Configuration for [SearchPanel].
class SearchPanelConfig {
  /// Configuration for the "from" field.
  final AddressSearchFieldConfig fromFieldConfig;

  /// Configuration for the "to" field.
  final AddressSearchFieldConfig toFieldConfig;

  /// Whether to show waypoints functionality.
  final bool enableWaypoints;

  /// Maximum number of waypoints allowed.
  final int maxWaypoints;

  /// Text for the "add waypoint" button.
  final String addWaypointText;

  /// Whether to show transport mode selector.
  final bool showTransportModeSelector;

  /// Whether to show "my location" button.
  final bool showMyLocationButton;

  /// Text for the "my location" button.
  final String myLocationButtonText;

  /// Whether to show "reset" button.
  final bool showResetButton;

  /// Text for the "reset" button.
  final String resetButtonText;

  /// Whether to show route info card when route is available.
  final bool showRouteInfo;

  /// Border radius of the panel.
  final double borderRadius;

  /// Background color of the panel.
  final Color? backgroundColor;

  /// Language for geocoding requests.
  final String language;

  const SearchPanelConfig({
    this.fromFieldConfig = const AddressSearchFieldConfig(label: 'Откуда'),
    this.toFieldConfig = const AddressSearchFieldConfig(label: 'Куда'),
    this.enableWaypoints = true,
    this.maxWaypoints = 10,
    this.addWaypointText = 'Добавить точку',
    this.showTransportModeSelector = true,
    this.showMyLocationButton = true,
    this.myLocationButtonText = 'Моя локация',
    this.showResetButton = true,
    this.resetButtonText = 'Сбросить',
    this.showRouteInfo = true,
    this.borderRadius = 28,
    this.backgroundColor,
    this.language = 'ru',
  });

  SearchPanelConfig copyWith({
    AddressSearchFieldConfig? fromFieldConfig,
    AddressSearchFieldConfig? toFieldConfig,
    bool? enableWaypoints,
    int? maxWaypoints,
    String? addWaypointText,
    bool? showTransportModeSelector,
    bool? showMyLocationButton,
    String? myLocationButtonText,
    bool? showResetButton,
    String? resetButtonText,
    bool? showRouteInfo,
    double? borderRadius,
    Color? backgroundColor,
    String? language,
  }) {
    return SearchPanelConfig(
      fromFieldConfig: fromFieldConfig ?? this.fromFieldConfig,
      toFieldConfig: toFieldConfig ?? this.toFieldConfig,
      enableWaypoints: enableWaypoints ?? this.enableWaypoints,
      maxWaypoints: maxWaypoints ?? this.maxWaypoints,
      addWaypointText: addWaypointText ?? this.addWaypointText,
      showTransportModeSelector:
          showTransportModeSelector ?? this.showTransportModeSelector,
      showMyLocationButton: showMyLocationButton ?? this.showMyLocationButton,
      myLocationButtonText: myLocationButtonText ?? this.myLocationButtonText,
      showResetButton: showResetButton ?? this.showResetButton,
      resetButtonText: resetButtonText ?? this.resetButtonText,
      showRouteInfo: showRouteInfo ?? this.showRouteInfo,
      borderRadius: borderRadius ?? this.borderRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      language: language ?? this.language,
    );
  }
}

/// Represents the active field in SearchPanel.
enum SearchFieldType {
  from,
  to,
  waypoint,
}

/// State of the currently focused field.
class ActiveSearchField {
  final SearchFieldType type;
  final int? waypointIndex;

  const ActiveSearchField({
    required this.type,
    this.waypointIndex,
  });

  const ActiveSearchField.from() : type = SearchFieldType.from, waypointIndex = null;
  const ActiveSearchField.to() : type = SearchFieldType.to, waypointIndex = null;
  const ActiveSearchField.waypoint(int index)
      : type = SearchFieldType.waypoint,
        waypointIndex = index;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveSearchField &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          waypointIndex == other.waypointIndex;

  @override
  int get hashCode => type.hashCode ^ waypointIndex.hashCode;
}
