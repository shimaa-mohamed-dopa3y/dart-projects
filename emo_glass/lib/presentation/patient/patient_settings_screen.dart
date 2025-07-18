import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme.dart';
import '../../core/services/audio_service.dart';
import '../../core/providers/providers.dart';
import '../onboarding/onboarding_screen.dart';
import 'patient_privacy_screen.dart';
import 'patient_help_support_screen.dart';
import 'patient_about_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'patient_profile_screen.dart';

class PatientSettingsScreen extends ConsumerStatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  ConsumerState<PatientSettingsScreen> createState() =>
      _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends ConsumerState<PatientSettingsScreen> {
  final _audioService = AudioService();
  final _emergencyContactController = TextEditingController();
  double _speechRate = 0.5;
  String _emergencyContact = '';

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioService.announceScreenChange('Patient Settings');
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final currentSpeechRate = await _audioService.getCurrentSpeechRate();

    setState(() {
      _speechRate = currentSpeechRate;
      _emergencyContact = prefs.getString('emergency_number') ?? '911';
      _emergencyContactController.text = _emergencyContact;
    });
  }

  @override
  void dispose() {
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _showSpeechRateDialog() async {
    await _audioService.announceButtonPress('Adjust speech rate');
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Adjust Speech Rate',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Current rate: ${_speechRate.toStringAsFixed(1)}',
                      style: GoogleFonts.inter(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Semantics(
                      label: 'Speech rate slider',
                      child: Slider(
                        value: _speechRate,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label: _speechRate.toStringAsFixed(1),
                        onChanged: (value) async {
                          setDialogState(() => _speechRate = value);
                          await _audioService.updateSpeechRate(value);
                          await _audioService.announceSliderValue(
                            'Speech rate',
                            value,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Drag the slider to adjust how fast the app speaks to you',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final originalRate =
                      await _audioService.getCurrentSpeechRate();
                  await _audioService.updateSpeechRate(originalRate);
                  setState(() => _speechRate = originalRate);

                  await _audioService.announceButtonPress(
                    'Cancel speech rate adjustment',
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Cancel'),
                      ),
              ElevatedButton(
                onPressed: () async {
                  await _audioService.announceSuccess(
                    'Speech rate updated to ${_speechRate.toStringAsFixed(1)}',
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _showEmergencyContactDialog() async {
    await _audioService.announceButtonPress('Manage emergency contact');
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Emergency Contact',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            content: Semantics(
              label: 'Emergency contact number input field',
              child: TextField(
                controller: _emergencyContactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency Number',
                  hintText: 'e.g., 911',
              ),
                onChanged: (value) async {
                  await _audioService.announceFormField(
                    'Emergency number',
                    value,
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await _audioService.announceButtonPress(
                    'Cancel emergency contact',
                  );
      if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newContact = _emergencyContactController.text;
                  if (newContact.isNotEmpty) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('emergency_number', newContact);
                    setState(() => _emergencyContact = newContact);
                    await _audioService.announceSuccess(
                      'Emergency contact updated',
                    );
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  } else {
                    await _audioService.announceError(
                      'Please enter a valid emergency number',
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _showRecordingPermissionsDialog() async {
    await _audioService.announceButtonPress('Recording permissions settings');
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
            title: Text(
                  'Recording Permissions',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice recording settings:',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: AppColors.subtitle,
              ),
            ),
                    SizedBox(height: 20.h),

                    // Auto upload status (always enabled)
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Automatic Upload',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                              ),
                            ),
                            Text(
                                  'Always enabled - recordings are automatically uploaded to your healthcare provider',
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
                        ),

                    SizedBox(height: 16.h),

                    // Information about recording
                              Container(
                      padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                        color: AppColors.subtitle.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                                ),
                      child: Text(
                        'Voice recordings are used for emotion analysis and medical assessment. All recordings are automatically uploaded to your assigned healthcare provider.',
                                  style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppColors.subtitle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await _audioService.announceButtonPress(
                        'Close permissions',
                      );
                      Navigator.pop(context);
                    },
                                child: Text(
                      'Close',
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                ],
              );
            },
          ),
    );
  }

  void _handleLogout() async {
    try {
      // Perform logout via the repository
      await ref.read(authRepositoryProvider).logoutUser();

      // Invalidate core providers to reset app state
      ref.invalidate(apiServiceProvider);
      ref.invalidate(currentUserProvider);

      if (mounted) {
        // Navigate to onboarding and remove all previous routes
        Navigator.pushAndRemoveUntil(
                                        context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
                                      );
                                    }
                                  } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.mainGradient),
          child: Column(
            children: [
            SizedBox(height: 60.h),
              Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                  Icon(
                    Iconsax.setting_2,
                          color: AppColors.primary,
                    size: 28.sp,
                        ),
                  SizedBox(width: 12.w),
                    Text(
                      'Settings',
                      style: GoogleFonts.inter(
                      fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 24.h),
              Expanded(
                  child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                    _buildSectionTitle('Account'),
                    _buildSettingsCard([
                      _buildSettingsTile(
                          icon: Iconsax.user,
                        title: 'Edit Profile',
                          subtitle: 'Manage your personal information',
                          onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PatientProfileScreen(),
                            ),
                          );
                          },
                        ),
                    ]),
                    SizedBox(height: 20.h),
                        _buildSectionTitle('Accessibility'),
                    _buildSettingsCard([
                      _buildSettingsTile(
                          icon: Iconsax.volume_high,
                        title: 'Speech Rate',
                        subtitle:
                            'Current: ${_speechRate.toStringAsFixed(1)} - Adjust text-to-speech speed',
                        onTap: _showSpeechRateDialog,
                      ),
                    ]),
                    SizedBox(height: 20.h),
                    _buildSectionTitle('Safety'),
                    _buildSettingsCard([
                      _buildSettingsTile(
                        icon: Iconsax.call,
                        title: 'Emergency Contact',
                        subtitle:
                            'Current: $_emergencyContact - Set emergency number',
                        onTap: _showEmergencyContactDialog,
                      ),
                    ]),
                    SizedBox(height: 20.h),
                    _buildSectionTitle('Privacy'),
                    _buildSettingsCard([
                      _buildSettingsTile(
                          icon: Iconsax.shield_tick,
                        title: 'Recording Permissions',
                        subtitle: _getRecordingPermissionsSubtitle(),
                        onTap: _showRecordingPermissionsDialog,
                      ),
                    ]),
                    SizedBox(height: 20.h),
                    _buildSectionTitle('Support'),
                    _buildSettingsCard([
                      _buildSettingsTile(
                        icon: Iconsax.support,
                        title: 'Help & Support',
                        subtitle: 'Get help and find answers',
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const PatientHelpSupportScreen(),
                              ),
                            ),
                        ),
                      _buildSettingsTile(
                        icon: Iconsax.document_text,
                        title: 'Privacy Policy',
                        subtitle: 'Read our privacy policy',
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PatientPrivacyScreen(),
                              ),
                        ),
                      ),
                      _buildSettingsTile(
                          icon: Iconsax.info_circle,
                        title: 'About Emo Glasses',
                        subtitle: 'Learn more about the app',
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PatientAboutScreen(),
                              ),
                            ),
                        ),
                    ]),
                    SizedBox(height: 20.h),
                        Semantics(
                      label: 'Logout button - Sign out of the application',
                          button: true,
                      child: ElevatedButton.icon(
                              onPressed: _handleLogout,
                        icon: const Icon(Iconsax.logout, color: Colors.white),
                        label: Text(
                                    'Logout',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 56.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                                  ),
                          elevation: 0,
                            ),
                          ),
                        ),
                    SizedBox(height: 40.h),
                      ],
                  ),
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 4.w),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
      title,
      style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
          decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppTheme.cardShadow,
                ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: '$title, $subtitle',
      button: true,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
        subtitle: Text(
                    subtitle,
          style: GoogleFonts.inter(color: AppColors.textLight),
                  ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          await _audioService.announceButtonPress(title);
          onTap();
        },
      ),
    );
  }

  String _getRecordingPermissionsSubtitle() {
    return 'Automatic upload enabled - Voice recording settings';
  }
}
