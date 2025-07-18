import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme.dart';
import '../../core/providers/providers.dart';
import 'dart:async';

class AssignmentRequestsScreen extends ConsumerStatefulWidget {
  const AssignmentRequestsScreen({super.key});

  @override
  ConsumerState<AssignmentRequestsScreen> createState() =>
      _AssignmentRequestsScreenState();
}

class _AssignmentRequestsScreenState
    extends ConsumerState<AssignmentRequestsScreen> {
  bool _isProcessing = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        ref.invalidate(doctorAssignmentRequestsProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _acceptRequest(String requestId, String patientName) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Accept Assignment',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            content: Text(
              'Accept assignment for $patientName?',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: AppColors.subtitle,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    color: AppColors.subtitle,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _acceptAssignment(requestId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Accept',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _acceptAssignment(String requestId) async {
    if (!mounted) return;

    try {
      setState(() => _isProcessing = true);

      await ref.read(apiServiceProvider).acceptAssignmentRequest(requestId);

      if (!mounted) return;

      // Use a try-catch to safely show the SnackBar
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment accepted and patient status updated.'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        // Context is no longer valid, ignore the SnackBar
        print('Could not show success SnackBar: $e');
      }

      ref.invalidate(doctorAssignmentRequestsProvider);
      ref.invalidate(assignedPatientsProvider);
      ref.invalidate(notificationsProvider);
    } catch (e) {
      if (!mounted) return;

      // Use a try-catch to safely show the SnackBar
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept assignment: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      } catch (e) {
        // Context is no longer valid, ignore the SnackBar
        print('Could not show error SnackBar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(doctorAssignmentRequestsProvider);

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
                        'Assignment Requests',
                        style: GoogleFonts.inter(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                  child: requestsAsync.when(
                    data: (requests) {
                      if (requests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64.sp,
                                color: AppColors.subtitle,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No Pending Requests',
                                style: GoogleFonts.inter(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.subtitle,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'You have no pending assignment requests',
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
                                'Pending Requests',
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
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  '${requests.length}',
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
                            child: RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(
                                  doctorAssignmentRequestsProvider,
                                );
                              },
                              child: ListView.builder(
                                itemCount: requests.length,
                                itemBuilder: (context, index) {
                                  final request = requests[index];
                                  print(
                                    'Request data at index $index: $request',
                                  );

                                  final patient = request['patient'];
                                  final patientName =
                                      patient != null
                                          ? patient['name'] ?? 'Unknown Patient'
                                          : 'Unknown Patient';
                                  final patientId =
                                      patient != null
                                          ? patient['_id'] ?? 'Unknown ID'
                                          : 'Unknown ID';
                                  final requestTime =
                                      request['created_at'] ?? '';
                                  final requestId = request['_id'] ?? '';

                                  print(
                                    'Extracted data - patientName: $patientName, patientId: $patientId, requestId: $requestId',
                                  );

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
                                                Icons.person_add,
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
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  Text(
                                                    'Patient ID: $patientId',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14.sp,
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
                                            Icon(
                                              Icons.schedule,
                                              size: 16.sp,
                                              color: AppColors.subtitle,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              requestTime.isNotEmpty
                                                  ? 'Requested ${_formatTime(requestTime)}'
                                                  : 'Request time unknown',
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
                                                onPressed:
                                                    requestId.isNotEmpty
                                                        ? () => _acceptRequest(
                                                          requestId,
                                                          patientName,
                                                        )
                                                        : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      requestId.isNotEmpty
                                                          ? AppColors.success
                                                          : AppColors.subtitle,
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
                                                  requestId.isNotEmpty
                                                      ? 'Accept'
                                                      : 'Invalid Request',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
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
                              Icon(
                                Iconsax.warning_2,
                                size: 64.sp,
                                color: AppColors.error,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Error loading requests',
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
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String timeString) {
    try {
      final dateTime = DateTime.parse(timeString);
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
}
