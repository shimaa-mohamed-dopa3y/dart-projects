import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/refreshable_widget.dart';
import '../../data/models/patient_model.dart';
import '../../data/services/api_service.dart';
import 'patient_details_screen.dart';

class MyPatientsScreen extends ConsumerStatefulWidget {
  const MyPatientsScreen({super.key});

  @override
  ConsumerState<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends ConsumerState<MyPatientsScreen>
    with RefreshableWidget {
  final _apiService = ApiService();
  bool _isSaving = false;

  @override
  String get refreshDataType => 'patients';

  @override
  int get refreshInterval => 30;

  @override
  void _invalidateProviders() {
    ref.invalidate(patientsProvider);
    ref.invalidate(assignedPatientsProvider);
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _updatePatientStatus(
    String patientId,
    String currentStatus,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Toggle between active and inactive assignment status
    final newStatus =
        currentStatus.toLowerCase() == 'active' ? 'inactive' : 'active';

    try {
      await ref
          .read(apiServiceProvider)
          .updatePatientStatus(patientId, newStatus);

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Patient status updated to $newStatus'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Refresh the patients list
      ref.invalidate(patientsProvider);
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleAssignmentStatus(
    String patientId,
    String currentStatus,
  ) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() => _isSaving = true);

      // Call the unassign endpoint (this will automatically set status to inactive)
      await ref.read(apiServiceProvider).unassignPatient(patientId);

      if (!mounted) return;

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Patient unassigned successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh the patients list
      ref.invalidate(assignedPatientsProvider);
      ref.invalidate(notificationsProvider);
    } catch (e) {
      if (!mounted) return;

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to unassign patient: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.subtitle;
      case 'stable':
        return AppColors.success;
      case 'improving':
        return AppColors.primary;
      case 'needs attention':
        return AppColors.warning;
      default:
        return AppColors.subtitle;
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

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsProvider);

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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        'My Patients',
                        style: GoogleFonts.inter(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    // Refresh button
                    buildRefreshButton(
                      color: AppColors.primary,
                      size: 24.sp,
                      tooltip: 'Refresh Patients',
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
                  child: buildRefreshableWidget(
                    child: patientsAsync.when(
                      data: (patients) {
                        if (patients.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64.sp,
                                  color: AppColors.subtitle,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No Assigned Patients',
                                  style: GoogleFonts.inter(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.subtitle,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'You have no patients assigned to you yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: AppColors.subtitle,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Assigned Patients',
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
                                    '${patients.length}',
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
                              child: ListView.builder(
                                itemCount: patients.length,
                                itemBuilder: (context, index) {
                                  final patient = patients[index];
                                  final patientName = patient.name;
                                  final patientId = patient.id;
                                  final status = patient.status ?? 'active';
                                  final lastUpdate = patient.lastActivity;
                                  final serialNumber = patient.serialNumber;

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 16.h),
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(8.w),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                color: AppColors.primary,
                                                size: 20.sp,
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    patientName,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.text,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  Text(
                                                    'ID: $patientId',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14.sp,
                                                      color: AppColors.subtitle,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Flexible(
                                              child: Container(
                                                constraints: BoxConstraints(
                                                  minWidth: 60.w,
                                                  maxWidth: 100.w,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 6.w,
                                                  vertical: 4.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                    status,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.r,
                                                      ),
                                                ),
                                                child: Text(
                                                  _getStatusDisplayText(status),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 9.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12.h),
                                        if (serialNumber.isNotEmpty) ...[
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.qr_code,
                                                size: 16.sp,
                                                color: AppColors.subtitle,
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                'Glasses: $serialNumber',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.sp,
                                                  color: AppColors.subtitle,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: 8.h),
                                        ],
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: 16.sp,
                                              color: AppColors.subtitle,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Last Update: ${_formatTime(lastUpdate)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12.sp,
                                                color: AppColors.subtitle,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16.h),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  final result =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (_) =>
                                                                  PatientDetailsScreen(
                                                                    patient:
                                                                        patient,
                                                                  ),
                                                        ),
                                                      );

                                                  // If a result is returned (patient was updated), refresh the list
                                                  if (result != null &&
                                                      result is PatientModel) {
                                                    ref.invalidate(
                                                      patientsProvider,
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 12.h,
                                                  ),
                                                ),
                                                child: Text(
                                                  'View Details',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed:
                                                    _isSaving
                                                        ? null
                                                        : () =>
                                                            _toggleAssignmentStatus(
                                                              patientId,
                                                              status,
                                                            ),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(
                                                    color: AppColors.warning,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 12.h,
                                                  ),
                                                ),
                                                child:
                                                    _isSaving
                                                        ? SizedBox(
                                                          height: 20.h,
                                                          width: 20.w,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                  Color
                                                                >(
                                                                  AppColors
                                                                      .warning,
                                                                ),
                                                          ),
                                                        )
                                                        : Text(
                                                          'Unassign',
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 14.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    AppColors
                                                                        .warning,
                                                              ),
                                                        ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                      loading:
                          () =>
                              const Center(child: CircularProgressIndicator()),
                      error:
                          (error, stack) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.warning_2,
                                  size: 64.sp,
                                  color: AppColors.error,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'Error loading patients',
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

  String _formatTime(DateTime dateTime) {
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
  }
}
