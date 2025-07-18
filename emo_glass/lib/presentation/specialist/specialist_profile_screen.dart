import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/providers/providers.dart';
import '../../core/theme.dart';

class SpecialistProfileScreen extends ConsumerStatefulWidget {
  const SpecialistProfileScreen({super.key});

  @override
  ConsumerState<SpecialistProfileScreen> createState() =>
      _SpecialistProfileScreenState();
}

class _SpecialistProfileScreenState
    extends ConsumerState<SpecialistProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _specialtyController;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final user = ref.read(currentUserProvider);

    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _specialtyController = TextEditingController(text: user?.specialist ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ref
          .read(authProvider.notifier)
          .updateProfile(name: _nameController.text);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
    final user = ref.read(currentUserProvider);
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _specialtyController.text = user?.specialist ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Profile',
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                      icon: Icon(
                        _isEditing ? Icons.close : Iconsax.edit,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.w),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            width: 120.w,
                            height: 120.w,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Iconsax.user,
                              color: Colors.white,
                              size: 64.w,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          _buildFormField(
                            label: 'Full Name',
                            controller: _nameController,
                            icon: Iconsax.user,
                            enabled: _isEditing,
                            validator:
                                (value) =>
                                    value!.isEmpty ? 'Name is required' : null,
                          ),
                          SizedBox(height: 20.h),
                          _buildFormField(
                            label: 'Email',
                            controller: _emailController,
                            icon: Iconsax.sms,
                            enabled: false,
                          ),
                          SizedBox(height: 20.h),
                          _buildFormField(
                            label: 'Specialty',
                            controller: _specialtyController,
                            icon: Iconsax.health,
                            enabled: false,
                          ),
                          SizedBox(height: 40.h),
                          if (_isEditing)
                            _isSaving
                                ? const CircularProgressIndicator()
                                : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _saveProfile,
                                    style: AppTheme.primaryButtonStyle,
                                    child: Text(
                                      'Save Changes',
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          style: GoogleFonts.inter(
            color: enabled ? AppColors.text : AppColors.textLight,
          ),
          decoration: AppTheme.inputDecoration(
            hintText: '',
            icon: icon,
          ).copyWith(
            fillColor:
                enabled
                    ? AppColors.inputBackground
                    : AppColors.inputBackground.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
