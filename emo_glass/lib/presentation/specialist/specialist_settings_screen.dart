import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/providers/providers.dart';
import '../../core/theme.dart';
import '../notification_settings_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'specialist_about_screen.dart';
import 'specialist_help_support_screen.dart';
import 'specialist_profile_screen.dart';
import 'specialist_privacy_screen.dart';

class SpecialistSettingsScreen extends ConsumerStatefulWidget {
  const SpecialistSettingsScreen({super.key});

  @override
  ConsumerState<SpecialistSettingsScreen> createState() =>
      _SpecialistSettingsScreenState();
}

class _SpecialistSettingsScreenState
    extends ConsumerState<SpecialistSettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _handleLogout() async {
    try {
      // Perform logout via the repository
      await ref.read(authRepositoryProvider).logoutUser();

      // Invalidate core providers to reset app state
      ref.invalidate(apiServiceProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(patientsProvider);
      ref.invalidate(notificationsProvider);

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
                              builder: (_) => const SpecialistProfileScreen(),
                              ),
                            );
                          },
                        ),
                    ]),
                    SizedBox(height: 20.h),
                    _buildSectionTitle('Application'),
                    _buildSettingsCard([
                      _buildSettingsTile(
                        icon: Iconsax.notification,
                        title: 'Notification Preferences',
                        subtitle: 'Choose what to be notified about',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                  (_) => const NotificationSettingsScreen(),
                              ),
                            );
                          },
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
                                    (_) => const SpecialistHelpSupportScreen(),
                              ),
                            ),
                        ),
                      _buildSettingsTile(
                        icon: Iconsax.shield_search,
                        title: 'Privacy Policy',
                        subtitle: 'Read our privacy policy',
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SpecialistPrivacyScreen(),
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
                                builder: (_) => const SpecialistAboutScreen(),
                              ),
                            ),
                          ),
                    ]),
                    SizedBox(height: 20.h),
                    ElevatedButton.icon(
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
    return ListTile(
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
      onTap: onTap,
    );
  }
}
