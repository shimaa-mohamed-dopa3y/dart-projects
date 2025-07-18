import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/refreshable_widget.dart';
import '../../data/models/patient_model.dart';
import '../onboarding/onboarding_screen.dart';
import 'patient_details_screen.dart';
import 'specialist_settings_screen.dart';
import 'assign_patients_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notification_center_screen.dart';
import 'my_patients_screen.dart';
import 'assignment_requests_screen.dart';

class SpecialistDashboardScreen extends ConsumerStatefulWidget {
  const SpecialistDashboardScreen({super.key});

  @override
  ConsumerState<SpecialistDashboardScreen> createState() =>
      _SpecialistDashboardScreenState();
}

class _SpecialistDashboardScreenState
    extends ConsumerState<SpecialistDashboardScreen>
    with RefreshableWidget {
  @override
  String get refreshDataType => 'dashboard';

  @override
  int get refreshInterval => 30;

  void _invalidateProviders() {
    ref.invalidate(patientsProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(doctorAssignmentRequestsProvider);
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Logout',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: AppColors.subtitle,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtitle,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  navigator.pop();

                  final authNotifier = ref.read(authProvider.notifier);
                  await authNotifier.logout();

                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildStatisticsSection(List<PatientModel> patients) {
    final needsAttention = patients.where((p) => p.id.hashCode % 3 == 2).length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Iconsax.people,
                      color: AppColors.info,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '${patients.length}',
                    style: GoogleFonts.inter(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Total Patients',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppColors.subtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Iconsax.warning_2,
                      color: AppColors.warning,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '$needsAttention',
                    style: GoogleFonts.inter(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Needs Attention',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppColors.subtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    final status = patient.patientStatus ?? 'Stable';
    final photosCount =
        patient.totalRecords; // Assuming each record has a photo
    final progressValue = (patient.totalRecords / 10.0).clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.subtitle.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    patient.name.isNotEmpty
                        ? patient.name.substring(0, 2).toUpperCase()
                        : 'P',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          patient.name,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        Container(
                          constraints: BoxConstraints(
                            minWidth: 60.w,
                            maxWidth: 100.w,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            _getStatusDisplayText(status),
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Last visit: ${patient.lastActivity.toString().substring(0, 10)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Iconsax.people, size: 16.sp, color: AppColors.subtitle),
              SizedBox(width: 4.w),
              Text(
                '${patient.totalRecords} Records',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.subtitle,
                ),
              ),
              SizedBox(width: 16.w),
              Icon(Iconsax.gallery, size: 16.sp, color: AppColors.subtitle),
              SizedBox(width: 4.w),
              Text(
                '$photosCount Photos',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.subtitle,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: AppColors.subtitle.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(status),
              ),
              minHeight: 6.h,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'stable':
        return const Color(0xFF4CAF50);
      case 'improving':
        return const Color(0xFF2196F3);
      case 'needs attention':
        return const Color(0xFFFF9800);
      default:
        return AppColors.primary;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'needs attention':
        return 'ATTENTION';
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildLoadingStatistics() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 80.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Container(
              height: 80.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStatistics() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Iconsax.people,
                      color: AppColors.info,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '0',
                    style: GoogleFonts.inter(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Total Patients',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppColors.subtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Iconsax.warning_2,
                      color: AppColors.warning,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '0',
                    style: GoogleFonts.inter(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Needs Attention',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppColors.subtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final patientsAsync = ref.watch(patientsProvider);
    final requestsAsync = ref.watch(doctorAssignmentRequestsProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Navigator.canPop(context)
                        ? IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.text,
                            size: 20.sp,
                          ),
                          padding: EdgeInsets.zero,
                        )
                        : IconButton(
                          onPressed: () => _handleLogout(),
                          icon: Icon(
                            Iconsax.logout,
                            color: AppColors.text,
                            size: 20.sp,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Specialist Dashboard',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Notifications button
                        Stack(
                          children: [
                            IconButton(
                              icon: Icon(Icons.notifications, size: 20.sp),
                              tooltip: 'Notifications',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const NotificationCenterScreen(),
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                minWidth: 32.w,
                                minHeight: 32.h,
                              ),
                            ),
                            // Show general notifications badge
                            Consumer(
                              builder: (context, ref, child) {
                                final notificationsAsync = ref.watch(
                                  notificationsProvider,
                                );
                                return notificationsAsync.when(
                                  data: (notifications) {
                                    final unreadCount =
                                        notifications
                                            .where((n) => n['read'] != true)
                                            .length;
                                    if (unreadCount > 0) {
                                      return Positioned(
                                        right: 2,
                                        top: 2,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 2.w,
                                            vertical: 1.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            borderRadius: BorderRadius.circular(
                                              4.r,
                                            ),
                                          ),
                                          child: Text(
                                            '$unreadCount',
                                            style: GoogleFonts.inter(
                                              fontSize: 6.sp,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                );
                              },
                            ),
                          ],
                        ),
                        // Settings button
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const SpecialistSettingsScreen(),
                              ),
                            );
                          },
                          icon: Icon(
                            Iconsax.setting_2,
                            color: AppColors.text,
                            size: 20.sp,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 32.w,
                            minHeight: 32.h,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Quick Actions Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // My Patients Action
                    _buildQuickAction(
                      icon: Icons.people,
                      label: 'My Patients',
                      badge:
                          patientsAsync.hasValue
                              ? patientsAsync.value?.length.toString()
                              : null,
                      badgeColor: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyPatientsScreen(),
                          ),
                        );
                      },
                    ),
                    // Assignment Requests Action
                    _buildQuickAction(
                      icon: Iconsax.notification,
                      label: 'Requests',
                      badge:
                          requestsAsync.hasValue
                              ? requestsAsync.value?.length.toString()
                              : null,
                      badgeColor: AppColors.warning,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AssignmentRequestsScreen(),
                          ),
                        );
                      },
                    ),
                    // Refresh Action
                    _buildQuickAction(
                      icon: Icons.refresh,
                      label: 'Refresh',
                      onTap: () => ref.invalidate(patientsProvider),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Welcome back,',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      color: AppColors.subtitle,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    user?.name ?? 'Doctor',
                    style: GoogleFonts.inter(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Real Statistics Section
              patientsAsync.when(
                data: (patients) {
                  final totalPatients = patients.length;
                  final needsAttention =
                      patients
                          .where((p) => p.patientStatus == 'needs attention')
                          .length;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 40.w,
                                  height: 40.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Iconsax.people,
                                    color: AppColors.info,
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  '$totalPatients',
                                  style: GoogleFonts.inter(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Total Patients',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: AppColors.subtitle,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 40.w,
                                  height: 40.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Iconsax.warning_2,
                                    color: AppColors.warning,
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  '$needsAttention',
                                  style: GoogleFonts.inter(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Needs Attention',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: AppColors.subtitle,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading:
                    () => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 40.w,
                                    height: 40.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      Iconsax.people,
                                      color: AppColors.info,
                                      size: 20.sp,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    '...',
                                    style: GoogleFonts.inter(
                                      fontSize: 28.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Loading...',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: AppColors.subtitle,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 40.w,
                                    height: 40.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      Iconsax.warning_2,
                                      color: AppColors.warning,
                                      size: 20.sp,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    '...',
                                    style: GoogleFonts.inter(
                                      fontSize: 28.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Loading...',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: AppColors.subtitle,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                error:
                    (error, stack) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Failed to load statistics',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ),

              SizedBox(height: 24.h),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: buildRefreshableWidget(
                    child: patientsAsync.when(
                      data: (patients) {
                        if (patients.isEmpty) {
                          return Center(
                            child: Text(
                              'No patients found',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: patients.length,
                          itemBuilder: (context, index) {
                            final patient = patients[index];
                            return GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => PatientDetailsScreen(
                                          patient: patient,
                                        ),
                                  ),
                                );

                                // If a result is returned (patient was updated), refresh the list
                                if (result != null) {
                                  ref.invalidate(patientsProvider);
                                }
                              },
                              child: _buildPatientCard(patient),
                            );
                          },
                        );
                      },
                      loading:
                          () => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                      error:
                          (error, stack) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64.sp,
                                  color: Colors.white54,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'Unable to load patients',
                                  style: GoogleFonts.inter(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Please check your connection and try again',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24.h),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.refresh(patientsProvider);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: Text(
                                    'Retry',
                                    style: GoogleFonts.inter(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.primary, size: 24.sp),
              ),
              if (badge != null)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor ?? AppColors.primary,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
