import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../constants.dart';
import '../../data/services/api_service.dart';

class DataRefreshService extends ChangeNotifier {
  static final DataRefreshService _instance = DataRefreshService._internal();
  factory DataRefreshService() => _instance;
  DataRefreshService._internal();

  final ApiService _apiService = ApiService();

  Timer? _refreshTimer;
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

  // Refresh intervals (in seconds)
  static const int _patientsRefreshInterval = 30;
  static const int _notificationsRefreshInterval = 15;
  static const int _requestsRefreshInterval = 20;
  static const int _profileRefreshInterval = 60;

  // Callbacks for different data types
  final Map<String, VoidCallback> _refreshCallbacks = {};

  // Data freshness tracking
  final Map<String, DateTime> _lastDataUpdate = {};

  /// Initialize the refresh service
  void initialize() {
    if (ApiConstants.debugMode) {
      print('🔄 Initializing DataRefreshService');
    }

    // Start periodic refresh
    _startPeriodicRefresh();

    // Listen for app lifecycle changes
    _setupAppLifecycleListener();
  }

  /// Start periodic refresh timer
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(
      Duration(seconds: _notificationsRefreshInterval),
      (_) => _performPeriodicRefresh(),
    );

    if (ApiConstants.debugMode) {
      print(
        '🔄 Started periodic refresh every $_notificationsRefreshInterval seconds',
      );
    }
  }

  /// Setup app lifecycle listener for background/foreground transitions
  void _setupAppLifecycleListener() {
    SystemChannels.lifecycle.setMessageHandler((String? message) async {
      if (message == AppLifecycleState.resumed.toString()) {
        if (ApiConstants.debugMode) {
          print('🔄 App resumed - refreshing data');
        }
        await refreshAllData();
      }
      return null;
    });
  }

  /// Perform periodic refresh based on data freshness
  Future<void> _performPeriodicRefresh() async {
    if (_isRefreshing) return;

    final now = DateTime.now();

    // Check what needs refreshing based on time intervals
    if (_shouldRefresh('notifications', now, _notificationsRefreshInterval)) {
      await _triggerRefresh('notifications');
    }

    if (_shouldRefresh('requests', now, _requestsRefreshInterval)) {
      await _triggerRefresh('requests');
    }

    if (_shouldRefresh('patients', now, _patientsRefreshInterval)) {
      await _triggerRefresh('patients');
    }

    if (_shouldRefresh('profile', now, _profileRefreshInterval)) {
      await _triggerRefresh('profile');
    }
  }

  /// Check if data should be refreshed based on time interval
  bool _shouldRefresh(String dataType, DateTime now, int intervalSeconds) {
    final lastUpdate = _lastDataUpdate[dataType];
    if (lastUpdate == null) return true;

    final timeSinceLastUpdate = now.difference(lastUpdate).inSeconds;
    return timeSinceLastUpdate >= intervalSeconds;
  }

  /// Trigger refresh for specific data type
  Future<void> _triggerRefresh(String dataType) async {
    final callback = _refreshCallbacks[dataType];
    if (callback == null) return;

    try {
      if (ApiConstants.debugMode) {
        print('🔄 Starting refresh for $dataType');
      }

      // Execute callback in a try-catch block
      callback();
      _lastDataUpdate[dataType] = DateTime.now();

      if (ApiConstants.debugMode) {
        print('✅ Refreshed $dataType data');
      }
    } catch (e) {
      if (ApiConstants.debugMode) {
        print('❌ Error refreshing $dataType: $e');
      }
      // Don't rethrow - we want to continue with other refreshes
    }
  }

  /// Register a refresh callback for a specific data type
  void registerRefreshCallback(String dataType, VoidCallback callback) {
    if (_refreshCallbacks.containsKey(dataType)) {
      if (ApiConstants.debugMode) {
        print('🔄 Replacing existing callback for $dataType');
      }
    }
    _refreshCallbacks[dataType] = callback;

    if (ApiConstants.debugMode) {
      print('🔄 Registered refresh callback for $dataType');
    }
  }

  /// Unregister a refresh callback
  void unregisterRefreshCallback(String dataType) {
    if (_refreshCallbacks.remove(dataType) != null) {
      if (ApiConstants.debugMode) {
        print('🔄 Unregistered refresh callback for $dataType');
      }
    }
  }

  /// Manual refresh of all data
  Future<void> refreshAllData() async {
    if (_isRefreshing) {
      if (ApiConstants.debugMode) {
        print('🔄 Refresh already in progress, skipping');
      }
      return;
    }

    _isRefreshing = true;
    _lastRefreshTime = DateTime.now();

    if (ApiConstants.debugMode) {
      print('🔄 Starting manual refresh of all data');
    }

    try {
      // Create a copy of the callbacks to avoid concurrent modification
      final callbacks = Map<String, VoidCallback>.from(_refreshCallbacks);

      // Trigger all registered callbacks
      for (final entry in callbacks.entries) {
        if (!_refreshCallbacks.containsKey(entry.key)) {
          // Skip if callback was unregistered during iteration
          continue;
        }
        await _triggerRefresh(entry.key);
      }

      if (ApiConstants.debugMode) {
        print('✅ Manual refresh completed');
      }
    } catch (e) {
      if (ApiConstants.debugMode) {
        print('❌ Error during manual refresh: $e');
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Manual refresh of specific data type
  Future<void> refreshData(String dataType) async {
    if (_isRefreshing) {
      if (ApiConstants.debugMode) {
        print('🔄 Refresh already in progress, skipping $dataType');
      }
      return;
    }

    try {
      await _triggerRefresh(dataType);
      notifyListeners();
    } catch (e) {
      if (ApiConstants.debugMode) {
        print('❌ Error refreshing $dataType: $e');
      }
    }
  }

  /// Force immediate refresh (bypasses time checks)
  Future<void> forceRefresh(String dataType) async {
    final callback = _refreshCallbacks[dataType];
    if (callback == null) return;

    try {
      if (ApiConstants.debugMode) {
        print('🔄 Force refreshing $dataType');
      }

      callback();
      _lastDataUpdate[dataType] = DateTime.now();

      if (ApiConstants.debugMode) {
        print('✅ Force refreshed $dataType data');
      }
    } catch (e) {
      if (ApiConstants.debugMode) {
        print('❌ Error force refreshing $dataType: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  /// Get last refresh time
  DateTime? get lastRefreshTime => _lastRefreshTime;

  /// Get last update time for specific data type
  DateTime? getLastUpdateTime(String dataType) {
    return _lastDataUpdate[dataType];
  }

  /// Check if data is fresh (updated within specified interval)
  bool isDataFresh(String dataType, int intervalSeconds) {
    final lastUpdate = _lastDataUpdate[dataType];
    if (lastUpdate == null) return false;

    final timeSinceLastUpdate = DateTime.now().difference(lastUpdate).inSeconds;
    return timeSinceLastUpdate < intervalSeconds;
  }

  /// Get refresh status
  bool get isRefreshing => _isRefreshing;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshCallbacks.clear();
    _lastDataUpdate.clear();

    if (ApiConstants.debugMode) {
      print('🔄 DataRefreshService disposed');
    }

    super.dispose();
  }
}
