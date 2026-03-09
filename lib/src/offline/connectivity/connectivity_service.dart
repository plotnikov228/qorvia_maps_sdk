import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../navigation/navigation_logger.dart';
import 'network_status.dart';

const _logTag = 'ConnectivityService';

/// Service for monitoring network connectivity status.
///
/// Provides real-time updates when network status changes and allows
/// checking connectivity on demand.
///
/// ## Usage
///
/// ```dart
/// // Initialize the service
/// await ConnectivityService.instance.initialize();
///
/// // Check current status
/// if (ConnectivityService.instance.currentStatus.isConnected) {
///   // Make network request
/// }
///
/// // Listen to status changes
/// ConnectivityService.instance.statusStream.listen((status) {
///   if (status.isOffline) {
///     // Switch to offline mode
///   }
/// });
///
/// // Dispose when done
/// ConnectivityService.instance.dispose();
/// ```
class ConnectivityService {
  ConnectivityService._();

  static ConnectivityService? _instance;

  /// Singleton instance of the connectivity service.
  static ConnectivityService get instance {
    _instance ??= ConnectivityService._();
    return _instance!;
  }

  /// Reset singleton instance (for testing).
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _currentStatus = NetworkStatus.unknown;
  bool _isInitialized = false;

  /// Stream of network status changes.
  ///
  /// Emits a new value whenever the network status changes.
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Current network status.
  ///
  /// Returns [NetworkStatus.unknown] if the service hasn't been initialized
  /// or the status couldn't be determined.
  NetworkStatus get currentStatus => _currentStatus;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initialize the connectivity service.
  ///
  /// This method should be called once during app initialization.
  /// It starts listening to connectivity changes and performs an initial check.
  Future<void> initialize() async {
    if (_isInitialized) {
      NavigationLogger.debug(_logTag, 'Already initialized, skipping');
      return;
    }

    NavigationLogger.info(_logTag, 'Initializing connectivity service');

    // Subscribe to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        NavigationLogger.error(
          _logTag,
          'Error listening to connectivity changes',
          error,
        );
      },
    );

    // Perform initial connectivity check
    await checkConnectivity();

    _isInitialized = true;
    NavigationLogger.info(_logTag, 'Initialized', {
      'initialStatus': _currentStatus.name,
    });
  }

  /// Check current connectivity status.
  ///
  /// Returns `true` if the device has internet connectivity.
  /// Updates [currentStatus] and emits to [statusStream] if status changed.
  Future<bool> checkConnectivity() async {
    NavigationLogger.debug(_logTag, 'Checking connectivity');

    try {
      final results = await _connectivity.checkConnectivity();
      final newStatus = _mapConnectivityResults(results);

      NavigationLogger.debug(_logTag, 'Connectivity check result', {
        'results': results.map((r) => r.name).toList(),
        'status': newStatus.name,
      });

      _updateStatus(newStatus);
      return newStatus.isConnected;
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'Failed to check connectivity', e, stack);
      _updateStatus(NetworkStatus.unknown);
      return false;
    }
  }

  /// Called when connectivity changes.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final newStatus = _mapConnectivityResults(results);

    NavigationLogger.debug(_logTag, 'Connectivity changed', {
      'results': results.map((r) => r.name).toList(),
      'newStatus': newStatus.name,
    });

    _updateStatus(newStatus);
  }

  /// Update current status and emit to stream if changed.
  void _updateStatus(NetworkStatus newStatus) {
    if (_currentStatus != newStatus) {
      final oldStatus = _currentStatus;
      _currentStatus = newStatus;

      NavigationLogger.info(_logTag, 'Network status changed', {
        'from': oldStatus.name,
        'to': newStatus.name,
      });

      if (!_statusController.isClosed) {
        _statusController.add(newStatus);
      }
    }
  }

  /// Map connectivity results to network status.
  NetworkStatus _mapConnectivityResults(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return NetworkStatus.offline;
    }

    // Check if we have any real connectivity
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.mobile:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.vpn:
          return NetworkStatus.online;
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.other:
          // These might provide connectivity, treat as online
          return NetworkStatus.online;
        case ConnectivityResult.none:
          // Continue checking other results
          continue;
      }
    }

    // All results were 'none'
    return NetworkStatus.offline;
  }

  /// Dispose the service and release resources.
  ///
  /// Call this when the service is no longer needed.
  void dispose() {
    NavigationLogger.debug(_logTag, 'Disposing connectivity service');
    _subscription?.cancel();
    _subscription = null;
    _statusController.close();
    _isInitialized = false;
    _currentStatus = NetworkStatus.unknown;
  }
}
