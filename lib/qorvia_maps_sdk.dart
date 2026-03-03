/// Base Maps SDK for Flutter.
///
/// A comprehensive SDK for geo services including navigation, routing,
/// geocoding, and interactive maps powered by MapLibre GL.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Initialize SDK globally (recommended)
///   await QorviaMapsSDK.init(apiKey: 'your_api_key');
///
///   runApp(MyApp());
/// }
///
/// // Map widget - styleUrl is loaded automatically from SDK
/// QorviaMapView(
///   options: MapOptions(
///     initialCenter: Coordinates(lat: 55.7539, lon: 37.6208),
///   ),
/// );
///
/// // Or use the client directly for API calls
/// final route = await QorviaMapsSDK.instance.client.route(
///   from: Coordinates(lat: 55.7539, lon: 37.6208),
///   to: Coordinates(lat: 55.7614, lon: 37.6500),
/// );
/// ```
library;

// SDK Initializer
export 'src/sdk_initializer.dart';

// Client
export 'src/client/qorvia_maps_client.dart';

// Config
export 'src/config/sdk_config.dart';
export 'src/config/transport_mode.dart';

// Models
export 'src/models/models.dart';

// Exceptions
export 'src/exceptions/qorvia_maps_exception.dart';

// Map
export 'src/map/qorvia_map_view.dart';
export 'src/map/qorvia_map_controller.dart';
export 'src/map/map_options.dart';
export 'src/map/camera/camera_position.dart';
export 'src/map/user_location_style.dart';
export 'src/map/user_location_layer.dart';

// Markers
export 'src/markers/marker.dart';
export 'src/markers/marker_icon.dart';
export 'src/markers/marker_widget.dart';
export 'src/markers/cluster/marker_cluster.dart';

// Route Display
export 'src/route_display/route_line.dart';

// Utils
export 'src/utils/polyline_decoder.dart';
export 'src/utils/sdk_logger.dart';

// Location
export 'src/location/location_data.dart';
export 'src/location/location_settings.dart';
export 'src/location/location_service.dart';
export 'src/location/location_filter.dart';

// Navigation
export 'src/navigation/navigation_view.dart';
export 'src/navigation/navigation_controller.dart';
export 'src/navigation/navigation_options.dart';
export 'src/navigation/navigation_state.dart';
export 'src/navigation/navigation_logger.dart';
export 'src/navigation/voice/voice_guidance.dart';
// Navigation - Camera & Animation
export 'src/navigation/camera/camera_controller.dart';
export 'src/navigation/camera/position_animator.dart';
export 'src/navigation/camera/bearing_smoother.dart';
// Navigation - Tracking
export 'src/navigation/tracking/route_tracker.dart';
export 'src/navigation/tracking/motion_predictor.dart';
export 'src/navigation/tracking/position_smoother.dart';
// Navigation - Map Layers
export 'src/navigation/user_arrow/user_arrow_layer.dart';
export 'src/navigation/user_arrow/route_line_manager.dart';
// Navigation - UI Widgets
export 'src/navigation/ui/next_turn_panel.dart';
export 'src/navigation/ui/eta_panel.dart';
export 'src/navigation/ui/speed_indicator.dart';
export 'src/navigation/ui/recenter_button.dart';
export 'src/navigation/ui/maneuver_icons.dart';
export 'src/navigation/ui/user_arrow_widget.dart';
export 'src/navigation/ui/widget_data.dart';
export 'src/navigation/ui/widget_builders.dart';
export 'src/navigation/ui/lanes_indicator.dart';
export 'src/navigation/ui/traffic_signal_indicator.dart';

// Map UI Widgets
export 'src/map/ui/widget_builders.dart';
export 'src/map/ui/zoom_controls.dart';
export 'src/map/ui/map_compass.dart';
export 'src/map/ui/map_scale_bar.dart';
export 'src/map/ui/user_location_button.dart';

// Search
export 'src/search/search.dart';
