import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../core/providers/providers.dart';
import '../core/theme.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

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
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      'Notification Settings',
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Flexible(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: settingsAsync.when(
                    data: (settings) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notification Preferences',
                              style: GoogleFonts.inter(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Choose which notifications you want to receive',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: AppColors.subtitle,
                              ),
                            ),
                            SizedBox(height: 24.h),
                            _buildSettingTile(
                              ref: ref,
                              icon: Iconsax.user_add,
                              title: 'Assignment Notifications',
                              subtitle:
                                  'Get notified about patient assignments',
                              settingKey: 'assignmentNotifications',
                              currentValue:
                                  settings['assignmentNotifications'] ?? true,
                            ),
                            _buildSettingTile(
                              ref: ref,
                              icon: Iconsax.chart,
                              title: 'Analysis Notifications',
                              subtitle:
                                  'Receive updates about medical analysis',
                              settingKey: 'analysisNotifications',
                              currentValue:
                                  settings['analysisNotifications'] ?? true,
                            ),
                            _buildSettingTile(
                              ref: ref,
                              icon: Iconsax.notification,
                              title: 'General Notifications',
                              subtitle: 'Get general app updates',
                              settingKey: 'generalNotifications',
                              currentValue:
                                  settings['generalNotifications'] ?? true,
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              'Notification Behavior',
                              style: GoogleFonts.inter(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildSettingTile(
                              ref: ref,
                              icon: Iconsax.volume_high,
                              title: 'Sound',
                              subtitle: 'Play sound for notifications',
                              settingKey: 'soundEnabled',
                              currentValue: settings['soundEnabled'] ?? true,
                            ),
                            _buildSettingTile(
                              ref: ref,
                              icon: Icons.vibration,
                              title: 'Vibration',
                              subtitle: 'Vibrate for notifications',
                              settingKey: 'vibrationEnabled',
                              currentValue:
                                  settings['vibrationEnabled'] ?? true,
                            ),
                          ],
                        ),
                      );
                    },
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, stack) => Center(
                          child: Text(
                            'Error: $error',
                            style: const TextStyle(color: AppColors.error),
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

  Widget _buildSettingTile({
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required String subtitle,
    required String settingKey,
    required bool currentValue,
  }) {
    // Read the provider once to get the notifier
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Switch(
            value: currentValue,
            onChanged:
                (newValue) => notifier.updateSetting(settingKey, newValue),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
