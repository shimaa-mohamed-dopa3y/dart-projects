import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../core/providers/providers.dart';
import '../core/services/audio_service.dart';
import '../core/theme.dart';
import 'notification_settings_screen.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  final _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioService.announceScreenChange('Notification Center');
    });
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final apiService = ref.read(apiServiceProvider);
    final notificationId = notification['_id']?.toString();

    if (notificationId == null) return;

    // Mark as read immediately for better UX
    try {
      await apiService.markNotificationAsRead(notificationId);
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }

    // Handle different notification types
    final type = notification['type']?.toString();
    final title = notification['title']?.toString() ?? '';
    final message = notification['message']?.toString() ?? '';

    switch (type) {
      case 'assignment':
        if (title.contains('Accepted') || title.contains('Patient Assigned')) {
          await _audioService.announceSuccess(
            'Assignment accepted successfully',
          );
          // Refresh user and doctor data for patients
          ref.invalidate(currentUserProvider);
          ref.invalidate(doctorsProvider);
        } else if (title.contains('New Assignment Request')) {
          await _audioService.announceSuccess(
            'You have a new assignment request',
          );
          // Refresh requests for doctors
          ref.invalidate(doctorAssignmentRequestsProvider);
        }
        break;
      case 'analysis':
        await _audioService.announceSuccess('Analysis notification: $message');
        break;
      case 'general':
        await _audioService.announceSuccess('General notification: $message');
        break;
      default:
        await _audioService.announceSuccess('Notification: $message');
    }

    // Refresh the notifications list
    ref.invalidate(notificationsProvider);
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Recently';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  IconData _getNotificationIcon(String? type, String? title) {
    if (type == 'assignment') {
      if (title?.contains('Accepted') == true ||
          title?.contains('Patient Assigned') == true) {
        return Iconsax.user_tick;
      } else if (title?.contains('New Assignment Request') == true) {
        return Iconsax.user_add;
      }
      return Iconsax.user;
    } else if (type == 'analysis') {
      return Iconsax.chart;
    } else if (type == 'general') {
      return Iconsax.notification;
    }
    return Iconsax.notification;
  }

  Color _getNotificationColor(String? type, String? title) {
    if (type == 'assignment') {
      if (title?.contains('Accepted') == true ||
          title?.contains('Patient Assigned') == true) {
        return AppColors.success;
      } else if (title?.contains('New Assignment Request') == true) {
        return AppColors.warning;
      }
      return AppColors.primary;
    } else if (type == 'analysis') {
      return AppColors.info;
    } else if (type == 'general') {
      return AppColors.subtitle;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Row(
                  children: [
                    Semantics(
                      label: 'Back button',
                      button: true,
                      child: IconButton(
                        onPressed: () {
                          _audioService.announceButtonPress('Back');
                          Navigator.of(context).pop();
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: GoogleFonts.inter(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Settings button
                    Semantics(
                      label: 'Notification settings',
                      button: true,
                      child: IconButton(
                        onPressed: () {
                          _audioService.announceButtonPress('Settings');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => const NotificationSettingsScreen(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.settings,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  child: notificationsAsync.when(
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return Semantics(
                          label: 'No notifications available',
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 64.sp,
                                  color: AppColors.subtitle,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No Notifications',
                                  style: GoogleFonts.inter(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.subtitle,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'You\'re all caught up!',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: AppColors.subtitle,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Sort notifications by creation date (newest first)
                      final sortedNotifications =
                          List<Map<String, dynamic>>.from(notifications);
                      sortedNotifications.sort((a, b) {
                        final aTime =
                            DateTime.tryParse(a['createdAt'] ?? '') ??
                            DateTime(1900);
                        final bTime =
                            DateTime.tryParse(b['createdAt'] ?? '') ??
                            DateTime(1900);
                        return bTime.compareTo(aTime);
                      });

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Recent Notifications',
                                style: GoogleFonts.inter(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  '${sortedNotifications.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Expanded(
                            child: Semantics(
                              label: 'Notifications list, pull down to refresh',
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  await _audioService.announceLoading(
                                    'Refreshing notifications',
                                  );
                                  ref.invalidate(notificationsProvider);
                                },
                                child: ListView.builder(
                                  itemCount: sortedNotifications.length,
                                  itemBuilder: (context, index) {
                                    final notification =
                                        sortedNotifications[index];
                                    return _buildNotificationTile(notification);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Semantics(
                                label: 'Error loading notifications',
                                child: Icon(
                                  Iconsax.warning_2,
                                  size: 64.sp,
                                  color: AppColors.error,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Error loading notifications',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  color: AppColors.error,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                error.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: AppColors.subtitle,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16.h),
                              Semantics(
                                label: 'Retry loading notifications',
                                button: true,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await _audioService.announceButtonPress(
                                      'Retry loading notifications',
                                    );
                                    ref.invalidate(notificationsProvider);
                                  },
                                  child: Text('Retry'),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    final type = notification['type']?.toString();
    final title = notification['title']?.toString() ?? '';
    final message = notification['message']?.toString() ?? '';
    final isRead = notification['read'] == true;
    final createdAt = notification['createdAt']?.toString();

    final icon = _getNotificationIcon(type, title);
    final color = _getNotificationColor(type, title);

    final semanticLabel =
        isRead
            ? '$title, $message, ${_formatTimestamp(createdAt)}, read'
            : '$title, $message, ${_formatTimestamp(createdAt)}, unread';

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Card(
        margin: EdgeInsets.only(bottom: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color:
                isRead
                    ? Colors.transparent
                    : AppColors.primary.withOpacity(0.3),
            width: isRead ? 0 : 1,
          ),
        ),
        color: isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
        elevation: isRead ? 1 : 2,
        child: ListTile(
          contentPadding: EdgeInsets.all(16.w),
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          title: Text(
            title.isNotEmpty ? title : 'Notification',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
              SizedBox(height: 8.h),
              Text(
                _formatTimestamp(createdAt),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.subtitle.withOpacity(0.7),
                ),
              ),
            ],
          ),
          trailing:
              isRead
                  ? null
                  : Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
          onTap: () async {
            await _audioService.announceButtonPress(
              'Open notification: $title',
            );
            _handleNotificationTap(notification);
          },
        ),
      ),
    );
  }
}
