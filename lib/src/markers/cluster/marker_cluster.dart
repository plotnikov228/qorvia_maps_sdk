import 'package:flutter/material.dart';
import '../../models/coordinates.dart';
import '../marker.dart';
import '../marker_icon.dart';

/// Represents a cluster of nearby markers.
class MarkerCluster {
  final String id;
  final Coordinates position;
  final List<Marker> markers;

  const MarkerCluster({
    required this.id,
    required this.position,
    required this.markers,
  });

  int get count => markers.length;
}

/// Visual style for clustered markers on the map.
class MarkerClusterStyle {
  final String? iconImage;
  final double iconSize;
  final Color iconColor;
  final double textSize;
  final Color textColor;
  final Color textHaloColor;
  final double textHaloWidth;

  const MarkerClusterStyle({
    this.iconImage = 'marker-15',
    this.iconSize = 1.4,
    this.iconColor = Colors.deepOrange,
    this.textSize = 14,
    this.textColor = Colors.white,
    this.textHaloColor = Colors.black,
    this.textHaloWidth = 1.2,
  });
}

/// Options for marker clustering.
class MarkerClusterOptions {
  /// Enables or disables clustering.
  final bool enabled;

  /// Cluster radius in screen pixels.
  final double radiusPx;

  /// Minimum marker count to form a cluster.
  final int minClusterSize;

  /// Minimum zoom where clustering is active.
  final double minZoom;

  /// Maximum zoom where clustering is active.
  final double maxZoom;

  /// Visual style for clustered markers.
  final MarkerClusterStyle style;

  const MarkerClusterOptions({
    this.enabled = false, // Disabled by default to avoid issues with few markers
    this.radiusPx = 60,
    this.minClusterSize = 3, // At least 3 markers to form a cluster
    this.minZoom = 0,
    this.maxZoom = 18,
    this.style = const MarkerClusterStyle(),
  });
}

/// Marker representing a cluster on the map.
class ClusterMarker extends Marker {
  final MarkerCluster cluster;
  final MarkerClusterStyle style;

  ClusterMarker({
    required this.cluster,
    this.style = const MarkerClusterStyle(),
    MarkerIcon icon = const DefaultMarkerIcon(),
    MarkerAnchor anchor = MarkerAnchor.center,
    int zIndex = 0,
  }) : super(
          id: cluster.id,
          position: cluster.position,
          icon: icon,
          anchor: anchor,
          zIndex: zIndex,
          data: cluster,
        );

  int get count => cluster.count;
}
