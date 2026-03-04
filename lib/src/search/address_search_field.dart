import 'dart:async';

import 'package:flutter/material.dart';

import '../client/qorvia_maps_client.dart';
import '../models/models.dart';
import '../sdk_initializer.dart';
import 'search_config.dart';
import 'selected_address.dart';

/// A search field widget for address input with autocomplete functionality.
///
/// This widget provides:
/// - Text input with debounced search
/// - Autocomplete results from geocoding API
/// - Optional "select on map" button
/// - Focus state management
/// - Location-biased search results
///
/// Example:
/// ```dart
/// AddressSearchField(
///   config: AddressSearchFieldConfig(label: 'Откуда'),
///   userLocation: Coordinates(lat: 53.404935, lon: 58.965423),
///   onAddressSelected: (address) {
///     print('Selected: ${address.label}');
///   },
/// )
/// ```
class AddressSearchField extends StatefulWidget {
  /// Configuration for the field.
  final AddressSearchFieldConfig config;

  /// Currently selected address (controlled mode).
  final SelectedAddress? value;

  /// User's current location for location-biased search results.
  /// When provided, search results will be prioritized by proximity.
  final Coordinates? userLocation;

  /// Search radius in kilometers (default: 50).
  /// Only used when [userLocation] is provided.
  final double radiusKm;

  /// Called when an address is selected from results.
  final ValueChanged<SelectedAddress>? onAddressSelected;

  /// Called when the "select on map" button is pressed.
  final VoidCallback? onMapSelectPressed;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChanged;

  /// Called when search results are updated.
  final ValueChanged<List<GeocodeResult>>? onResultsChanged;

  /// External focus node (optional).
  final FocusNode? focusNode;

  /// External text controller (optional).
  final TextEditingController? controller;

  /// Custom client for geocoding (uses SDK client if not provided).
  final QorviaMapsClient? client;

  const AddressSearchField({
    super.key,
    this.config = const AddressSearchFieldConfig(label: ''),
    this.value,
    this.userLocation,
    this.radiusKm = 50,
    this.onAddressSelected,
    this.onMapSelectPressed,
    this.onFocusChanged,
    this.onResultsChanged,
    this.focusNode,
    this.controller,
    this.client,
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounce;
  List<GeocodeResult> _results = [];
  bool _isSearching = false;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  QorviaMapsClient get _client =>
      widget.client ?? QorviaMapsSDK.instance.client;

  @override
  void initState() {
    super.initState();
    _initController();
    _initFocusNode();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = TextEditingController(text: widget.value?.label ?? '');
      _ownsController = true;
    }
  }

  void _initFocusNode() {
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsFocusNode = false;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AddressSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update text if value changed externally
    if (widget.value != oldWidget.value && widget.value != null) {
      if (_controller.text != widget.value!.label) {
        _controller.text = widget.value!.label;
      }
    }

    // Handle controller change
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _initController();
    }

    // Handle focus node change
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
      _initFocusNode();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    debugPrint('[AddressSearchField] Focus changed: ${_focusNode.hasFocus}');
    widget.onFocusChanged?.call(_focusNode.hasFocus);

    if (!_focusNode.hasFocus) {
      // Clear results when losing focus
      setState(() {
        _results = [];
      });
      widget.onResultsChanged?.call([]);
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
      });
      widget.onResultsChanged?.call([]);
      return;
    }

    _debounce = Timer(widget.config.searchDebounce, () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!QorviaMapsSDK.isInitialized) {
      debugPrint('[AddressSearchField] SDK not initialized, skipping search');
      return;
    }

    final userLoc = widget.userLocation;
    if (userLoc != null) {
      debugPrint(
        '[AddressSearchField] Searching with user location: '
        'lat=${userLoc.lat}, lon=${userLoc.lon}, radius=${widget.radiusKm}km',
      );
    } else {
      debugPrint('[AddressSearchField] Searching without location bias');
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await _client.geocode(
        query: query,
        limit: 6,
        language: 'ru',
        userLat: userLoc?.lat,
        userLon: userLoc?.lon,
        radiusKm: userLoc != null ? widget.radiusKm : null,
        biasLocation: userLoc != null ? true : null,
      );

      debugPrint(
          '[AddressSearchField] Found ${response.results.length} results');

      if (mounted) {
        setState(() {
          _results = response.results;
          _isSearching = false;
        });
        widget.onResultsChanged?.call(_results);
      }
    } catch (e) {
      debugPrint('[AddressSearchField] Search error: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectResult(GeocodeResult result) {
    debugPrint('[AddressSearchField] Selected: ${result.displayName}');

    final address = SelectedAddress(
      coordinates: result.coordinates,
      label: result.displayName,
    );

    _controller.text = result.displayName;
    setState(() {
      _results = [];
    });
    widget.onResultsChanged?.call([]);
    widget.onAddressSelected?.call(address);

    // Unfocus after selection
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Input field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: config.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(config.borderRadius),
            border: Border.all(
              color: config.borderColor ?? const Color(0xFFE2E8F0),
            ),
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
                  controller: _controller,
                  focusNode: _focusNode,
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

        // Results list
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(config.borderRadius),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
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
                    title: Text(
                      result.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
