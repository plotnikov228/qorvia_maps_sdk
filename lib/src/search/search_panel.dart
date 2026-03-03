import 'dart:async';

import 'package:flutter/material.dart';

import '../client/qorvia_maps_client.dart';
import '../config/transport_mode.dart';
import '../location/location_service.dart';
import '../location/location_settings.dart';
import '../models/models.dart';
import '../sdk_initializer.dart';
import 'search_config.dart';
import 'selected_address.dart';

/// A complete search panel widget for route planning.
///
/// This widget provides:
/// - "From" and "To" address fields with autocomplete
/// - Waypoints support (add/remove intermediate points)
/// - Transport mode selector (car, foot, bike)
/// - "My location" and "Reset" buttons
/// - Route info display
/// - Focus mode: hides non-essential elements when a field is focused
///
/// Example:
/// ```dart
/// SearchPanel(
///   onRouteRequested: (from, to, waypoints, mode) async {
///     return await client.route(from: from, to: to, waypoints: waypoints, mode: mode);
///   },
///   onNavigationStart: () {
///     // Start navigation
///   },
/// )
/// ```
class SearchPanel extends StatefulWidget {
  /// Configuration for the panel.
  final SearchPanelConfig config;

  /// Called when a route should be calculated.
  final Future<RouteResponse?> Function(
    Coordinates from,
    Coordinates to,
    List<Coordinates>? waypoints,
    TransportMode mode,
  )? onRouteRequested;

  /// Called when the navigation button is pressed.
  final VoidCallback? onNavigationStart;

  /// Called when "select on map" is pressed for a field.
  final void Function(SearchFieldType type, int? waypointIndex)?
      onMapSelectRequested;

  /// Called when the panel state changes (for external state management).
  final void Function(SearchPanelState state)? onStateChanged;

  /// Custom client for geocoding (uses SDK client if not provided).
  final QorviaMapsClient? client;

  /// Custom location service (creates new one if not provided).
  final LocationService? locationService;

  /// Initial "from" address.
  final SelectedAddress? initialFrom;

  /// Initial "to" address.
  final SelectedAddress? initialTo;

  /// Initial waypoints.
  final List<SelectedAddress>? initialWaypoints;

  /// Initial transport mode.
  final TransportMode initialMode;

  const SearchPanel({
    super.key,
    this.config = const SearchPanelConfig(),
    this.onRouteRequested,
    this.onNavigationStart,
    this.onMapSelectRequested,
    this.onStateChanged,
    this.client,
    this.locationService,
    this.initialFrom,
    this.initialTo,
    this.initialWaypoints,
    this.initialMode = TransportMode.car,
  });

  @override
  State<SearchPanel> createState() => SearchPanelState();
}

/// Public state class for external access to panel state.
class SearchPanelState extends State<SearchPanel> {
  // State
  SelectedAddress? _fromAddress;
  SelectedAddress? _toAddress;
  final List<SelectedAddress> _waypoints = [];
  TransportMode _transportMode = TransportMode.car;
  RouteResponse? _activeRoute;
  bool _isSearchFocused = false;
  ActiveSearchField? _activeField;
  bool _isLocating = false;
  bool _isRouting = false;

  // Controllers and focus nodes
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();
  final List<TextEditingController> _waypointControllers = [];
  final List<FocusNode> _waypointFocusNodes = [];

  // Services
  late LocationService _locationService;
  bool _ownsLocationService = false;

  // Getters for external access
  SelectedAddress? get fromAddress => _fromAddress;
  SelectedAddress? get toAddress => _toAddress;
  List<SelectedAddress> get waypoints => List.unmodifiable(_waypoints);
  TransportMode get transportMode => _transportMode;
  RouteResponse? get activeRoute => _activeRoute;
  bool get isSearchFocused => _isSearchFocused;
  bool get canRoute =>
      _fromAddress != null &&
      _fromAddress!.isSet &&
      _toAddress != null &&
      _toAddress!.isSet;

  QorviaMapsClient get _client => widget.client ?? QorviaMapsSDK.instance.client;

  @override
  void initState() {
    super.initState();
    debugPrint('[SearchPanel] initState');

    _fromAddress = widget.initialFrom;
    _toAddress = widget.initialTo;
    _transportMode = widget.initialMode;

    if (widget.initialWaypoints != null) {
      for (final wp in widget.initialWaypoints!) {
        _addWaypointWithAddress(wp);
      }
    }

    if (_fromAddress != null) {
      _fromController.text = _fromAddress!.label;
    }
    if (_toAddress != null) {
      _toController.text = _toAddress!.label;
    }

    _fromFocus.addListener(_onFocusChange);
    _toFocus.addListener(_onFocusChange);

    if (widget.locationService != null) {
      _locationService = widget.locationService!;
      _ownsLocationService = false;
    } else {
      _locationService = LocationService();
      _ownsLocationService = true;
    }
  }

