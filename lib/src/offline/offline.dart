/// Offline support for Qorvia Maps SDK.
///
/// Provides API response caching, network monitoring,
/// and map tile downloading for offline use.
library;

// Configuration
export 'config/offline_config.dart';

// Connectivity
export 'connectivity/connectivity_service.dart';
export 'connectivity/network_status.dart';

// Offline-aware client
export 'client/offline_aware_client.dart';

// Tile management
export 'tiles/tiles.dart';

// Offline routing
export 'routing/offline_routing_service.dart';

// Offline geocoding
export 'geocoding/offline_geocoding_service.dart';

// Package management
export 'package/offline_package_manager.dart';
export 'package/models/offline_package.dart';
export 'package/models/package_content.dart';
export 'package/models/package_download_progress.dart';
export 'package/services/routing_data_service.dart';
export 'package/services/geocoding_data_service.dart';

// UI widgets
export 'ui/ui.dart';
