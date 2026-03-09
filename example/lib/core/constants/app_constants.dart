/// Application constants.
abstract final class AppConstants {
  // SharedPreferences keys
  static const String cachedLatKey = 'cached_user_lat';
  static const String cachedLonKey = 'cached_user_lon';

  // Default coordinates (Moscow center)
  static const double defaultLat = 55.7539;
  static const double defaultLon = 37.6208;

  // Map settings
  static const double defaultZoom = 13.0;
  static const double navigationZoom = 16.0;

  // Timing
  static const Duration searchDebounce = Duration(milliseconds: 450);
  static const Duration locationTimeout = Duration(seconds: 15);
  static const Duration animationDuration = Duration(milliseconds: 200);

  // UI - Bottom sheet snap points (legacy - fraction based)
  // @deprecated Use panelMinHeight, panelMaxHeightFraction instead
  static const double panelMinSize = 0.25;
  static const double panelMaxSize = 0.75;
  static const double panelInitialSize = 0.38;

  // UI - ExpandableBottomPanel (new - pixel/fraction hybrid)
  // Minimum height in pixels (collapsed state showing only "From" field + hint)
  static const double panelMinHeight = 160.0;

  // Maximum height as fraction of screen (expanded state)
  static const double panelMaxHeightFraction = 0.75;

  // Initial height as fraction of screen
  static const double panelInitialHeightFraction = 0.38;

  // Snap animation duration
  static const Duration panelSnapDuration = Duration(milliseconds: 300);
}
