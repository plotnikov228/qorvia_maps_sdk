/// Represents the current network connectivity status.
enum NetworkStatus {
  /// Device has internet connectivity (WiFi, mobile data, or ethernet).
  online,

  /// Device has no network connectivity.
  offline,

  /// Network status could not be determined.
  unknown;

  /// Returns true if the device is connected to the internet.
  bool get isConnected => this == NetworkStatus.online;

  /// Returns true if the device is definitely offline.
  bool get isOffline => this == NetworkStatus.offline;

  /// Returns a human-readable description of the status.
  String get description {
    switch (this) {
      case NetworkStatus.online:
        return 'Connected to internet';
      case NetworkStatus.offline:
        return 'No internet connection';
      case NetworkStatus.unknown:
        return 'Connection status unknown';
    }
  }
}
