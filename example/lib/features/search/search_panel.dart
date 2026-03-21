import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../shared/services/offline_geocoding_helper.dart';
import 'models/selected_point.dart';
import 'models/travel_mode.dart';
import 'widgets/action_button.dart';
import 'widgets/search_field.dart';
import 'widgets/search_results_list.dart';
import 'widgets/travel_mode_selector.dart';

/// Which input field is currently active.
enum ActiveField { from, to, waypoint }

/// Search panel for selecting origin and destination points.
/// Features glassmorphism design with backdrop blur effect.
class SearchPanel extends StatefulWidget {
  final ValueChanged<SelectedPoint>? onFromChanged;
  final ValueChanged<SelectedPoint>? onToChanged;
  final ValueChanged<TravelMode>? onTravelModeChanged;
  final void Function(ActiveField field, int? waypointIndex)? onMapSelect;
  final VoidCallback? onMyLocation;
  final VoidCallback? onReset;
  final bool isLocating;
  final SelectedPoint? fromPoint;
  final SelectedPoint? toPoint;
  final TravelMode travelMode;
  final Widget? child;

  /// Callback when waypoints change.
  final ValueChanged<List<SelectedPoint>>? onWaypointsChanged;

  /// Initial waypoints list.
  final List<SelectedPoint>? waypoints;

  /// Maximum number of waypoints allowed.
  final int maxWaypoints;

  /// Whether to enable waypoints functionality.
  final bool enableWaypoints;

  /// Whether to enable glassmorphism effect.
  /// Set to false when using inside ExpandableBottomPanel (which has its own glassmorphism).
  final bool enableGlassmorphism;

  /// Whether the panel is in collapsed state.
  /// In collapsed state, only the "From" field is shown with a hint to expand.
  final bool isCollapsed;

  /// Callback when user taps to expand the panel.
  final VoidCallback? onExpandRequest;

  const SearchPanel({
    super.key,
    this.onFromChanged,
    this.onToChanged,
    this.onTravelModeChanged,
    this.onMapSelect,
    this.onMyLocation,
    this.onReset,
    this.isLocating = false,
    this.fromPoint,
    this.toPoint,
    this.travelMode = TravelMode.car,
    this.child,
    this.onWaypointsChanged,
    this.waypoints,
    this.maxWaypoints = 10,
    this.enableWaypoints = true,
    this.enableGlassmorphism = true,
    this.isCollapsed = false,
    this.onExpandRequest,
  });

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel>
{
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();

  // Waypoints
  final List<SelectedPoint> _waypoints = [];
  final List<TextEditingController> _waypointControllers = [];
  final List<FocusNode> _waypointFocusNodes = [];
  int? _activeWaypointIndex;

  // Focus mode
  bool _isSearchFocused = false;

  List<GeocodeResult> _results = [];
  ActiveField? _activeField;
  TravelMode _travelMode = TravelMode.car;
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _travelMode = widget.travelMode;

    _fromFocus.addListener(_onFocusChange);
    _toFocus.addListener(_onFocusChange);

    if (widget.fromPoint != null) {
      _fromController.text = widget.fromPoint!.label;
    }
    if (widget.toPoint != null) {
      _toController.text = widget.toPoint!.label;
    }

    // Initialize waypoints
    if (widget.waypoints != null) {
      for (final wp in widget.waypoints!) {
        _addWaypointWithPoint(wp);
      }
    }

    _log('SearchPanel initialized', {
      'isCollapsed': widget.isCollapsed,
    });
  }

  void _onFocusChange() {
    final anyFocused = _fromFocus.hasFocus ||
        _toFocus.hasFocus ||
        _waypointFocusNodes.any((f) => f.hasFocus);

    setState(() {
      _isSearchFocused = anyFocused;

      if (_fromFocus.hasFocus) {
        _activeField = ActiveField.from;
        _activeWaypointIndex = null;
      } else if (_toFocus.hasFocus) {
        _activeField = ActiveField.to;
        _activeWaypointIndex = null;
      } else {
        for (int i = 0; i < _waypointFocusNodes.length; i++) {
          if (_waypointFocusNodes[i].hasFocus) {
            _activeField = ActiveField.waypoint;
            _activeWaypointIndex = i;
            break;
          }
        }
      }

      if (!anyFocused) {
        _activeField = null;
        _activeWaypointIndex = null;
      }
    });

    _log('Focus changed', {
      'focused': anyFocused,
      'field': _activeField?.name,
      'waypointIndex': _activeWaypointIndex,
    });
  }

