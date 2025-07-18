import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/api_service.dart';
import '../providers/providers.dart';
import 'notification_service.dart';

final notificationPollingProvider = Provider<NotificationPollingService>((ref) {
  return NotificationPollingService(ref);
});

class NotificationPollingService {
  NotificationPollingService(this._ref);

  final Ref _ref;
  Timer? _pollingTimer;
  final Set<String> _processedNotificationIds = {};

  void startPolling() {
    // Stop any existing timer
    _pollingTimer?.cancel();

    // Poll every 15 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkForNewNotifications();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> _checkForNewNotifications() async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      final notifications = await apiService.getNotifications();

      for (var notification in notifications) {
        final id = notification['_id'];
        if (id != null && !_processedNotificationIds.contains(id)) {
          // New notification found
          final notificationService = _ref.read(notificationServiceProvider);
          notificationService.showNotification(
            id: id.hashCode,
            title: notification['title'] ?? 'New Notification',
            body: notification['message'] ?? '',
            payload: id,
          );
          _processedNotificationIds.add(id);
        }
      }
    } catch (e) {
      print('Error polling for notifications: $e');
    }
  }
}
 