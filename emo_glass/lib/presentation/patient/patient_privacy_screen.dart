import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class PatientPrivacyScreen extends StatelessWidget {
  const PatientPrivacyScreen({super.key});

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
                padding: EdgeInsets.all(24.w),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      'Privacy Policy',
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPolicyHeader(),
                        SizedBox(height: 24.h),
                        _buildSectionTitle('1. Introduction'),
                        _buildParagraph(
                          'This Privacy Policy explains how Emo Glasses ("we," "our," or "us") collects, uses, and protects your information when you use our accessibility application. We are committed to protecting your privacy and ensuring your data is handled securely.',
                        ),
                        _buildSectionTitle('2. Information We Collect'),
                        _buildParagraph(
                          'We collect minimal information necessary for app functionality:\n'
                          '• Device Information: Basic device details for app optimization\n'
                          '• Usage Data: How you interact with the app to improve accessibility features\n'
                          '• Emotion Data: Processed locally on your device for real-time assistance\n'
                          '• Voice Commands: Processed locally for hands-free operation',
                        ),
                        _buildSectionTitle('3. How We Use Your Information'),
                        _buildParagraph(
                          'Your information is used solely to:\n'
                          '• Provide real-time emotion detection and voice assistance\n'
                          '• Improve app accessibility and user experience\n'
                          '• Ensure app stability and performance\n'
                          '• Provide customer support when needed',
                        ),
                        _buildSectionTitle('4. Data Security'),
                        _buildParagraph(
                          'We implement strong security measures to protect your information:\n'
                          '• All data is encrypted in transit and at rest\n'
                          '• Emotion detection processes locally on your device\n'
                          '• No personal information is shared without your consent\n'
                          '• Regular security updates and monitoring',
                        ),
                        _buildSectionTitle('5. Your Rights'),
                        _buildParagraph(
                          'You have control over your data:\n'
                          '• Access and update your profile information\n'
                          '• Delete your account and associated data\n'
                          '• Control app permissions through device settings\n'
                          '• Contact us with privacy concerns',
                        ),
                        _buildSectionTitle('6. Contact Us'),
                        _buildParagraph(
                          'If you have questions about this Privacy Policy or our data practices, please contact us at: privacy@emoglasses.com',
                        ),
                      ],
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

  Widget _buildPolicyHeader() {
    return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
          'Your Privacy Matters',
                    style: GoogleFonts.inter(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
          'Last updated: July 29, 2024',
                    style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
                    ),
                  ),
                ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
                      style: GoogleFonts.inter(
        fontSize: 15.sp,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );
  }
}