  void _unfocusAll() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearchFocused = false;
      _results = [];
    });
  }

  void _addWaypoint() {
    _addWaypointWithPoint(SelectedPoint.empty());
  }

  void _addWaypointWithPoint(SelectedPoint point) {
    final controller = TextEditingController(text: point.label);
    final focusNode = FocusNode();
    final index = _waypoints.length;

    focusNode.addListener(() {
      _onFocusChange();
      if (focusNode.hasFocus) {
        setState(() {
          _activeField = ActiveField.waypoint;
          _activeWaypointIndex = index;
        });
      }
    });

    setState(() {
      _waypoints.add(point);
      _waypointControllers.add(controller);
      _waypointFocusNodes.add(focusNode);
    });

    _notifyWaypointsChanged();
    _log('Waypoint added', {'index': index});
  }

  void _removeWaypoint(int index) {
    _log('Removing waypoint', {'index': index});

    setState(() {
      _waypoints.removeAt(index);
      _waypointControllers[index].dispose();
      _waypointControllers.removeAt(index);
      _waypointFocusNodes[index].dispose();
      _waypointFocusNodes.removeAt(index);

      if (_activeWaypointIndex != null && _activeWaypointIndex! >= index) {
        _activeWaypointIndex = null;
        _activeField = null;
      }
    });

    _notifyWaypointsChanged();
  }

  void _updateWaypoint(int index, SelectedPoint point) {
    if (index < 0 || index >= _waypoints.length) return;

    setState(() {
      _waypoints[index] = point;
      _waypointControllers[index].text = point.label;
    });

    _notifyWaypointsChanged();
  }

  void _notifyWaypointsChanged() {
    widget.onWaypointsChanged?.call(List.unmodifiable(_waypoints));
  }

  /// Set waypoint from external source (e.g., map selection).
  void setWaypoint(int index, SelectedPoint point) {
    _updateWaypoint(index, point);
  }

  @override
  void didUpdateWidget(SearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.fromPoint != oldWidget.fromPoint && widget.fromPoint != null) {
      _fromController.text = widget.fromPoint!.label;
    }
    if (widget.toPoint != oldWidget.toPoint && widget.toPoint != null) {
      _toController.text = widget.toPoint!.label;
    }
    if (widget.travelMode != oldWidget.travelMode) {
      _travelMode = widget.travelMode;
    }
  }

  @override
  void dispose() {
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
    _searchDebounce?.cancel();
    _log('SearchPanel disposed');
    super.dispose();
  }

  String get _activeQuery {
    if (_activeField == ActiveField.to) {
      return _toController.text;
    }
    if (_activeField == ActiveField.waypoint && _activeWaypointIndex != null) {
      return _waypointControllers[_activeWaypointIndex!].text;
    }
    return _fromController.text;
  }

  Future<void> _searchAddress() async {
    if (!QorviaMapsSDK.isInitialized) {
      _log('SDK not initialized', {'level': 'WARN'});
      return;
    }

    final query = _activeQuery.trim();
    if (query.isEmpty) return;

    _log('Searching', {'query': query});
    setState(() => _isSearching = true);

    try {
      // Use system language for search results (offline-first)
      final locale = Localizations.localeOf(context);
      final response = await OfflineGeocodingHelper.geocode(
        query: query,
        limit: 6,
        language: locale.languageCode,
      );
      _log('Search results', {'count': response?.results.length ?? 0});
      setState(() => _results = response?.results ?? []);
    } catch (error) {
      _log('Search error', {'error': error.toString(), 'level': 'ERROR'});
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _scheduleSearch(String value) {
    if (value.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppConstants.searchDebounce, _searchAddress);
  }

  void _selectResult(GeocodeResult result) {
    _log('Result selected', {'displayName': result.displayName});

    final point = SelectedPoint(
      coordinates: result.coordinates,
      label: result.displayName,
    );

    setState(() {
      if (_activeField == ActiveField.to) {
        _toController.text = result.displayName;
        widget.onToChanged?.call(point);
      } else if (_activeField == ActiveField.waypoint &&
          _activeWaypointIndex != null) {
        _updateWaypoint(_activeWaypointIndex!, point);
      } else {
        _fromController.text = result.displayName;
        widget.onFromChanged?.call(point);
      }
      _results = [];
    });

    _unfocusAll();
  }

  void _onTravelModeChanged(TravelMode mode) {
    _log('Travel mode changed', {'mode': mode.name});
    setState(() => _travelMode = mode);
    widget.onTravelModeChanged?.call(mode);
  }

  void _onReset() {
    _log('Reset pressed');
    setState(() {
      _fromController.clear();
      _toController.clear();
      _results = [];

      // Clear waypoints
      for (final c in _waypointControllers) {
        c.dispose();
      }
      for (final f in _waypointFocusNodes) {
        f.dispose();
      }
      _waypoints.clear();
      _waypointControllers.clear();
      _waypointFocusNodes.clear();
      _activeWaypointIndex = null;
    });
    _notifyWaypointsChanged();
    widget.onReset?.call();
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[SearchPanel] $message$dataStr');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context);

    // Log state changes for debugging
    _log('Build', {
      'isCollapsed': widget.isCollapsed,
      'isSearchFocused': _isSearchFocused,
      'activeField': _activeField?.name,
    });

    // Collapsed mode: only show "From" field with expand hint
    if (widget.isCollapsed && !_isSearchFocused) {
      return _buildCollapsedContent(bottomPadding, l10n);
    }

    final content = Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            // From field - show when not focused or when it's the active field
            if (!_isSearchFocused || _activeField == ActiveField.from)
              SearchField(
                label: l10n.from,
                controller: _fromController,
                focusNode: _fromFocus,
                prefixIcon: Icons.trip_origin,
                iconColor: AppColors.primary,
                isLoading: widget.fromPoint?.isLoading ?? false,
                onChanged: (value) {
                  _activeField = ActiveField.from;
                  _scheduleSearch(value);
                },
                onMapSelect: () => widget.onMapSelect?.call(ActiveField.from, null),
                onSubmitted: _searchAddress,
              ),

            // Waypoints - show when not focused or show only active waypoint
            if (widget.enableWaypoints) ...[
              if (!_isSearchFocused)
                for (int i = 0; i < _waypoints.length; i++) ...[
                  const SizedBox(height: 8),
                  _buildWaypointField(index: i, l10n: l10n),
                ]
              else if (_activeField == ActiveField.waypoint &&
                  _activeWaypointIndex != null) ...[
                const SizedBox(height: 8),
                _buildWaypointField(index: _activeWaypointIndex!, l10n: l10n),
              ],

              // Add waypoint button - hide when focused
              if (!_isSearchFocused &&
                  _waypoints.length < widget.maxWaypoints) ...[
                const SizedBox(height: 8),
                _buildAddWaypointButton(l10n),
              ],
            ],

            // To field - show when not focused or when it's the active field
            if (!_isSearchFocused || _activeField == ActiveField.to) ...[
              const SizedBox(height: 12),
              SearchField(
                label: l10n.to,
                controller: _toController,
                focusNode: _toFocus,
                prefixIcon: Icons.location_on,
                iconColor: AppColors.primary,
                isLoading: widget.toPoint?.isLoading ?? false,
                onChanged: (value) {
                  _activeField = ActiveField.to;
                  _scheduleSearch(value);
                },
                onMapSelect: () => widget.onMapSelect?.call(ActiveField.to, null),
                onSubmitted: _searchAddress,
              ),
            ],

            // Controls - hide when focused
            if (!_isSearchFocused) ...[
              const SizedBox(height: 16),

              // Travel mode selector
              TravelModeSelector(
                selectedMode: _travelMode,
                onModeChanged: _onTravelModeChanged,
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      icon: widget.isLocating ? null : Icons.my_location,
                      label: l10n.myLocation,
                      isLoading: widget.isLocating,
                      onTap: widget.isLocating ? null : widget.onMyLocation,
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      icon: Icons.refresh_rounded,
                      label: l10n.reset,
                      onTap: _onReset,
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            ],

            // Search results
            SearchResultsList(
              results: _results,
              onResultSelected: _selectResult,
            ),

            // Child widget (route preview) - hide when focused
            if (widget.child != null && !_isSearchFocused) widget.child!,

            // Loading indicator
            if (_isSearching) _buildLoadingIndicator(),
          ],
        ),
      );

    // Return content directly if glassmorphism is disabled
    if (!widget.enableGlassmorphism) {
      return content;
    }

    // Wrap with glassmorphism effect
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withAlpha(242), // 95%
                Colors.white.withAlpha(230), // 90%
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withAlpha(128),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowPrimary,
                blurRadius: 32,
                spreadRadius: 0,
                offset: const Offset(0, -12),
              ),
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }

  /// Builds the collapsed view showing only "From" field with expand hint.
  Widget _buildCollapsedContent(double bottomPadding, AppLocalizations l10n) {
    _log('Building collapsed content');

    final content = Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // From field - always visible and active in collapsed mode
          SearchField(
            label: l10n.from,
            controller: _fromController,
            focusNode: _fromFocus,
            prefixIcon: Icons.trip_origin,
            iconColor: AppColors.primary,
            isLoading: widget.fromPoint?.isLoading ?? false,
            onChanged: (value) {
              _activeField = ActiveField.from;
              _scheduleSearch(value);
            },
            onMapSelect: () => widget.onMapSelect?.call(ActiveField.from, null),
            onSubmitted: _searchAddress,
          ),

          const SizedBox(height: 12),

          // Expand hint - tap to show full panel
          GestureDetector(
            onTap: () {
              _log('Expand hint tapped');
              widget.onExpandRequest?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withAlpha(40),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.whereToGo,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search results (show if searching in collapsed mode)
          SearchResultsList(
            results: _results,
            onResultSelected: _selectResult,
          ),

          // Loading indicator
          if (_isSearching) _buildLoadingIndicator(),
        ],
      ),
    );

    // Return content directly if glassmorphism is disabled
    if (!widget.enableGlassmorphism) {
      return content;
    }

    // Wrap with glassmorphism effect
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withAlpha(242),
                Colors.white.withAlpha(230),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withAlpha(128),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowPrimary,
                blurRadius: 32,
                spreadRadius: 0,
                offset: const Offset(0, -12),
              ),
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildWaypointField({required int index, required AppLocalizations l10n}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withAlpha(100)),
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
              color: AppColors.primary,
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
            child: TextField(
              controller: _waypointControllers[index],
              focusNode: _waypointFocusNodes[index],
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                _activeField = ActiveField.waypoint;
                _activeWaypointIndex = index;
                _scheduleSearch(value);
              },
              onSubmitted: (_) => _searchAddress(),
              decoration: InputDecoration(
                hintText: '${l10n.viaPoint} ${index + 1}',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                widget.onMapSelect?.call(ActiveField.waypoint, index),
            icon: const Icon(Icons.place_outlined, size: 20),
            visualDensity: VisualDensity.compact,
            tooltip: l10n.selectOnMap,
            color: AppColors.primary,
          ),
          IconButton(
            onPressed: () => _removeWaypoint(index),
            icon: const Icon(Icons.close, size: 20),
            visualDensity: VisualDensity.compact,
            color: AppColors.outline,
            tooltip: l10n.delete,
          ),
        ],
      ),
    );
  }

  Widget _buildAddWaypointButton(AppLocalizations l10n) {
    return Center(
      child: TextButton.icon(
        onPressed: _addWaypoint,
        icon: Icon(
          Icons.add_location_alt_outlined,
          size: 18,
          color: AppColors.primary,
        ),
        label: Text(
          l10n.addPoint,
          style: TextStyle(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          minHeight: 3,
          backgroundColor: AppColors.outlineVariant,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}
