import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme.dart';
import '../../core/services/audio_service.dart';
import '../../core/providers/providers.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() =>
      _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  final _audioService = AudioService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _serialNumberController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _serialNumberController = TextEditingController(
      text: user?.serialNumber ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioService.announceScreenChange('Profile');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _serialNumberController.dispose();
    super.dispose();
  }

  Future<void> _toggleEditing() async {
    setState(() => _isEditing = !_isEditing);
    await _audioService.announceButtonPress(
      _isEditing ? 'Edit mode enabled' : 'Edit mode disabled',
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _audioService.announceButtonPress('Save profile');

      final authNotifier = ref.read(authProvider.notifier);

      await authNotifier.updateProfile(
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        serialNumber: _serialNumberController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isEditing = false);
      await _audioService.announceSuccess('Profile updated successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      await _audioService.announceError('Failed to update profile');

      String errorMessage = 'An unexpected error occurred.';
      if (e.toString().contains('serial number used by another user')) {
        errorMessage = 'This serial number is already in use.';
      } else if (e.toString().contains('Network error')) {
        errorMessage = 'Network error. Please check your connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Profile',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Semantics(
                      label: _isEditing ? 'Cancel editing' : 'Edit profile',
                      button: true,
                      child: IconButton(
                        onPressed: _toggleEditing,
                        icon: Icon(
                          _isEditing ? Icons.close : Icons.edit,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          user?.name ?? 'Patient',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Patient Account',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.subtitle,
                          ),
                        ),
                        const SizedBox(height: 32),

                                _buildFormField(
                                  label: 'Full Name',
                                  controller: _nameController,
                                  icon: Icons.person_outline,
                                  enabled: _isEditing,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildFormField(
                                  label: 'Email',
                                  controller: _emailController,
                                  icon: Icons.email_outlined,
                                  enabled: _isEditing,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Email is required';
                                    }
                                    if (!value!.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildFormField(
                                  label: 'Serial Number',
                                  controller: _serialNumberController,
                                  icon: Iconsax.scan_barcode,
                                  enabled: _isEditing,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Serial number is required';
                                    }
                                    return null;
                                  },
                        ),

                        if (_isEditing) ...[
                            const SizedBox(height: 40),
                            ElevatedButton(
                                onPressed: _saveProfile,
                              child: const Text('Save Changes'),
                                style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                  backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
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
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: '$label input field',
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: enabled ? AppColors.primary : AppColors.subtitle,
              ),
              filled: true,
              fillColor: enabled ? AppColors.background : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
