import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../services/data_refresh_service.dart';

mixin RefreshableWidget<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Override this to specify which data type this widget refreshes
  String get refreshDataType;

  /// Override this to specify the refresh interval in seconds
  int get refreshInterval => 30;

  /// Override this to provide custom refresh logic
  Future<void>? customRefreshLogic() => null;

  late final DataRefreshService _refreshService;

  @override
  void initState() {
    super.initState();
    _refreshService = DataRefreshService();
    _registerRefreshCallback();
  }

  @override
  void dispose() {
    _unregisterRefreshCallback();
    super.dispose();
  }

  void _registerRefreshCallback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshService.registerRefreshCallback(refreshDataType, () {
        _performRefresh();
      });
    });
  }

  void _unregisterRefreshCallback() {
    _refreshService.unregisterRefreshCallback(refreshDataType);
  }

  Future<void> _performRefresh() async {
    if (customRefreshLogic() != null) {
      await customRefreshLogic()!;
    } else {
      // Default refresh logic - invalidate relevant providers
      _invalidateProviders();
    }
  }

  /// Override this to specify which providers to invalidate on refresh
  void _invalidateProviders() {
    // Default implementation - override in subclasses
  }

  /// Force refresh the data
  Future<void> forceRefresh() async {
    await _refreshService.forceRefresh(refreshDataType);
  }

  /// Check if data is fresh
  bool isDataFresh() {
    return _refreshService.isDataFresh(refreshDataType, refreshInterval);
  }

  /// Get last update time
  DateTime? getLastUpdateTime() {
    return _refreshService.getLastUpdateTime(refreshDataType);
  }

  /// Create a RefreshIndicator widget with the refresh logic
  Widget buildRefreshableWidget({
    required Widget child,
    Color? color,
    Color? backgroundColor,
    double? strokeWidth,
    String? semanticsLabel,
    String? semanticsValue,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        await forceRefresh();
      },
      color: color ?? Theme.of(context).primaryColor,
      backgroundColor: backgroundColor,
      strokeWidth: strokeWidth ?? 2.0,
      semanticsLabel: semanticsLabel ?? 'Refresh',
      semanticsValue: semanticsValue,
      child: child,
    );
  }

  /// Create a refresh button widget
  Widget buildRefreshButton({
    VoidCallback? onPressed,
    IconData icon = Icons.refresh,
    String? tooltip,
    Color? color,
    double? size,
  }) {
    return IconButton(
      onPressed: onPressed ?? () => forceRefresh(),
      icon: Icon(icon, color: color, size: size),
      tooltip: tooltip ?? 'Refresh',
    );
  }

  /// Create a refresh status indicator
  Widget buildRefreshStatusIndicator() {
    if (_refreshService.isRefreshing) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final lastUpdate = getLastUpdateTime();
    if (lastUpdate != null) {
      final timeAgo = DateTime.now().difference(lastUpdate);
      final minutes = timeAgo.inMinutes;

      if (minutes < 1) {
        return const Icon(Icons.check_circle, color: Colors.green, size: 16);
      } else if (minutes < 5) {
        return const Icon(Icons.info, color: Colors.orange, size: 16);
      } else {
        return const Icon(Icons.warning, color: Colors.red, size: 16);
      }
    }

    return const Icon(Icons.help, color: Colors.grey, size: 16);
  }
}
