import 'dart:developer' as dev;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../models/coordinates.dart';
import 'user_location_style.dart';

/// Source and layer IDs for the user location marker.
const _kSourceId = 'user-location-source';
const _kLayerId = 'user-location-layer';
const _kAccuracySourceId = 'user-location-accuracy-source';
const _kAccuracyLayerId = 'user-location-accuracy-layer';
const _kCustomIconName = 'user-location-icon';

/// Public layer ID for the user location marker.
///
/// Can be used by other components to place their layers below the user
/// location via MapLibre `belowLayerId`.
const kUserLocationLayerId = _kLayerId;

/// Manages custom user location marker on map via GeoJSON source.
///
/// Creates and updates a GeoJSON point with rotation property for the user
/// direction indicator. Uses MapLibre symbol layer with icon-rotation-alignment
/// for bearing-aligned rendering.
///
/// Example usage:
/// ```dart
/// final layer = UserLocationLayer(
///   style: UserLocationStyle(
///     iconAsset: 'assets/icons/my_car.png',
///     iconSize: 1.5,
///   ),
/// );
/// await layer.attach(mapController);
/// await layer.update(coordinates, bearing, accuracy);
/// ```
class UserLocationLayer {
  MaplibreMapController? _mapController;
  final UserLocationStyle style;

  bool _layerAdded = false;
  DateTime? _lastUpdate;

  /// Throttle update rate (~60fps for smooth animation).
  static const _throttleMs = 16;

  /// Log level threshold (500 = debug, 800 = info, 1000 = error).
  static const _logLevel = 500;

  /// Creates a user location layer with the given style.
  UserLocationLayer({required this.style});

  /// Whether the layer has been added to the map.
  bool get isAttached => _layerAdded;

  /// Attaches the layer to a MapLibre controller and sets up map layers.
  ///
  /// Must be called after the map style has loaded.
  Future<void> attach(MaplibreMapController controller) async {
    _mapController = controller;

    dev.log(
      '[UserLocationLayer.attach] START '
      'iconAsset=${style.iconAsset}, '
      'iconSize=${style.iconSize}, '
      'showAccuracyCircle=${style.showAccuracyCircle}',
      level: _logLevel,
    );

    await _addLayers();

    dev.log('[UserLocationLayer.attach] COMPLETE layerAdded=$_layerAdded', level: _logLevel);
  }

  /// Detaches from the map controller.
  void detach() {
    dev.log('[UserLocationLayer.detach] Detaching', level: _logLevel);
    _mapController = null;
    _layerAdded = false;
  }

