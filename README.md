# Qorvia Maps SDK

Flutter SDK for geo services: navigation, routing, geocoding, and interactive maps powered by MapLibre GL.

[Русская версия](README.md)

## Getting API Key

To use the SDK, you need an API key. Go to [qorviamapkit.ru](https://qorviamapkit.ru) to create your API key and manage your account.

## Features

- **SDK Initialization** - Global configuration with automatic tile URL loading
- **API Client** - Routing, geocoding, reverse geocoding, quota and usage tracking
- **Map Widget** - Interactive MapLibre GL map with gesture support
- **Markers** - Default, SVG, asset, network, widget, numbered, animated and cached icons
- **Clustering** - Automatic marker clustering with customizable style
- **Route Display** - Configurable route line rendering
- **Turn-by-turn Navigation** - Real-time navigation with state tracking
- **Voice Guidance** - Text-to-speech navigation instructions
- **Location Service** - GPS tracking with Kalman filtering
- **Offline mode** — Navigation and maps without internet

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  qorvia_maps_sdk: ^0.2.9
```

### Platform Setup

**Android** - Add to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

**iOS** - Add to `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>App needs location access for navigation</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>App needs background location for turn-by-turn navigation</string>
```

## Quick Start

### Initialize the SDK

```dart
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SDK - automatically fetches map tile URL
  await QorviaMapsSDK.init(
    apiKey: 'your_api_key',
    enableLogging: true,  // optional, for debugging
  );

  runApp(MyApp());
}
```

### Display a Map

```dart
final controller = QorviaMapController();

QorviaMapView(
  controller: controller,
  options: const MapOptions(
    initialCenter: Coordinates(lat: 55.7539, lon: 37.6208),
    initialZoom: 13,
    showUserLocation: true,
  ),
  onMapTap: (coordinates) => print('Tapped: $coordinates'),
)
```

### Add Markers

```dart
QorviaMapView(
  controller: controller,
  options: MapOptions(
    initialCenter: Coordinates(lat: 55.7539, lon: 37.6208),
  ),
  markers: [
    // Default marker
    Marker(
      id: 'start',
      position: Coordinates(lat: 55.7539, lon: 37.6208),
      icon: DefaultMarkerIcon.start,
    ),
    // Numbered marker
    Marker(
      id: 'waypoint1',
      position: Coordinates(lat: 55.7545, lon: 37.6220),
      icon: NumberedMarkerIcon(number: 1),
    ),
    // Animated marker
    Marker(
      id: 'active',
      position: Coordinates(lat: 55.7550, lon: 37.6230),
      icon: AnimatedMarkerIcon.pulsingPrimary,
    ),
  ],
  onMarkerTap: (marker) => print('Tapped: ${marker.id}'),
)
```

### Marker Clustering

```dart
QorviaMapView(
  controller: controller,
  options: MapOptions(initialCenter: center),
  markers: myMarkers,
  clusterOptions: const MarkerClusterOptions(
    enabled: true,
    radiusPx: 60,
    minClusterSize: 3,
  ),
  onClusterTap: (cluster) => print('Cluster: ${cluster.count} markers'),
)
```

### Calculate Route

```dart
// Use the global SDK client
final client = QorviaMapsSDK.instance.client;

final route = await client.route(
  from: Coordinates(lat: 55.7539, lon: 37.6208),
  to: Coordinates(lat: 55.7614, lon: 37.6500),
  mode: TransportMode.car,
  language: 'ru',
);

print('Distance: ${route.formattedDistance}');
print('Duration: ${route.formattedDuration}');

// Display on map
controller.displayRoute(route, options: RouteLineOptions.primary());
```

### Geocoding

```dart
// Address to coordinates
final response = await client.geocode(
  query: 'Red Square, Moscow',
  limit: 5,
  language: 'en',
);

for (final result in response.results) {
  print('${result.displayName}: ${result.coordinates}');
}

// Geocoding with location bias (prioritize results near user)
final nearbyResponse = await client.geocode(
  query: 'train station',
  limit: 5,
  language: 'en',
  userLat: 53.404935,
  userLon: 58.965423,
  radiusKm: 50,
  biasLocation: true,
);
// Results are sorted by proximity to the specified coordinates

// Coordinates to address
final address = await client.reverse(
  coordinates: Coordinates(lat: 55.7539, lon: 37.6208),
  language: 'en',
);
print('Address: ${address.displayName}');
```

### Turn-by-Turn Navigation

```dart
NavigationView(
  route: route,
  options: NavigationOptions(
    enableVoiceInstructions: true,
    voiceGuidanceOptions: const VoiceGuidanceOptions(
      language: 'en-US',
      speechRate: 0.5,
    ),
    trackingMode: CameraTrackingMode.followWithBearing,
    autoReroute: true,
  ),
  onStateChanged: (state) {
    print('Distance remaining: ${state.distanceRemaining}m');
    print('ETA: ${state.estimatedArrival}');
  },
  onStepChanged: (step) => print('Next: ${step.instruction}'),
  onOffRoute: () => print('User went off route'),
  onArrival: () => print('Arrived at destination!'),
  onReroute: (from, to) async {
    // Return new route when user goes off-route
    return await client.route(from: from, to: to);
  },
)
```

## API Reference

### QorviaMapsSDK

Global SDK initializer and entry point.

```dart
// Initialize
await QorviaMapsSDK.init(apiKey: 'key');

