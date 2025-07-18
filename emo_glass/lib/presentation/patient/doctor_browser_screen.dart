import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme.dart';
import '../../core/services/audio_service.dart';
import '../../core/providers/providers.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';
import 'dart:async';

class DoctorBrowserScreen extends ConsumerStatefulWidget {
  const DoctorBrowserScreen({super.key});

  @override
  ConsumerState<DoctorBrowserScreen> createState() =>
      _DoctorBrowserScreenState();
}

class _DoctorBrowserScreenState extends ConsumerState<DoctorBrowserScreen> {
  final _audioService = AudioService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _mounted = true;

  // Polling timer
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audioService.announceScreenChange('Doctor Browser');
      // Start polling for real-time updates
      _startPolling();
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    try {
      // Invalidate providers to refresh data
      ref.invalidate(doctorsProvider);
      ref.invalidate(currentUserProvider);
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pollingTimer?.cancel();
    _mounted = false;
    super.dispose();
  }

  Future<void> _requestAssignment(UserModel doctor) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (!mounted) return;
      _showSnackBar(
        'Unable to get current user information. Please try again.',
        AppColors.error,
      );
      return;
    }

    // Check if user is a patient
    if (currentUser.role != 'patient') {
      if (!mounted) return;
      _showSnackBar(
        'Only patients can request doctor assignments.',
        AppColors.error,
      );
      return;
    }

    // Check if already assigned to this doctor
    if (currentUser.assignedDoctor == doctor.id) {
      if (!mounted) return;
      _showSnackBar(
        'You are already assigned to Dr. ${doctor.name}',
        AppColors.warning,
      );
      return;
    }

    // Check if assigned to another doctor
    if (currentUser.assignedDoctor != null) {
      if (!mounted) return;
      _showSnackBar(
        'You are already assigned to another doctor. Please unassign from your current doctor before requesting a new one.',
        AppColors.warning,
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Request assignment
      await ref
          .read(apiServiceProvider)
          .requestAssignmentToDoctor(doctorId: doctor.id);

      if (!mounted) return;

      // Play success sound
      await _audioService.announceSuccess(
        'Assignment request sent successfully',
      );

      // Show success message
      _showSnackBar(
        'Assignment request sent to Dr. ${doctor.name}',
        AppColors.success,
      );

      // Refresh providers
      if (!mounted) return;
      ref.invalidate(currentUserProvider);
      ref.invalidate(doctorsProvider);
    } catch (e) {
      if (!mounted) return;

      // Play error sound
      await _audioService.announceError('Failed to send assignment request');

      String errorMessage = 'Failed to send assignment request';

      if (e.toString().contains('already have an active doctor')) {
        errorMessage =
            'You already have an active doctor. Please unassign first.';
      } else if (e.toString().contains('already requested') ||
          e.toString().contains('pending request')) {
        errorMessage = 'You have already sent a request to this doctor.';
      } else if (e.toString().contains('doctor not found')) {
        errorMessage = 'Doctor not found. Please refresh and try again.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      // Show error message
      _showSnackBar(errorMessage, AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;

    // Use a safer way to show snackbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  List<UserModel> _filterDoctors(List<UserModel> doctors) {
    if (_searchQuery.isEmpty) return doctors;

    return doctors.where((doctor) {
      final name = doctor.name.toLowerCase();
      final specialist = (doctor.specialist ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || specialist.contains(query);
    }).toList();
  }

  Widget _buildCurrentDoctorSection(User? currentUser) {
    if (currentUser?.assignedDoctor == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        margin: EdgeInsets.symmetric(horizontal: 24.w),
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
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.subtitle, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'You currently have no assigned doctor. Browse the list below to request an assignment.',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.subtitle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Use the doctorDetailsProvider instead of direct API call
    final doctorDetailsAsync = ref.watch(
      doctorDetailsProvider(currentUser!.assignedDoctor!),
    );

    return doctorDetailsAsync.when(
      data: (doctor) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          margin: EdgeInsets.symmetric(horizontal: 24.w),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Current Doctor',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${doctor.name}',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          doctor.specialist ?? 'General Practitioner',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Active',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading:
          () => Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            margin: EdgeInsets.symmetric(horizontal: 24.w),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Loading doctor details...',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
      error:
          (error, stack) => Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            margin: EdgeInsets.symmetric(horizontal: 24.w),
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
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error loading assigned doctor details',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        error.toString(),
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
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final doctorsAsync = ref.watch(doctorsProvider);

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
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      'Browse Doctors',
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Current Doctor Section
              _buildCurrentDoctorSection(currentUser),
              SizedBox(height: 24.h),

              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Semantics(
                  label: 'Search doctors by name or specialization',
                  child: Container(
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
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) async {
                        setState(() {
                          _searchQuery = value;
                        });
                        if (value.isNotEmpty) {
                          await _audioService.announceFormField(
                            'Search query',
                            value,
                          );
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Search doctors by name or specialization...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppColors.subtitle,
                        ),
                        prefixIcon: Icon(
                          Iconsax.search_normal,
                          color: AppColors.primary,
                          size: 20.sp,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 16.h,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Doctors List
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
                  child: doctorsAsync.when(
                    data: (doctors) {
                      final filteredDoctors = _filterDoctors(doctors);

                      if (filteredDoctors.isEmpty) {
                        return Semantics(
                          label:
                              _searchQuery.isEmpty
                                  ? 'No doctors available'
                                  : 'No doctors found for search query',
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.search_normal,
                                  size: 64.sp,
                                  color: AppColors.subtitle,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No doctors available'
                                      : 'No doctors found for "$_searchQuery"',
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    color: AppColors.subtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Semantics(
                        label:
                            'Doctors list, ${filteredDoctors.length} doctors found',
                        child: ListView.builder(
                          itemCount: filteredDoctors.length,
                          itemBuilder: (context, index) {
                            final doctor = filteredDoctors[index];
                            return _buildDoctorCard(doctor);
                          },
                        ),
                      );
                    },
                    loading:
                        () => Semantics(
                          label: 'Loading doctors',
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    error:
                        (error, stack) => Semantics(
                          label: 'Error loading doctors',
                          child: Center(
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
                                  'Error loading doctors',
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

  Widget _buildDoctorCard(UserModel doctor) {
    final currentUser = ref.watch(currentUserProvider);
    final bool isAssigned = currentUser?.assignedDoctor != null;
    final bool isThisDoctor = currentUser?.assignedDoctor == doctor.id;

    final semanticLabel =
        isThisDoctor
            ? 'Dr. ${doctor.name}, ${doctor.specialist ?? 'General Practitioner'}, your current doctor'
            : isAssigned
            ? 'Dr. ${doctor.name}, ${doctor.specialist ?? 'General Practitioner'}, cannot request assignment'
            : 'Dr. ${doctor.name}, ${doctor.specialist ?? 'General Practitioner'}, tap to request assignment';

    return Semantics(
      label: semanticLabel,
      button: !isAssigned || isThisDoctor,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.all(16.w),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Iconsax.user,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        doctor.specialist ?? 'General Practitioner',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Semantics(
              label:
                  isThisDoctor
                      ? 'Current doctor button'
                      : isAssigned
                      ? 'Cannot request assignment button'
                      : 'Request assignment button',
              button: !isAssigned || isThisDoctor,
              child: ElevatedButton(
                onPressed:
                    isAssigned && !isThisDoctor
                        ? null
                        : () async {
                          if (!isThisDoctor) {
                            await _audioService.announceButtonPress(
                              'Request assignment with Dr. ${doctor.name}',
                            );
                          }
                          _requestAssignment(doctor);
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isThisDoctor
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.primary,
                  foregroundColor:
                      isThisDoctor ? AppColors.success : Colors.white,
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  disabledBackgroundColor: AppColors.disabled,
                ),
                child: Text(
                  isThisDoctor
                      ? 'Current Doctor'
                      : isAssigned
                      ? 'Cannot Request'
                      : 'Request Assignment',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