  /// Updates the user location position and bearing.
  ///
  /// [position] geographic coordinates of the user.
  /// [bearing] heading in degrees (0-360, where 0 = north).
  /// [accuracy] GPS accuracy in meters (for accuracy circle).
  Future<void> update(
    Coordinates position,
    double bearing, {
    double accuracy = 0,
  }) async {
    if (_mapController == null || !_layerAdded) {
      dev.log(
        '[UserLocationLayer.update] SKIP controller=$_mapController, layerAdded=$_layerAdded',
        level: _logLevel,
      );
      return;
    }

    // Throttle updates for performance
    final now = DateTime.now();
    if (_lastUpdate != null &&
        now.difference(_lastUpdate!).inMilliseconds < _throttleMs) {
      return;
    }
    _lastUpdate = now;

    try {
      // Update arrow/icon source
      final locationGeoJson = _buildLocationGeoJson(position, bearing);
      await _mapController!.setGeoJsonSource(_kSourceId, locationGeoJson);

      // Update accuracy circle if enabled
      if (style.showAccuracyCircle && accuracy >= style.minAccuracyToShow) {
        final accuracyGeoJson = _buildAccuracyGeoJson(position, accuracy);
        await _mapController!.setGeoJsonSource(_kAccuracySourceId, accuracyGeoJson);
      }

      dev.log(
        '[UserLocationLayer.update] '
        'lat=${position.lat.toStringAsFixed(6)}, '
        'lon=${position.lon.toStringAsFixed(6)}, '
        'bearing=${bearing.toStringAsFixed(1)}, '
        'accuracy=${accuracy.toStringAsFixed(1)}',
        level: _logLevel,
      );
    } catch (e, stack) {
      dev.log(
        '[UserLocationLayer.update] ERROR: $e',
        level: 1000,
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Removes layers from the map.
  Future<void> remove() async {
    if (_mapController == null || !_layerAdded) return;

    dev.log('[UserLocationLayer.remove] Removing layers', level: _logLevel);

    try {
      await _mapController!.removeLayer(_kLayerId);
      await _mapController!.removeSource(_kSourceId);

      if (style.showAccuracyCircle) {
        await _mapController!.removeLayer(_kAccuracyLayerId);
        await _mapController!.removeSource(_kAccuracySourceId);
      }

      _layerAdded = false;
      dev.log('[UserLocationLayer.remove] COMPLETE', level: _logLevel);
    } catch (e, stack) {
      dev.log(
        '[UserLocationLayer.remove] ERROR: $e',
        level: 1000,
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Resets internal state (e.g., throttle timer).
  void reset() {
    _lastUpdate = null;
  }

  /// Disposes resources.
  void dispose() {
    dev.log('[UserLocationLayer.dispose] Disposing', level: _logLevel);
    _mapController = null;
    _layerAdded = false;
  }

  // --- Private ---

  Future<void> _addLayers() async {
    if (_mapController == null) return;

    try {
      // 1. Add accuracy circle (bottom layer, drawn first)
      if (style.showAccuracyCircle) {
        await _mapController!.addGeoJsonSource(
          _kAccuracySourceId,
          _buildAccuracyGeoJson(const Coordinates(lat: 0, lon: 0), 0),
        );
        await _mapController!.addCircleLayer(
          _kAccuracySourceId,
          _kAccuracyLayerId,
          CircleLayerProperties(
            circleRadius: 20, // Will be updated based on accuracy
            circleColor: _colorToHex(style.accuracyCircleColor),
            circleOpacity: style.accuracyCircleOpacity,
            circleStrokeColor: _colorToHex(style.accuracyCircleStrokeColor),
            circleStrokeWidth: style.accuracyCircleStrokeWidth,
            circleStrokeOpacity: style.accuracyCircleStrokeOpacity,
          ),
        );
        dev.log('[UserLocationLayer._addLayers] Accuracy circle layer added', level: _logLevel);
      }

      // 2. Register custom icon from asset
      final iconBytes = await _loadAssetIcon(style.iconAsset);
      if (iconBytes != null) {
        await _mapController!.addImage(_kCustomIconName, iconBytes);
        dev.log(
          '[UserLocationLayer._addLayers] Icon registered from asset: ${style.iconAsset}',
          level: _logLevel,
        );
      } else {
        // Fallback: generate default arrow programmatically
        final fallbackBytes = await _generateFallbackArrowImage();
        if (fallbackBytes != null) {
          await _mapController!.addImage(_kCustomIconName, fallbackBytes);
          dev.log(
            '[UserLocationLayer._addLayers] Using fallback arrow icon',
            level: 800,
          );
        }
      }

      // 3. Add user location symbol layer (top layer)
      await _mapController!.addGeoJsonSource(
        _kSourceId,
        _buildLocationGeoJson(const Coordinates(lat: 0, lon: 0), 0),
      );
      await _mapController!.addSymbolLayer(
        _kSourceId,
        _kLayerId,
        SymbolLayerProperties(
          iconImage: _kCustomIconName,
          iconSize: style.iconSize,
          iconRotate: [Expressions.get, 'bearing'],
          iconRotationAlignment: 'map',
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
      );

      _layerAdded = true;
      dev.log('[UserLocationLayer._addLayers] Symbol layer added', level: _logLevel);
    } catch (e, stack) {
      dev.log(
        '[UserLocationLayer._addLayers] ERROR: $e',
        level: 1000,
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Loads icon from Flutter assets.
  ///
  /// Returns PNG bytes or null if loading fails.
  Future<Uint8List?> _loadAssetIcon(String assetPath) async {
    dev.log('[UserLocationLayer._loadAssetIcon] Loading: $assetPath', level: _logLevel);

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      dev.log(
        '[UserLocationLayer._loadAssetIcon] SUCCESS size=${bytes.length} bytes',
        level: _logLevel,
      );
      return bytes;
    } catch (e, stack) {
      dev.log(
        '[UserLocationLayer._loadAssetIcon] FAILED: $e, using fallback',
        level: 800,
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Generates a fallback arrow image programmatically.
  ///
  /// Used when the asset icon cannot be loaded.
  Future<Uint8List?> _generateFallbackArrowImage() async {
    const scale = 2.0;
    const canvasSize = 48.0 * scale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const fillColor = Color(0xFF6366F1); // Indigo
    const borderColor = Colors.white;

    final centerX = canvasSize / 2;
    final centerY = canvasSize / 2;
    final arrowSize = canvasSize * 0.4;

    // Arrow path pointing up (north = 0°)
    final path = Path()
      ..moveTo(centerX, centerY - arrowSize)
      ..lineTo(centerX - arrowSize * 0.6, centerY + arrowSize * 0.5)
      ..lineTo(centerX, centerY + arrowSize * 0.2)
      ..lineTo(centerX + arrowSize * 0.6, centerY + arrowSize * 0.5)
      ..close();

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(1.5 * scale, 1.5 * scale)),
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0 * scale),
    );

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Border
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale,
    );

    // Center dot
    canvas.drawCircle(
      Offset(centerX, centerY),
      canvasSize * 0.05,
      Paint()..color = borderColor,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Map<String, dynamic> _buildLocationGeoJson(Coordinates position, double bearing) {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [position.lon, position.lat],
          },
          'properties': {
            'bearing': bearing,
          },
        },
      ],
    };
  }

  Map<String, dynamic> _buildAccuracyGeoJson(Coordinates position, double accuracy) {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [position.lon, position.lat],
          },
          'properties': {
            'accuracy': accuracy,
          },
        },
      ],
    };
  }

  String _colorToHex(Color color) {
    // Convert to ARGB32 and extract RGB (skip alpha)
    final argb = color.toARGB32();
    return '#${argb.toRadixString(16).substring(2)}';
  }
}