  @override
  void dispose() {
    debugPrint('[SearchPanel] dispose');
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    for (final c in _waypointControllers) {
      c.dispose();
    }
    for (final f in _waypointFocusNodes) {
      f.dispose();
    }
    if (_ownsLocationService) {
      _locationService.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    final anyFocused = _fromFocus.hasFocus ||
        _toFocus.hasFocus ||
        _waypointFocusNodes.any((f) => f.hasFocus);

    debugPrint('[SearchPanel] Focus changed: $anyFocused');

    setState(() {
      _isSearchFocused = anyFocused;

      if (_fromFocus.hasFocus) {
        _activeField = const ActiveSearchField.from();
      } else if (_toFocus.hasFocus) {
        _activeField = const ActiveSearchField.to();
      } else {
        for (int i = 0; i < _waypointFocusNodes.length; i++) {
          if (_waypointFocusNodes[i].hasFocus) {
            _activeField = ActiveSearchField.waypoint(i);
            break;
          }
        }
      }

      if (!anyFocused) {
        _activeField = null;
      }
    });

    _notifyStateChanged();
  }

  void _notifyStateChanged() {
    widget.onStateChanged?.call(this);
  }

  /// Unfocus all fields and clear results.
  void unfocus() {
    debugPrint('[SearchPanel] unfocus');
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearchFocused = false;
      _activeField = null;
    });
  }

  /// Set the "from" address programmatically.
  void setFromAddress(SelectedAddress address) {
    debugPrint('[SearchPanel] setFromAddress: ${address.label}');
    setState(() {
      _fromAddress = address;
      _fromController.text = address.label;
    });
    _updateRoute();
    _notifyStateChanged();
  }

  /// Set the "to" address programmatically.
  void setToAddress(SelectedAddress address) {
    debugPrint('[SearchPanel] setToAddress: ${address.label}');
    setState(() {
      _toAddress = address;
      _toController.text = address.label;
    });
    _updateRoute();
    _notifyStateChanged();
  }

  /// Set a waypoint address programmatically.
  void setWaypointAddress(int index, SelectedAddress address) {
    if (index < 0 || index >= _waypoints.length) return;
    debugPrint('[SearchPanel] setWaypointAddress[$index]: ${address.label}');
    setState(() {
      _waypoints[index] = address;
      _waypointControllers[index].text = address.label;
    });
    _updateRoute();
    _notifyStateChanged();
  }

  /// Reset all fields and state.
  void reset() {
    debugPrint('[SearchPanel] reset');
    setState(() {
      _fromAddress = null;
      _toAddress = null;
      _fromController.clear();
      _toController.clear();
      _activeRoute = null;

      for (final c in _waypointControllers) {
        c.dispose();
      }
      for (final f in _waypointFocusNodes) {
        f.dispose();
      }
      _waypoints.clear();
      _waypointControllers.clear();
      _waypointFocusNodes.clear();
    });
    _notifyStateChanged();
  }

  void _addWaypoint() {
    _addWaypointWithAddress(SelectedAddress.empty);
  }

  void _addWaypointWithAddress(SelectedAddress address) {
    final controller = TextEditingController(text: address.label);
    final focusNode = FocusNode();
    final index = _waypoints.length;

    focusNode.addListener(() {
      _onFocusChange();
      if (focusNode.hasFocus) {
        setState(() {
          _activeField = ActiveSearchField.waypoint(index);
        });
      }
    });

    setState(() {
      _waypoints.add(address);
      _waypointControllers.add(controller);
      _waypointFocusNodes.add(focusNode);
    });
    _notifyStateChanged();
  }

  void _removeWaypoint(int index) {
    debugPrint('[SearchPanel] removeWaypoint[$index]');
    setState(() {
      _waypoints.removeAt(index);
      _waypointControllers[index].dispose();
      _waypointControllers.removeAt(index);
      _waypointFocusNodes[index].dispose();
      _waypointFocusNodes.removeAt(index);
    });
    _updateRoute();
    _notifyStateChanged();
  }

  Future<void> _setFromCurrentLocation() async {
    debugPrint('[SearchPanel] setFromCurrentLocation');
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
    });

    try {
      final location = await _locationService.getCurrentLocation(
        accuracy: LocationAccuracy.high,
      );

      if (location == null || !mounted) {
        debugPrint('[SearchPanel] Could not get location');
        return;
      }

      String label =
          '${location.coordinates.lat.toStringAsFixed(5)}, ${location.coordinates.lon.toStringAsFixed(5)}';

      try {
        final reverse = await _client.reverse(
          coordinates: location.coordinates,
          language: widget.config.language,
        );
        label = reverse.displayName;
      } catch (_) {
        // Fallback to coords
      }

      final address = SelectedAddress(
        coordinates: location.coordinates,
        label: label,
      );

      setFromAddress(address);
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _updateRoute() async {
    if (!canRoute) {
      setState(() {
        _activeRoute = null;
      });
      return;
    }

    if (_isRouting) return;

    debugPrint('[SearchPanel] updateRoute');
    setState(() {
      _isRouting = true;
    });

    try {
      final validWaypoints = _waypoints
          .where((w) => w.isSet)
          .map((w) => w.coordinates)
          .toList();

      final route = await widget.onRouteRequested?.call(
        _fromAddress!.coordinates,
        _toAddress!.coordinates,
        validWaypoints.isNotEmpty ? validWaypoints : null,
        _transportMode,
      );

      if (mounted) {
        setState(() {
          _activeRoute = route;
        });
        _notifyStateChanged();
      }
    } catch (e) {
      debugPrint('[SearchPanel] Route error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRouting = false;
        });
      }
    }
  }

  void _onAddressSelected(SearchFieldType type, int? waypointIndex,
      SelectedAddress address) {
    debugPrint(
        '[SearchPanel] onAddressSelected: $type, waypointIndex: $waypointIndex');
    switch (type) {
      case SearchFieldType.from:
        setFromAddress(address);
        break;
      case SearchFieldType.to:
        setToAddress(address);
        break;
      case SearchFieldType.waypoint:
        if (waypointIndex != null) {
          setWaypointAddress(waypointIndex, address);
        }
        break;
    }
  }

  void _onModeChanged(TransportMode mode) {
    debugPrint('[SearchPanel] onModeChanged: $mode');
    setState(() {
      _transportMode = mode;
    });
    _updateRoute();
    _notifyStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return Container(
      decoration: BoxDecoration(
        color: config.backgroundColor ?? const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(config.borderRadius),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5F5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // From field (always visible or only when focused)
            if (!_isSearchFocused ||
                _activeField?.type == SearchFieldType.from)
              _buildAddressField(
                config: config.fromFieldConfig,
                controller: _fromController,
                focusNode: _fromFocus,
                type: SearchFieldType.from,
              ),

            // Waypoints
            if (!_isSearchFocused && config.enableWaypoints)
              for (int i = 0; i < _waypoints.length; i++) ...[
                const SizedBox(height: 8),
                _buildWaypointField(index: i),
              ]
            else if (_isSearchFocused &&
                _activeField?.type == SearchFieldType.waypoint &&
                _activeField?.waypointIndex != null)
              ...[
                const SizedBox(height: 8),
                _buildWaypointField(index: _activeField!.waypointIndex!),
              ],

            // Add waypoint button
            if (!_isSearchFocused &&
                config.enableWaypoints &&
                _waypoints.length < config.maxWaypoints) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _addWaypoint,
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: Text(config.addWaypointText),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // To field
            if (!_isSearchFocused || _activeField?.type == SearchFieldType.to)
              _buildAddressField(
                config: config.toFieldConfig,
                controller: _toController,
                focusNode: _toFocus,
                type: SearchFieldType.to,
              ),

            // Controls (hidden when focused)
            if (!_isSearchFocused) ...[
              // Transport mode selector
              if (config.showTransportModeSelector) ...[
                const SizedBox(height: 12),
                SegmentedButton<TransportMode>(
                  segments: const [
                    ButtonSegment(
                        value: TransportMode.car, label: Text('Авто')),
                    ButtonSegment(
                        value: TransportMode.foot, label: Text('Пешком')),
                    ButtonSegment(
                        value: TransportMode.bike, label: Text('Вело')),
                  ],
                  selected: {_transportMode},
                  onSelectionChanged: (value) => _onModeChanged(value.first),
                ),
              ],

              // Action buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  if (config.showMyLocationButton)
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _isLocating ? null : _setFromCurrentLocation,
                        icon: _isLocating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(config.myLocationButtonText),
                      ),
                    ),
                  if (config.showMyLocationButton && config.showResetButton)
                    const SizedBox(width: 12),
                  if (config.showResetButton)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: reset,
                        icon: const Icon(Icons.clear),
                        label: Text(config.resetButtonText),
                      ),
                    ),
                ],
              ),

              // Route info
              if (config.showRouteInfo && _activeRoute != null) ...[
                const SizedBox(height: 16),
                _buildRouteCard(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField({
    required AddressSearchFieldConfig config,
    required TextEditingController controller,
    required FocusNode focusNode,
    required SearchFieldType type,
  }) {
    return _SearchFieldInternal(
      config: config,
      controller: controller,
      focusNode: focusNode,
      client: _client,
      language: widget.config.language,
      onAddressSelected: (address) =>
          _onAddressSelected(type, null, address),
      onMapSelectPressed: () =>
          widget.onMapSelectRequested?.call(type, null),
    );
  }

  Widget _buildWaypointField({required int index}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF1351B4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _WaypointFieldInternal(
              controller: _waypointControllers[index],
              focusNode: _waypointFocusNodes[index],
              index: index,
              client: _client,
              language: widget.config.language,
              onAddressSelected: (address) =>
                  _onAddressSelected(SearchFieldType.waypoint, index, address),
            ),
          ),
          IconButton(
            onPressed: () =>
                widget.onMapSelectRequested?.call(SearchFieldType.waypoint, index),
            icon: const Icon(Icons.place_outlined, size: 20),
            visualDensity: VisualDensity.compact,
            tooltip: 'Выбрать на карте',
          ),
          IconButton(
            onPressed: () => _removeWaypoint(index),
            icon: const Icon(Icons.close, size: 20),
            visualDensity: VisualDensity.compact,
            color: Colors.grey,
            tooltip: 'Удалить',
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_activeRoute!.formattedDistance} · ${_activeRoute!.formattedDuration}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isRouting)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

/// Internal field widget with search functionality.
class _SearchFieldInternal extends StatefulWidget {
  final AddressSearchFieldConfig config;
  final TextEditingController controller;
  final FocusNode focusNode;
  final QorviaMapsClient client;
  final String language;
  final ValueChanged<SelectedAddress> onAddressSelected;
  final VoidCallback? onMapSelectPressed;

  const _SearchFieldInternal({
    required this.config,
    required this.controller,
    required this.focusNode,
    required this.client,
    required this.language,
    required this.onAddressSelected,
    this.onMapSelectPressed,
  });

  @override
  State<_SearchFieldInternal> createState() => _SearchFieldInternalState();
}

class _SearchFieldInternalState extends State<_SearchFieldInternal> {
  Timer? _debounce;
  List<GeocodeResult> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (!widget.focusNode.hasFocus) {
      setState(() {
        _results = [];
      });
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    _debounce = Timer(widget.config.searchDebounce, () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!QorviaMapsSDK.isInitialized) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await widget.client.geocode(
        query: query,
        limit: 6,
        language: widget.language,
      );

      if (mounted) {
        setState(() {
          _results = response.results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectResult(GeocodeResult result) {
    final address = SelectedAddress(
      coordinates: result.coordinates,
      label: result.displayName,
    );
    widget.controller.text = result.displayName;
    setState(() {
      _results = [];
    });
    widget.onAddressSelected(address);
    widget.focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: config.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(config.borderRadius),
            border:
                Border.all(color: config.borderColor ?? const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: _onTextChanged,
                  decoration: InputDecoration(
                    labelText: config.label,
                    hintText: config.hint,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (config.showMapSelectButton) ...[
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: widget.onMapSelectPressed,
                  icon: const Icon(Icons.place_outlined, size: 18),
                  label: Text(config.mapSelectButtonText),
                ),
              ],
            ],
          ),
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(config.borderRadius),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(config.borderRadius),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    title: Text(result.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => _selectResult(result),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Internal waypoint field with search.
class _WaypointFieldInternal extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int index;
  final QorviaMapsClient client;
  final String language;
  final ValueChanged<SelectedAddress> onAddressSelected;

  const _WaypointFieldInternal({
    required this.controller,
    required this.focusNode,
    required this.index,
    required this.client,
    required this.language,
    required this.onAddressSelected,
  });

  @override
  State<_WaypointFieldInternal> createState() => _WaypointFieldInternalState();
}

class _WaypointFieldInternalState extends State<_WaypointFieldInternal> {
  Timer? _debounce;
  List<GeocodeResult> _results = [];

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (!widget.focusNode.hasFocus) {
      setState(() {
        _results = [];
      });
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!QorviaMapsSDK.isInitialized) return;

    try {
      final response = await widget.client.geocode(
        query: query,
        limit: 6,
        language: widget.language,
      );

      if (mounted) {
        setState(() {
          _results = response.results;
        });
      }
    } catch (_) {}
  }

  void _selectResult(GeocodeResult result) {
    final address = SelectedAddress(
      coordinates: result.coordinates,
      label: result.displayName,
    );
    widget.controller.text = result.displayName;
    setState(() {
      _results = [];
    });
    widget.onAddressSelected(address);
    widget.focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textInputAction: TextInputAction.search,
          onChanged: _onTextChanged,
          decoration: InputDecoration(
            hintText: 'Через точку ${widget.index + 1}',
            border: InputBorder.none,
            isDense: true,
          ),
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final result = _results[index];
                return ListTile(
                  dense: true,
                  title: Text(result.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                  onTap: () => _selectResult(result),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
