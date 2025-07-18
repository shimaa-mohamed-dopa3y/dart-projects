import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_refresh_service.dart';

class DataRefreshNotifier extends StateNotifier<bool> {
  final DataRefreshService _refreshService;
  final Ref _ref;
  bool _disposed = false;

  DataRefreshNotifier(this._refreshService, this._ref) : super(false) {
    _setupRefreshCallbacks();
  }

  void _setupRefreshCallbacks() {
    // Register refresh callbacks for different data types
    _refreshService.registerRefreshCallback('notifications', () {
      if (!_disposed) {
        _refreshNotifications();
      }
    });

    _refreshService.registerRefreshCallback('requests', () {
      if (!_disposed) {
        _refreshRequests();
      }
    });

    _refreshService.registerRefreshCallback('patients', () {
      if (!_disposed) {
        _refreshPatients();
      }
    });

    _refreshService.registerRefreshCallback('profile', () {
      if (!_disposed) {
        _refreshProfile();
      }
    });
  }

  void startPolling() {
    if (_disposed) return;
    _refreshService.initialize();
  }

  void stopPolling() {
    if (_disposed) return;
    _refreshService.dispose();
  }

  Future<void> _refreshNotifications() async {
    if (_disposed) return;
    try {
      print('🔄 Starting refresh for notifications');
      // The service will handle the actual refresh
    } catch (e) {
      print('❌ Error refreshing notifications: $e');
    }
  }

  Future<void> _refreshRequests() async {
    if (_disposed) return;
    try {
      print('🔄 Starting refresh for requests');
      // The service will handle the actual refresh
    } catch (e) {
      print('❌ Error refreshing requests: $e');
    }
  }

  Future<void> _refreshPatients() async {
    if (_disposed) return;
    try {
      print('🔄 Starting refresh for patients');
      // The service will handle the actual refresh
    } catch (e) {
      print('❌ Error refreshing patients: $e');
    }
  }

  Future<void> _refreshProfile() async {
    if (_disposed) return;
    try {
      print('🔄 Starting refresh for profile');
      // The service will handle the actual refresh
      print('✅ Refreshed profile data');
    } catch (e) {
      print('Profile refresh error: $e');
    }
  }

  Future<void> refreshAllData() async {
    if (_disposed) return;
    try {
      state = true;
      await _refreshService.refreshAllData();
    } catch (e) {
      print('Error during data refresh: $e');
    } finally {
      if (!_disposed) {
        state = false;
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshService.unregisterRefreshCallback('notifications');
    _refreshService.unregisterRefreshCallback('requests');
    _refreshService.unregisterRefreshCallback('patients');
    _refreshService.unregisterRefreshCallback('profile');
    super.dispose();
  }
}

final dataRefreshProvider = StateNotifierProvider<DataRefreshNotifier, bool>((
  ref,
) {
  final refreshService = DataRefreshService();
  return DataRefreshNotifier(refreshService, ref);
});
