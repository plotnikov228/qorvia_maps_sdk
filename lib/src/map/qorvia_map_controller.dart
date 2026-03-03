import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/coordinates.dart';
import '../models/route/route_response.dart';
import '../markers/marker.dart';
import '../markers/marker_icon.dart';
import '../markers/cluster/marker_cluster.dart';
import '../route_display/route_line.dart';
import 'camera/camera_position.dart' as sdk;

/// Log level for QorviaMapController operations
enum _LogLevel { debug, info }

/// Internal logger for QorviaMapController
void _log(_LogLevel level, String message, [Object? data]) {
  if (!kDebugMode) return;
  final prefix = '[QorviaMapController]';
  final levelStr = level.name.toUpperCase();
  if (data != null) {
    debugPrint('$prefix [$levelStr] $message: $data');
  } else {
    debugPrint('$prefix [$levelStr] $message');
  }
}

/// Controller for managing the map.
class QorviaMapController extends ChangeNotifier {
  MaplibreMapController? _mapController;
  final Map<String, Symbol> _markers = {};
  final Map<String, String> _symbolToMarkerId = {};
  final Map<String, Line> _routeLines = {};
  final Set<String> _registeredImages = {};
  sdk.CameraPosition? _currentCameraPosition;
  Dio? _sharedDio;

  // Throttle for camera position notifyListeners to avoid excessive rebuilds
  // Camera updates happen 60 times/sec during navigation - throttle to 10/sec
  DateTime? _lastCameraNotifyAt;
  static const Duration _cameraNotifyThrottle = Duration(milliseconds: 100);

  // Debounce for notifyListeners to coalesce multiple rapid updates
  bool _notifyScheduled = false;
  int _coalescedNotifications = 0;

  /// Whether the map is ready.
  bool get isMapReady => _mapController != null;

  /// Current camera position.
  sdk.CameraPosition? get cameraPosition => _currentCameraPosition;

  /// Raw MapLibre camera position.
  CameraPosition? get maplibreCameraPosition => _mapController?.cameraPosition;

  /// Returns marker id for a given symbol id.
  String? markerIdForSymbolId(String symbolId) => _symbolToMarkerId[symbolId];