// Check if initialized
if (QorviaMapsSDK.isInitialized) {
  final client = QorviaMapsSDK.instance.client;
}

// Get tile URL
final tileUrl = await QorviaMapsSDK.instance.getTileUrl();

// Dispose when done
QorviaMapsSDK.dispose();
```

### QorviaMapsClient

API client for all geo services.

| Method | Description |
|--------|-------------|
| `route()` | Calculate route between points |
| `geocode()` | Convert address to coordinates (with optional location bias) |
| `search()` | Single best match for query (with optional location bias) |
| `reverse()` | Convert coordinates to address |
| `quota()` | Get API quota information |
| `usage()` | Get usage statistics |
| `tileUrl()` | Get map tile style URL |

### QorviaMapView

Main map widget.

| Parameter | Type | Description |
|-----------|------|-------------|
| `controller` | `QorviaMapController?` | Map controller |
| `options` | `MapOptions` | Map configuration |
| `markers` | `List<Marker>` | Markers to display |
| `clusterOptions` | `MarkerClusterOptions?` | Clustering config |
| `routeLines` | `List<RouteLine>` | Routes to display |
| `onMapCreated` | `Function(QorviaMapController)` | Map ready callback |
| `onMarkerTap` | `Function(Marker)` | Marker tap callback |
| `onClusterTap` | `Function(MarkerCluster)` | Cluster tap callback |
| `onMapTap` | `Function(Coordinates)` | Map tap callback |

### QorviaMapController

Map control interface.

```dart
// Camera control
await controller.animateCamera(
  CameraUpdate.newPosition(CameraPosition(
    center: Coordinates(lat: 55.75, lon: 37.62),
    zoom: 15,
    tilt: 45,
    bearing: 90,
  )),
  duration: Duration(milliseconds: 800),
);

// Fit bounds
await controller.animateCamera(
  CameraUpdate.newLatLngBounds(coordinates, padding: 50),
);

// Markers
await controller.addMarker(marker);
await controller.removeMarker('marker_id');
await controller.clearMarkers();
await controller.updateMarkerPosition('id', newCoordinates);

// Routes
await controller.displayRoute(route, options: RouteLineOptions.primary());
await controller.displayRouteLine(routeLine);
await controller.fitRoute(route, padding: EdgeInsets.all(50));
await controller.clearRoutes();

// Zoom
await controller.zoomIn();
await controller.zoomOut();
```

### NavigationView

Turn-by-turn navigation widget.

| Parameter | Type | Description |
|-----------|------|-------------|
| `route` | `RouteResponse` | Route to navigate |
| `options` | `NavigationOptions` | Navigation config |
| `styleUrl` | `String?` | Map style URL |
| `onStateChanged` | `Function(NavigationState)` | State updates |
| `onStepChanged` | `Function(RouteStep)` | Step change callback |
| `onArrival` | `VoidCallback` | Arrival callback |
| `onOffRoute` | `VoidCallback` | Off-route callback |
| `onReroute` | `Function(Coordinates, Coordinates)` | Reroute builder |

### NavigationOptions

| Option | Default | Description |
|--------|---------|-------------|
| `trackingMode` | `followWithBearing` | Camera tracking mode |
| `zoom` | `17` | Navigation zoom level |
| `tilt` | `55` | Camera tilt angle |
| `enableVoiceInstructions` | `false` | Enable TTS guidance |
| `offRouteThreshold` | `30` | Meters to trigger off-route |
| `arrivalThreshold` | `35` | Meters to trigger arrival |
| `autoReroute` | `true` | Auto request reroute |
| `showNextTurnPanel` | `true` | Show turn instruction |
| `showEtaPanel` | `true` | Show ETA/distance |
| `showSpeedIndicator` | `true` | Show current speed |
| `snapToRouteEnabled` | `true` | Snap cursor to route |
| `cursorColor` | `null` | Navigation arrow fill color |
| `cursorBorderColor` | `null` | Navigation arrow border color |

### NavigationController

Programmatic navigation control.

```dart
final controller = NavigationController(
  options: NavigationOptions.driving(),
  onStateChanged: (state) => print(state),
  onArrival: () => print('Arrived!'),
);

// Start navigation
await controller.startNavigation(route);

// Update route (reroute)
await controller.updateRoute(newRoute);

// Camera control
controller.setTrackingMode(CameraTrackingMode.follow);
controller.pauseTracking();  // User panned
controller.recenter();       // Return to tracking

// Stop
controller.stopNavigation();