  /// Schedules a debounced notifyListeners call.
  /// Multiple calls within the same microtask are coalesced into one.
  /// Use [notifyListenersImmediate] for critical updates that can't wait.
  void _scheduleNotify() {
    _coalescedNotifications++;
    if (_notifyScheduled) return;

    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      final coalesced = _coalescedNotifications;
      _coalescedNotifications = 0;

      if (coalesced > 1) {
        _log(_LogLevel.debug, 'notifyListeners coalesced', {'count': coalesced});
      }

      super.notifyListeners();
    });
  }

  /// Calls notifyListeners immediately without debouncing.
  /// Use for critical updates like map controller changes.
  void notifyListenersImmediate() {
    _notifyScheduled = false;
    _coalescedNotifications = 0;
    super.notifyListeners();
  }

  @override
  void notifyListeners() {
    // Use debounced version by default for marker operations
    _scheduleNotify();
  }

  /// Sets the internal MapLibre controller.
  /// Called internally when map is created.
  void setMapController(MaplibreMapController controller) {
    // Clear stale state from previous controller (if any)
    // The new MapLibre controller doesn't have our registered images/markers
    _markers.clear();
    _symbolToMarkerId.clear();
    _registeredImages.clear();
    _routeLines.clear();

    _mapController = controller;
    // Use immediate notify for critical state changes
    notifyListenersImmediate();
  }

  /// Updates current camera position.
  /// Called internally on camera move.
  /// Throttles notifyListeners to 100ms to avoid excessive widget rebuilds.
  void updateCameraPosition(sdk.CameraPosition position) {
    _currentCameraPosition = position;

    // Throttle notifyListeners to reduce widget rebuilds during navigation
    // Camera moves happen ~60 times/sec, throttling to ~10/sec
    final now = DateTime.now();
    if (_lastCameraNotifyAt != null &&
        now.difference(_lastCameraNotifyAt!) < _cameraNotifyThrottle) {
      return;
    }
    _lastCameraNotifyAt = now;
    notifyListeners();
  }

  // ==================== CAMERA ====================

  /// Animates the camera to a new position.
  Future<void> animateCamera(
    sdk.CameraUpdate update, {
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    final controller = _mapController;
    if (controller == null) return;

    if (update.position != null) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              update.position!.center.lat,
              update.position!.center.lon,
            ),
            zoom: update.position!.zoom,
            tilt: update.position!.tilt,
            bearing: update.position!.bearing,
          ),
        ),
        duration: duration,
      );
    } else if (update.bounds != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          update.bounds!.map((c) => c.lat).reduce((a, b) => a < b ? a : b),
          update.bounds!.map((c) => c.lon).reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          update.bounds!.map((c) => c.lat).reduce((a, b) => a > b ? a : b),
          update.bounds!.map((c) => c.lon).reduce((a, b) => a > b ? a : b),
        ),
      );
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          left: update.boundsPadding ?? 50,
          right: update.boundsPadding ?? 50,
          top: update.boundsPadding ?? 50,
          bottom: update.boundsPadding ?? 50,
        ),
        duration: duration,
      );
    } else if (update.center != null) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(update.center!.lat, update.center!.lon),
          update.zoom ?? _currentCameraPosition?.zoom ?? 14,
        ),
        duration: duration,
      );
    } else if (update.zoom != null) {
      await controller.animateCamera(
        CameraUpdate.zoomTo(update.zoom!),
        duration: duration,
      );
    } else if (update.bearing != null) {
      await controller.animateCamera(
        CameraUpdate.bearingTo(update.bearing!),
        duration: duration,
      );
    } else if (update.tilt != null) {
      await controller.animateCamera(
        CameraUpdate.tiltTo(update.tilt!),
        duration: duration,
      );
    }
  }

  /// Moves the camera to a new position instantly.
  Future<void> moveCamera(sdk.CameraUpdate update) async {
    final controller = _mapController;
    if (controller == null) return;

    if (update.position != null) {
      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              update.position!.center.lat,
              update.position!.center.lon,
            ),
            zoom: update.position!.zoom,
            tilt: update.position!.tilt,
            bearing: update.position!.bearing,
          ),
        ),
      );
    } else if (update.center != null) {
      await controller.moveCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(update.center!.lat, update.center!.lon),
          update.zoom ?? _currentCameraPosition?.zoom ?? 14,
        ),
      );
    }
  }

  /// Gets the current zoom level.
  Future<double?> getZoom() async {
    return _mapController?.cameraPosition?.zoom;
  }

  /// Zooms in by one level.
  Future<void> zoomIn() async {
    final zoom = await getZoom();
    if (zoom != null) {
      await animateCamera(sdk.CameraUpdate.zoomTo(zoom + 1));
    }
  }

  /// Zooms out by one level.
  Future<void> zoomOut() async {
    final zoom = await getZoom();
    if (zoom != null) {
      await animateCamera(sdk.CameraUpdate.zoomTo(zoom - 1));
    }
  }


  /// Convenience method to animate to a new center with optional zoom.
  Future<void> animateTo({
    required Coordinates center,
    double? zoom,
    double? tilt,
    double? bearing,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(center.lat, center.lon),
          zoom: zoom ?? _currentCameraPosition?.zoom ?? 14,
          tilt: tilt ?? _currentCameraPosition?.tilt ?? 0,
          bearing: bearing ?? _currentCameraPosition?.bearing ?? 0,
        ),
      ),
      duration: duration,
    );
  }

  /// Fits the camera to show bounds defined by southwest and northeast corners.
  Future<void> fitBounds({
    required Coordinates southwest,
    required Coordinates northeast,
    EdgeInsets padding = const EdgeInsets.all(50),
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    final controller = _mapController;
    if (controller == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(southwest.lat, southwest.lon),
      northeast: LatLng(northeast.lat, northeast.lon),
    );

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        left: padding.left,
        right: padding.right,
        top: padding.top,
        bottom: padding.bottom,
      ),
      duration: duration,
    );
  }

  /// Converts geographic coordinates to screen position.
  /// Returns the screen position in logical pixels.
  Future<Offset?> toScreenLocation(Coordinates coordinates) async {
    final controller = _mapController;
    if (controller == null) return null;

    final point = await controller.toScreenLocation(
      LatLng(coordinates.lat, coordinates.lon),
    );

    // MapLibre returns physical pixels, convert to logical pixels
    // Note: This requires devicePixelRatio which we don't have here,
    // so we return physical pixels and let the caller handle the conversion
    return Offset(point.x.toDouble(), point.y.toDouble());
  }

  /// Converts geographic coordinates to screen position in logical pixels.
  /// Requires devicePixelRatio for proper conversion.
  Future<Offset?> toScreenLocationLogical(
      Coordinates coordinates,
      double devicePixelRatio,
      ) async {
    final controller = _mapController;
    if (controller == null) return null;

    final point = await controller.toScreenLocation(
      LatLng(coordinates.lat, coordinates.lon),
    );

    return Offset(
      point.x.toDouble() / devicePixelRatio,
      point.y.toDouble() / devicePixelRatio,
    );
  }


  // ==================== MARKERS ====================

  /// Generates a marker image name for a DefaultMarkerIcon.
  String _markerImageName(DefaultMarkerIcon icon) {
    return 'marker_${icon.color.toARGB32().toRadixString(16)}_${icon.size.toInt()}';
  }

  /// Registers a marker image if not already registered.
  Future<void> _ensureMarkerImageRegistered(DefaultMarkerIcon icon) async {
    final controller = _mapController;
    if (controller == null) return;

    final imageName = _markerImageName(icon);
    if (_registeredImages.contains(imageName)) return;

    final imageBytes = await _generateMarkerImage(icon);
    if (imageBytes != null) {
      await controller.addImage(imageName, imageBytes);
      _registeredImages.add(imageName);
    }
  }

  /// Registers an asset marker image if not already registered.
  Future<void> _ensureAssetMarkerImageRegistered(AssetMarkerIcon icon) async {
    final controller = _mapController;
    if (controller == null) return;

    final imageName = _assetMarkerImageName(icon);
    if (_registeredImages.contains(imageName)) return;

    final bytes = await _loadAssetMarkerImage(icon);
    if (bytes != null) {
      await controller.addImage(imageName, bytes);
      _registeredImages.add(imageName);
    }
  }

  /// Generates a PNG image for a DefaultMarkerIcon.
  Future<Uint8List?> _generateMarkerImage(DefaultMarkerIcon icon) async {
    // Use 2x scale for better quality on high-DPI screens
    const scale = 2.0;
    final size = icon.size * scale;
    final height = size * 1.3;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw outer border/stroke
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale;

    final paint = Paint()
      ..color = icon.color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color.fromARGB(60, 0, 0, 0)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);

    final centerX = size / 2;
    final pinRadius = size / 2 - 4 * scale;
    final pinHeight = height - 2 * scale;

    Path createPinPath() {
      return Path()
        ..moveTo(centerX, pinHeight)
        ..quadraticBezierTo(
          centerX - pinRadius * 0.7,
          pinHeight - pinRadius * 1.4,
          centerX - pinRadius,
          pinRadius + 2 * scale,
        )
        ..arcTo(
          Rect.fromCircle(
            center: Offset(centerX, pinRadius + 2 * scale),
            radius: pinRadius,
          ),
          3.14159,
          -3.14159,
          false,
        )
        ..quadraticBezierTo(
          centerX + pinRadius * 0.7,
          pinHeight - pinRadius * 1.4,
          centerX,
          pinHeight,
        );
    }

    // Draw shadow
    canvas.drawPath(
      createPinPath().shift(Offset(2 * scale, 3 * scale)),
      shadowPaint,
    );

    // Draw white border
    canvas.drawPath(createPinPath(), strokePaint);

    // Draw pin body
    canvas.drawPath(createPinPath(), paint);

    // Draw inner white circle
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(centerX, pinRadius + 2 * scale),
      pinRadius * 0.35,
      innerPaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// Adds a marker to the map.
  Future<void> addMarker(Marker marker) async {
    final controller = _mapController;
    if (controller == null) return;

    // Resolve icon to base type for native rendering
    final resolvedIcon = _resolveBaseIcon(marker.icon);

    // Register marker image if needed
    await _ensureIconImageRegistered(resolvedIcon);
    await _ensureFallbackMarkerImageRegistered();

    // Remove existing marker with same ID
    await removeMarker(marker.id);

    final symbolOptions = SymbolOptions(
      geometry: LatLng(marker.position.lat, marker.position.lon),
      iconSize: _resolveIconSize(marker),
      iconImage: _resolveIconImage(marker),
      iconColor: _resolveIconColor(marker),
      iconAnchor: _convertAnchor(marker.anchor),
      iconRotate: marker.rotation,
      textField: _resolveTextField(marker),
      textSize: _resolveTextSize(marker),
      textColor: _resolveTextColor(marker),
      textHaloColor: _resolveTextHaloColor(marker),
      textHaloWidth: _resolveTextHaloWidth(marker),
      textOffset: _resolveTextOffset(marker),
      zIndex: marker.zIndex,
      draggable: marker.draggable,
    );

    final symbol = await controller.addSymbol(symbolOptions);

    _markers[marker.id] = symbol;
    _symbolToMarkerId[symbol.id] = marker.id;
    notifyListeners();
  }

  /// Adds multiple markers to the map using batch operation.
  /// This is more efficient than calling addMarker() multiple times
  /// as it uses a single platform channel call via addSymbols().
  Future<void> addMarkers(List<Marker> markers) async {
    final controller = _mapController;
    if (controller == null) return;
    if (markers.isEmpty) return;

    final stopwatch = Stopwatch()..start();
    _log(_LogLevel.debug, 'addMarkers START', {'count': markers.length});

    // Step 1: Pre-register all marker images (still sequential due to image generation)
    final imagesToRegister = <MarkerIcon>[];
    for (final marker in markers) {
      final resolvedIcon = _resolveBaseIcon(marker.icon);
      if (!_isImageRegistered(resolvedIcon)) {
        imagesToRegister.add(resolvedIcon);
      }
    }

    if (imagesToRegister.isNotEmpty) {
      _log(_LogLevel.debug, 'Registering marker images', {'count': imagesToRegister.length});
      await Future.wait(
        imagesToRegister.map((icon) => _ensureIconImageRegistered(icon)),
      );
    }

    // Pre-register fallback image for any markers whose images failed to load
    await _ensureFallbackMarkerImageRegistered();

    // Step 2: Remove existing markers with same IDs (batch)
    final existingIds = markers.map((m) => m.id).where((id) => _markers.containsKey(id)).toList();
    if (existingIds.isNotEmpty) {
      _log(_LogLevel.debug, 'Removing existing markers', {'count': existingIds.length});
      await _removeMarkersBatchInternal(existingIds);
    }

    // Step 3: Build all SymbolOptions in one pass
    final symbolOptionsList = <SymbolOptions>[];
    final markerIdOrder = <String>[];

    for (final marker in markers) {
      final options = SymbolOptions(
        geometry: LatLng(marker.position.lat, marker.position.lon),
        iconSize: _resolveIconSize(marker),
        iconImage: _resolveIconImage(marker),
        iconColor: _resolveIconColor(marker),
        iconAnchor: _convertAnchor(marker.anchor),
        iconRotate: marker.rotation,
        textField: _resolveTextField(marker),
        textSize: _resolveTextSize(marker),
        textColor: _resolveTextColor(marker),
        textHaloColor: _resolveTextHaloColor(marker),
        textHaloWidth: _resolveTextHaloWidth(marker),
        textOffset: _resolveTextOffset(marker),
        zIndex: marker.zIndex,
        draggable: marker.draggable,
      );
      symbolOptionsList.add(options);
      markerIdOrder.add(marker.id);
    }

    // Step 4: Single platform call to add all symbols
    _log(_LogLevel.debug, 'Calling addSymbols', {'count': symbolOptionsList.length});
    final symbols = await controller.addSymbols(symbolOptionsList);

    // Step 5: Update internal state
    for (var i = 0; i < symbols.length; i++) {
      final markerId = markerIdOrder[i];
      final symbol = symbols[i];
      _markers[markerId] = symbol;
      _symbolToMarkerId[symbol.id] = markerId;
    }

    stopwatch.stop();
    _log(_LogLevel.info, 'addMarkers COMPLETE', {
      'count': markers.length,
      'durationMs': stopwatch.elapsedMilliseconds,
      'avgPerMarker': markers.isNotEmpty
          ? (stopwatch.elapsedMilliseconds / markers.length).toStringAsFixed(2)
          : 0,
    });

    notifyListeners();
  }

  /// Checks if a marker image is already registered.
  bool _isImageRegistered(MarkerIcon icon) {
    final name = _iconImageName(icon);
    if (name == null) return true; // Unknown type, nothing to register
    return _registeredImages.contains(name);
  }

  /// Returns the image name for any supported MarkerIcon type, or null.
  String? _iconImageName(MarkerIcon icon) {
    if (icon is AvatarMarkerIcon) {
      return _friendAvatarMarkerImageName(icon);
    }
    if (icon is NetworkMarkerIcon) {
      return _networkMarkerImageName(icon);
    }
    if (icon is SvgMarkerIcon) {
      return _svgMarkerImageName(icon);
    }
    if (icon is WidgetMarkerIcon) {
      return _widgetMarkerImageName(icon);
    }
    if (icon is DefaultMarkerIcon) {
      return _markerImageName(icon);
    }
    if (icon is AssetMarkerIcon) {
      return _assetMarkerImageName(icon);
    }
    if (icon is NumberedMarkerIcon) {
      return _numberedMarkerImageName(icon);
    }
    return null;
  }

  /// Removes multiple markers by IDs using batch operation.
  /// More efficient than calling removeMarker() multiple times
  /// as it uses a single platform channel call via removeSymbols().
  Future<void> removeMarkers(List<String> markerIds) async {
    final controller = _mapController;
    if (controller == null) return;
    if (markerIds.isEmpty) return;

    final stopwatch = Stopwatch()..start();
    _log(_LogLevel.debug, 'removeMarkers START', {'count': markerIds.length});

    final symbolsToRemove = <Symbol>[];
    for (final markerId in markerIds) {
      final symbol = _markers.remove(markerId);
      if (symbol != null) {
        _symbolToMarkerId.remove(symbol.id);
        symbolsToRemove.add(symbol);
      }
    }

    if (symbolsToRemove.isNotEmpty) {
      // Single platform call to remove all symbols
      await controller.removeSymbols(symbolsToRemove);
    }

    stopwatch.stop();
    _log(_LogLevel.info, 'removeMarkers COMPLETE', {
      'requested': markerIds.length,
      'removed': symbolsToRemove.length,
      'durationMs': stopwatch.elapsedMilliseconds,
    });

    notifyListeners();
  }

  /// Internal batch remove without notifyListeners().
  /// Used by addMarkers() to remove existing markers before re-adding.
  Future<void> _removeMarkersBatchInternal(List<String> markerIds) async {
    final controller = _mapController;
    if (controller == null) return;
    if (markerIds.isEmpty) return;

    final symbolsToRemove = <Symbol>[];
    for (final markerId in markerIds) {
      final symbol = _markers.remove(markerId);
      if (symbol != null) {
        _symbolToMarkerId.remove(symbol.id);
        symbolsToRemove.add(symbol);
      }
    }

    if (symbolsToRemove.isNotEmpty) {
      await controller.removeSymbols(symbolsToRemove);
    }
  }

  /// Removes a marker from the map.
  Future<void> removeMarker(String markerId) async {
    final controller = _mapController;
    if (controller == null) return;

    final symbol = _markers.remove(markerId);
    if (symbol != null) {
      _symbolToMarkerId.remove(symbol.id);
      await controller.removeSymbol(symbol);
      notifyListeners();
    }
  }

  /// Removes all markers from the map using batch operation.
  /// Uses clearSymbols() for optimal performance.
  Future<void> clearMarkers() async {
    final controller = _mapController;
    if (controller == null) return;

    final count = _markers.length;
    if (count == 0) return;

    final stopwatch = Stopwatch()..start();
    _log(_LogLevel.debug, 'clearMarkers START', {'count': count});

    // Clear internal state first
    _markers.clear();
    _symbolToMarkerId.clear();

    // Single platform call to clear all symbols
    await controller.clearSymbols();

    stopwatch.stop();
    _log(_LogLevel.info, 'clearMarkers COMPLETE', {
      'count': count,
      'durationMs': stopwatch.elapsedMilliseconds,
    });

    notifyListeners();
  }

  /// Updates a marker's position.
  Future<void> updateMarkerPosition(
    String markerId,
    Coordinates newPosition,
  ) async {
    final controller = _mapController;
    if (controller == null) return;

    final symbol = _markers[markerId];
    if (symbol != null) {
      await controller.updateSymbol(
        symbol,
        SymbolOptions(
          geometry: LatLng(newPosition.lat, newPosition.lon),
        ),
      );
    }
  }

  /// Resolves an icon to its base type for native rendering.
  /// AnimatedMarkerIcon and CachedMarkerIcon are converted to their underlying icons.
  MarkerIcon _resolveBaseIcon(MarkerIcon icon) {
    if (icon is AnimatedMarkerIcon) {
      // Convert AnimatedMarkerIcon to DefaultMarkerIcon for native rendering
      // (animations are only supported in Flutter widgets, not native MapLibre)
      return DefaultMarkerIcon(
        color: icon.color,
        size: icon.size,
        style: icon.style,
        showShadow: icon.showShadow,
        innerIcon: icon.innerIcon,
      );
    }
    if (icon is CachedMarkerIcon) {
      // Recursively resolve the base icon
      return _resolveBaseIcon(icon.baseIcon);
    }
    return icon;
  }

  /// Generates a marker image name for a NumberedMarkerIcon.
  String _numberedMarkerImageName(NumberedMarkerIcon icon) {
    return 'numbered_${icon.color.toARGB32().toRadixString(16)}_${icon.textColor.toARGB32().toRadixString(16)}_${icon.size.toInt()}_${icon.displayText}';
  }

  /// Registers a numbered marker image if not already registered.
  Future<void> _ensureNumberedMarkerImageRegistered(NumberedMarkerIcon icon) async {
    final controller = _mapController;
    if (controller == null) return;

    final imageName = _numberedMarkerImageName(icon);
    if (_registeredImages.contains(imageName)) return;

    final imageBytes = await _generateNumberedMarkerImage(icon);
    if (imageBytes != null) {
      await controller.addImage(imageName, imageBytes);
      _registeredImages.add(imageName);
    }
  }

  /// Generates a PNG image for a NumberedMarkerIcon.
  Future<Uint8List?> _generateNumberedMarkerImage(NumberedMarkerIcon icon) async {
    const scale = 2.0;
    final size = icon.size * scale;
    final height = size * 1.3;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw the pin shape (same as DefaultMarkerIcon)
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale;

    final paint = Paint()
      ..color = icon.color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color.fromARGB(60, 0, 0, 0)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);

    final centerX = size / 2;
    final pinRadius = size / 2 - 4 * scale;
    final pinHeight = height - 2 * scale;

    Path createPinPath() {
      return Path()
        ..moveTo(centerX, pinHeight)
        ..quadraticBezierTo(
          centerX - pinRadius * 0.7,
          pinHeight - pinRadius * 1.4,
          centerX - pinRadius,
          pinRadius + 2 * scale,
        )
        ..arcTo(
          Rect.fromCircle(
            center: Offset(centerX, pinRadius + 2 * scale),
            radius: pinRadius,
          ),
          3.14159,
          -3.14159,
          false,
        )
        ..quadraticBezierTo(
          centerX + pinRadius * 0.7,
          pinHeight - pinRadius * 1.4,
          centerX,
          pinHeight,
        );
    }

    // Draw shadow
    canvas.drawPath(
      createPinPath().shift(Offset(2 * scale, 3 * scale)),
      shadowPaint,
    );

    // Draw white border
    canvas.drawPath(createPinPath(), strokePaint);

    // Draw pin body
    canvas.drawPath(createPinPath(), paint);

    // Draw number/text
    final displayText = icon.displayText;
    double fontSize;
    if (displayText.length == 1) {
      fontSize = pinRadius * 0.9;
    } else if (displayText.length == 2) {
      fontSize = pinRadius * 0.7;
    } else {
      fontSize = pinRadius * 0.5;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          color: icon.textColor,
          fontSize: fontSize,
          fontWeight: icon.fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        (pinRadius + 2 * scale) - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  String _convertAnchor(MarkerAnchor anchor) {
    if (anchor.x == 0.5 && anchor.y == 0.5) return 'center';
    if (anchor.x == 0.5 && anchor.y == 1) return 'bottom';
    if (anchor.x == 0.5 && anchor.y == 0) return 'top';
    if (anchor.x == 0 && anchor.y == 0.5) return 'left';
    if (anchor.x == 1 && anchor.y == 0.5) return 'right';
    if (anchor.x == 0 && anchor.y == 0) return 'top-left';
    if (anchor.x == 1 && anchor.y == 0) return 'top-right';
    if (anchor.x == 0 && anchor.y == 1) return 'bottom-left';
    if (anchor.x == 1 && anchor.y == 1) return 'bottom-right';
    return 'center';
  }

  // ==================== ROUTES ====================

  /// Displays a route on the map.
  Future<void> displayRoute(
    RouteResponse route, {
    String? id,
    RouteLineOptions? options,
  }) async {
    final coordinates = route.decodedPolyline;
    if (coordinates == null || coordinates.isEmpty) return;

    final routeId = id ?? 'route_${DateTime.now().millisecondsSinceEpoch}';
    await displayRouteLine(RouteLine(
      id: routeId,
      coordinates: coordinates,
      options: options ?? RouteLineOptions.primary(),
    ));
  }

  /// Displays a route line on the map.
  Future<void> displayRouteLine(RouteLine routeLine) async {
    final controller = _mapController;
    if (controller == null) return;

    // Remove existing route with same ID
    await removeRoute(routeLine.id);

    final line = await controller.addLine(
      LineOptions(
        geometry: routeLine.coordinates
            .map((c) => LatLng(c.lat, c.lon))
            .toList(),
        lineColor: _colorToHex(routeLine.options.color),
        lineWidth: routeLine.options.width,
        lineOpacity: routeLine.options.opacity,
      ),
    );

    _routeLines[routeLine.id] = line;
    notifyListeners();
  }

  /// Removes a route from the map.
  Future<void> removeRoute(String routeId) async {
    final controller = _mapController;
    if (controller == null) return;

    final line = _routeLines.remove(routeId);
    if (line != null) {
      await controller.removeLine(line);
      notifyListeners();
    }
  }

  /// Removes all routes from the map.
  Future<void> clearRoutes() async {
    final controller = _mapController;
    if (controller == null) return;

    // Copy values to avoid concurrent modification
    final lines = _routeLines.values.toList();
    _routeLines.clear();

    for (final line in lines) {
      await controller.removeLine(line);
    }
    notifyListeners();
  }

  /// Fits the camera to show the entire route.
  Future<void> fitRoute(
    RouteResponse route, {
    EdgeInsets padding = const EdgeInsets.all(50),
  }) async {
    final coordinates = route.decodedPolyline;
    if (coordinates == null || coordinates.isEmpty) return;

    await animateCamera(sdk.CameraUpdate.newLatLngBounds(
      coordinates,
      padding: padding.left,
    ));
  }

  String _colorToHex(Color color) {
    final argb = color.toARGB32();
    return '#${argb.toRadixString(16).substring(2)}';
  }

  double _resolveIconSize(Marker marker) {
    if (marker is ClusterMarker) {
      return marker.style.iconSize;
    }
    if (marker.icon is DefaultMarkerIcon) {
      return 1.0;
    }
    if (marker.icon is AssetMarkerIcon) {
      return 1.0;
    }
    return 1.0;
  }

  String? _resolveIconImage(Marker marker) {
    if (marker is ClusterMarker) {
      return marker.style.iconImage;
    }

    // Resolve to base icon for animated/cached markers
    final icon = _resolveBaseIcon(marker.icon);
    final name = _iconImageName(icon);

    // If the image was supposed to be registered but wasn't (e.g. network
    // failure), fall back to the default marker so the symbol is visible.
    if (name != null && !_registeredImages.contains(name)) {
      return _fallbackImageName;
    }
    return name;
  }

  static const String _fallbackImageName = 'fallback_default_marker';

  Future<void> _ensureFallbackMarkerImageRegistered() async {
    final controller = _mapController;
    if (controller == null) return;
    if (_registeredImages.contains(_fallbackImageName)) return;

    const fallback = DefaultMarkerIcon(
      color: Color(0xFF6366F1),
      size: 48,
      style: MarkerStyle.modern,
    );
    final bytes = await _generateMarkerImage(fallback);
    if (bytes != null) {
      await controller.addImage(_fallbackImageName, bytes);
      _registeredImages.add(_fallbackImageName);
    }
  }

  String? _resolveIconColor(Marker marker) {
    if (marker is ClusterMarker) {
      return _colorToHex(marker.style.iconColor);
    }
    return null;
  }

  String? _resolveTextField(Marker marker) {
    if (marker is ClusterMarker) {
      return marker.count.toString();
    }
    return null;
  }

  double? _resolveTextSize(Marker marker) {
    if (marker is ClusterMarker) {
      return marker.style.textSize;
    }
    return null;
  }

  String? _resolveTextColor(Marker marker) {
    if (marker is ClusterMarker) {
      return _colorToHex(marker.style.textColor);
    }
    return null;
  }

  String? _resolveTextHaloColor(Marker marker) {
    if (marker is ClusterMarker) {
      return _colorToHex(marker.style.textHaloColor);
    }
    return null;
  }

  double? _resolveTextHaloWidth(Marker marker) {
    if (marker is ClusterMarker) {
      return marker.style.textHaloWidth;
    }
    return null;
  }

  Offset? _resolveTextOffset(Marker marker) {
    if (marker is ClusterMarker) {
      return const Offset(0, 0.0);
    }
    return null;
  }

  // ==================== UNIFIED IMAGE REGISTRATION ====================

  /// Registers a marker icon image with MapLibre based on its type.
  Future<void> _ensureIconImageRegistered(MarkerIcon icon) async {
    if (icon is AvatarMarkerIcon) {
      await _ensureFriendAvatarMarkerImageRegistered(icon);
    } else if (icon is NetworkMarkerIcon) {
      await _ensureNetworkMarkerImageRegistered(icon);
    } else if (icon is SvgMarkerIcon) {
      await _ensureSvgMarkerImageRegistered(icon);
    } else if (icon is WidgetMarkerIcon) {
      await _ensureWidgetMarkerImageRegistered(icon);
    } else if (icon is DefaultMarkerIcon) {
      await _ensureMarkerImageRegistered(icon);
    } else if (icon is AssetMarkerIcon) {
      await _ensureAssetMarkerImageRegistered(icon);
    } else if (icon is NumberedMarkerIcon) {
      await _ensureNumberedMarkerImageRegistered(icon);
    }
  }

  // ==================== NETWORK MARKER ====================

  String _networkMarkerImageName(NetworkMarkerIcon icon) {
    return 'network_${icon.url.hashCode.toRadixString(16)}_${icon.width.toInt()}x${icon.height.toInt()}';
  }

  Future<void> _ensureNetworkMarkerImageRegistered(NetworkMarkerIcon icon) async {
    final controller = _mapController;
    if (controller == null) return;

    final imageName = _networkMarkerImageName(icon);
    if (_registeredImages.contains(imageName)) return;

    try {
      final response = await _dio.get<List<int>>(
        icon.url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        dev.log(
          '[QorviaMapController] NetworkMarkerIcon: empty response from ${icon.url}',
          level: 900,
        );
        return;
      }

      // Decode and resize to requested dimensions
      final codec = await ui.instantiateImageCodec(
        Uint8List.fromList(bytes),
        targetWidth: (icon.width * 2).toInt(),
        targetHeight: (icon.height * 2).toInt(),
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      frame.image.dispose();

      if (byteData != null) {
        await controller.addImage(imageName, byteData.buffer.asUint8List());
        _registeredImages.add(imageName);
        dev.log(
          '[QorviaMapController] Registered NetworkMarkerIcon: $imageName',
          level: 800,
        );
      }
    } catch (e) {
      dev.log(
        '[QorviaMapController] Failed to register NetworkMarkerIcon '
        '(${icon.url}): $e',
        level: 900,
      );
    }
  }

  // ==================== SVG MARKER ====================

  String _svgMarkerImageName(SvgMarkerIcon icon) {
    final colorKey = icon.color?.toARGB32().toRadixString(16) ?? 'none';
    return 'svg_${icon.assetPath.hashCode.toRadixString(16)}_${icon.size.toInt()}_$colorKey';
  }

  Future<void> _ensureSvgMarkerImageRegistered(SvgMarkerIcon icon) async {
    final controller = _mapController;
    if (controller == null) return;

    final imageName = _svgMarkerImageName(icon);
    if (_registeredImages.contains(imageName)) return;

    try {
      final imageBytes = await _renderWidgetToImage(
        svg.SvgPicture.asset(
          icon.assetPath,
          width: icon.size,
          height: icon.size,
          colorFilter: icon.color != null
              ? ColorFilter.mode(icon.color!, BlendMode.srcIn)
              : null,
        ),
        icon.size,
        icon.size,
      );

      if (imageBytes != null) {
        await controller.addImage(imageName, imageBytes);
        _registeredImages.add(imageName);
      }
    } catch (e) {
      dev.log(
        '[QorviaMapController] Failed to register SvgMarkerIcon '
        '(${icon.assetPath}): $e',
        level: 900,
      );
    }
  }

  // ==================== WIDGET MARKER ====================

  String _widgetMarkerImageName(WidgetMarkerIcon icon) {
    return 'widget_${icon.child.hashCode.toRadixString(16)}_${icon.width.toInt()}x${icon.height.toInt()}';
  }

  Future<void> _ensureWidgetMarkerImageRegistered(WidgetMarkerIcon icon) async {
    final controller = _mapController;
    if (controller == null) return;

    final imageName = _widgetMarkerImageName(icon);
    if (_registeredImages.contains(imageName)) return;

    try {
      final imageBytes = await _renderWidgetToImage(
        icon.child,
        icon.width,
        icon.height,
      );

      if (imageBytes != null) {
        await controller.addImage(imageName, imageBytes);
        _registeredImages.add(imageName);
      }
    } catch (e) {
      dev.log(
        '[QorviaMapController] Failed to register WidgetMarkerIcon: $e',
        level: 900,
      );
    }
  }

  /// Renders a Flutter widget to PNG bytes offscreen.
  Future<Uint8List?> _renderWidgetToImage(
    Widget widget,
    double width,
    double height,
  ) async {
    const scale = 2.0;

    final repaintBoundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: ui.PlatformDispatcher.instance.implicitView!,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(Size(width, height)),
        devicePixelRatio: scale,
      ),
    );

    final pipelineOwner = PipelineOwner();
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final buildOwner = BuildOwner(focusManager: FocusManager());
    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: widget,
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: scale);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return byteData?.buffer.asUint8List();
  }

  // ==================== FRIEND AVATAR MARKER ====================

  /// Generates a unique image name for a FriendAvatarMarkerIcon.
  String _friendAvatarMarkerImageName(AvatarMarkerIcon icon) {
    final headingKey = icon.heading?.toStringAsFixed(0) ?? 'none';
    final urlKey = icon.avatarUrl?.hashCode.toRadixString(16) ?? 'placeholder';
    return 'friend_avatar_${urlKey}_${headingKey}_${icon.size.toInt()}_${icon.borderColor.toARGB32().toRadixString(16)}';
  }

  /// Registers a FriendAvatarMarkerIcon image with MapLibre if not already cached.
  Future<void> _ensureFriendAvatarMarkerImageRegistered(
    AvatarMarkerIcon icon,
  ) async {
    final controller = _mapController;
    if (controller == null) {
      dev.log(
        '[QorviaMapController] _ensureFriendAvatarMarkerImageRegistered: '
        'controller is null, skipping',
        level: 900,
      );
      return;
    }

    final imageName = _friendAvatarMarkerImageName(icon);
    if (_registeredImages.contains(imageName)) return;

    try {
      // Load avatar from network if URL provided
      ui.Image? avatarImage;
      if (icon.avatarUrl != null && icon.avatarUrl!.isNotEmpty) {
        avatarImage = await _loadNetworkImageForAvatar(icon.avatarUrl!);
      }

      // Generate the composite marker image
      final imageBytes =
          await _generateFriendAvatarMarkerImage(icon, avatarImage);

      if (imageBytes != null) {
        await controller.addImage(imageName, imageBytes);
        _registeredImages.add(imageName);
        dev.log(
          '[QorviaMapController] Registered friend avatar image: $imageName '
          '(${imageBytes.length} bytes)',
          level: 800,
        );
      } else {
        dev.log(
          '[QorviaMapController] Failed to generate friend avatar image: '
          '$imageName',
          level: 900,
        );
      }

      avatarImage?.dispose();
    } catch (e, stack) {
      dev.log(
        '[QorviaMapController] Error registering friend avatar: $e',
        level: 1000,
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Returns the shared Dio instance, creating it if needed.
  Dio get _dio => _sharedDio ??= Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 5),
    followRedirects: true,
    maxRedirects: 5,
  ));

  /// Loads an image from a network URL and decodes it.
  Future<ui.Image?> _loadNetworkImageForAvatar(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;

      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      dev.log(
        '[QorviaMapController] Failed to load avatar image from $url: $e',
        level: 900,
      );
      return null;
    }
  }

  /// Generates a PNG image for a FriendAvatarMarkerIcon.
  ///
  /// Renders a circular avatar with border, optional heading arrow, and shadow.
  Future<Uint8List?> _generateFriendAvatarMarkerImage(
    AvatarMarkerIcon icon,
    ui.Image? avatarImage,
  ) async {
    const scale = 2.0;
    final totalSize = icon.totalSize * scale;
    if (totalSize <= 0) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(totalSize / 2, totalSize / 2);
    final radius = (icon.size / 2) * scale;
    final borderW = icon.borderWidth * scale;

    // Draw shadow
    if (icon.showShadow) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);
      canvas.drawCircle(
        center + Offset(0, 2 * scale),
        radius,
        shadowPaint,
      );
    }

    // Draw heading arrow
    if (icon.showHeadingIndicator && icon.heading != null) {
      final arrowPaint = Paint()
        ..color = icon.borderColor
        ..style = PaintingStyle.fill;
      final arrowLength = icon.arrowSize * scale;
      final headingRad = (icon.heading! - 90) * (math.pi / 180);
      final arrowTip = Offset(
        center.dx + (radius + arrowLength) * math.cos(headingRad),
        center.dy + (radius + arrowLength) * math.sin(headingRad),
      );
      final arrowBaseAngle = math.pi / 6;
      final arrowBase1 = Offset(
        center.dx + radius * math.cos(headingRad - arrowBaseAngle),
        center.dy + radius * math.sin(headingRad - arrowBaseAngle),
      );
      final arrowBase2 = Offset(
        center.dx + radius * math.cos(headingRad + arrowBaseAngle),
        center.dy + radius * math.sin(headingRad + arrowBaseAngle),
      );
      canvas.drawPath(
        Path()
          ..moveTo(arrowTip.dx, arrowTip.dy)
          ..lineTo(arrowBase1.dx, arrowBase1.dy)
          ..lineTo(arrowBase2.dx, arrowBase2.dy)
          ..close(),
        arrowPaint,
      );
    }

    // Draw border circle
    final borderPaint = Paint()
      ..color = icon.borderColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw avatar or placeholder
    final innerRadius = radius - borderW;
    if (avatarImage != null) {
      // Clip to circle and draw avatar
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)),
      );
      final srcRect = Rect.fromLTWH(
        0,
        0,
        avatarImage.width.toDouble(),
        avatarImage.height.toDouble(),
      );
      final dstRect = Rect.fromCircle(center: center, radius: innerRadius);
      canvas.drawImageRect(avatarImage, srcRect, dstRect, Paint());
      canvas.restore();
    } else {
      // Draw placeholder background
      final bgPaint = Paint()
        ..color = icon.placeholderBackgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, innerRadius, bgPaint);

      // Draw placeholder icon
      final iconSize = innerRadius * 1.2;
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.placeholderIcon.codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: icon.placeholderIcon.fontFamily,
            package: icon.placeholderIcon.fontPackage,
            color: icon.placeholderIconColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(totalSize.ceil(), totalSize.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return byteData?.buffer.asUint8List();
  }

  // ==================== STYLE ====================

  /// Changes the map style to the specified URL.
  ///
  /// Note: This will clear all markers and routes, which need to be re-added
  /// after the style loads. The [QorviaMapView] handles this automatically.
  ///
  /// Example:
  /// ```dart
  /// await controller.setStyle(MapStyles.ourMapsDark);
  /// ```
  Future<void> setStyle(String styleUrl) async {
    final controller = _mapController;
    if (controller == null) {
      _log(_LogLevel.debug, 'setStyle: controller is null, skipping');
      return;
    }

    _log(_LogLevel.info, 'setStyle START', {'url': styleUrl});

    // Clear internal state as style change resets the map layer
    // (MapLibre removes all symbols/lines when style changes)
    final markerCount = _markers.length;
    final routeCount = _routeLines.length;
    final imageCount = _registeredImages.length;

    _markers.clear();
    _symbolToMarkerId.clear();
    _registeredImages.clear();
    _routeLines.clear();

    _log(_LogLevel.debug, 'setStyle: cleared state', {
      'markers': markerCount,
      'routes': routeCount,
      'images': imageCount,
    });

    try {
      await controller.setStyle(styleUrl);
      _log(_LogLevel.info, 'setStyle COMPLETE', {'url': styleUrl});
    } catch (e, stack) {
      dev.log(
        '[QorviaMapController] setStyle ERROR: $e',
        level: 1000,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ==================== CLEANUP ====================

  @override
  void dispose() {
    _sharedDio?.close();
    _sharedDio = null;
    _mapController = null;
    _markers.clear();
    _routeLines.clear();
    _registeredImages.clear();
    super.dispose();
  }

  String _assetMarkerImageName(AssetMarkerIcon icon) {
    return 'asset_${icon.assetPath}_${icon.width.toInt()}x${icon.height.toInt()}';
  }

  Future<Uint8List?> _loadAssetMarkerImage(AssetMarkerIcon icon) async {
    try {
      final data = await rootBundle.load(icon.assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: icon.width.toInt(),
        targetHeight: icon.height.toInt(),
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