// Cleanup
controller.dispose();
```

### LocationService

Device location management.

```dart
final locationService = LocationService();

// Check permissions
final enabled = await locationService.isLocationServiceEnabled();
final permission = await locationService.checkPermission();

if (permission == LocationPermissionStatus.denied) {
  await locationService.requestPermission();
}

// Get current location
final location = await locationService.getCurrentLocation(
  accuracy: LocationAccuracy.high,
);

// Start tracking with filtering
await locationService.startTracking(
  LocationSettings.navigation(),
  LocationFilterSettings.navigation(),
);

locationService.locationStream.listen((location) {
  print('${location.coordinates}, speed: ${location.speed}');
});

// Health check
final health = locationService.checkHealth();
print('Healthy: ${health.isHealthy}');

// Stop tracking
locationService.stopTracking();
locationService.dispose();
```

### Marker Icons

```dart
// Default presets
DefaultMarkerIcon.primary    // Indigo
DefaultMarkerIcon.red        // Red
DefaultMarkerIcon.green      // Green
DefaultMarkerIcon.start      // Green with flag
DefaultMarkerIcon.end        // Red with pin

// Custom default
DefaultMarkerIcon(
  color: MarkerColors.purple,
  size: 56,
  style: MarkerStyle.modern,
  innerIcon: Icons.star,
)

// Numbered
NumberedMarkerIcon(number: 1)
NumberedMarkerIcon.letter('A')
NumberedMarkerIcon.sequence(5)  // [1, 2, 3, 4, 5]
NumberedMarkerIcon.letters(3)   // [A, B, C]

// Animated
AnimatedMarkerIcon.pulsingPrimary
AnimatedMarkerIcon.dropInStart
AnimatedMarkerIcon.rippleLocation
AnimatedMarkerIcon(
  color: MarkerColors.info,
  animationType: MarkerAnimationType.pulse,
)

// Asset-based
AssetMarkerIcon('assets/pin.png', width: 32, height: 32)
SvgMarkerIcon('assets/icon.svg', size: 24, color: Colors.blue)
NetworkMarkerIcon('https://example.com/icon.png')

// Widget
WidgetMarkerIcon(
  MyCustomWidget(),
  width: 48,
  height: 48,
)

// Cached (for many identical markers)
CachedMarkerIcon.primary()
```

### Transport Modes

```dart
TransportMode.car    // Car/automobile
TransportMode.bike   // Bicycle
TransportMode.foot   // Walking
TransportMode.truck  // Truck with restrictions
```

### Map Styles

```dart
MapStyles.osm                 // OpenStreetMap
MapStyles.openFreeMapLiberty  // OpenFreeMap Liberty (no key)
MapStyles.cartoPositron       // CARTO Positron (no key)
MapStyles.custom('https://tiles.example.com')
```

## Architecture

```
qorvia_maps_sdk/
├── lib/
│   ├── qorvia_maps_sdk.dart          # Public exports
│   └── src/
│       ├── sdk_initializer.dart      # QorviaMapsSDK singleton
│       ├── client/                   # API client
│       │   ├── qorvia_maps_client.dart
│       │   └── http_client.dart
│       ├── config/                   # Configuration
│       │   ├── sdk_config.dart
│       │   └── transport_mode.dart
│       ├── map/                      # Map widgets
│       │   ├── qorvia_map_view.dart
│       │   ├── qorvia_map_controller.dart
│       │   ├── map_options.dart
│       │   └── camera/
│       ├── markers/                  # Marker system
│       │   ├── marker.dart
│       │   ├── marker_icon.dart
│       │   ├── marker_widget.dart
│       │   └── cluster/
│       ├── navigation/               # Navigation
│       │   ├── navigation_view.dart
│       │   ├── navigation_controller.dart
│       │   ├── navigation_options.dart
│       │   ├── navigation_state.dart
│       │   ├── ui/                   # UI components
│       │   └── voice/                # TTS guidance
│       ├── location/                 # Location services
│       │   ├── location_service.dart
│       │   ├── location_data.dart
│       │   ├── location_filter.dart
│       │   └── location_settings.dart
│       ├── models/                   # Data models
│       │   ├── coordinates.dart
│       │   ├── route/
│       │   ├── geocode/
│       │   └── reverse/
│       ├── services/                 # API services
│       │   ├── routing_service.dart
│       │   ├── geocoding_service.dart
│       │   └── reverse_service.dart
│       ├── route_display/            # Route rendering
│       └── utils/                    # Utilities
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `maplibre_gl` | Map rendering |
| `dio` | HTTP client |
| `geolocator` | GPS location |
| `permission_handler` | Permission management |
| `flutter_compass` | Compass heading |
| `flutter_tts` | Voice guidance |
| `flutter_svg` | SVG marker icons |
| `equatable` | Value equality |
| `freezed_annotation` | Immutable models |

## Example App

See the `example/` directory for a complete demo application.

```bash
cd example
flutter run
```

## License

MIT License. See [LICENSE](LICENSE) for details.
