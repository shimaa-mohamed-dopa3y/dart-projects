import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme.dart';

class SpecialistPrivacyScreen extends StatelessWidget {
  const SpecialistPrivacyScreen({super.key});

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
                          'This Privacy Policy outlines how Emo Glasses ("we," "our," or "us") collects, uses, maintains, and discloses information collected from healthcare professionals ("you") using the Emo Glasses application. This policy is designed to be compliant with HIPAA and other relevant privacy regulations.',
                        ),
                        _buildSectionTitle('2. Information We Collect'),
                        _buildParagraph(
                          'We may collect the following types of information:\n'
                          '• Personal Identification Information: Name, email address, professional credentials.\n'
                          '• Patient Data (Anonymized): Anonymized emotion and interaction data for the purpose of providing our service. All personally identifiable information (PII) is handled in accordance with HIPAA.\n'
                          '• Usage Data: Information on how you interact with the application, such as feature usage and session duration, to improve our services.',
                        ),
                        _buildSectionTitle(
                          '3. How We Use Collected Information',
                        ),
                        _buildParagraph(
                          'Emo Glasses may use your information for the following purposes:\n'
                          '• To Provide and Improve Our Service: Information helps us operate the application, respond to support requests, and enhance user experience.\n'
                          '• To Personalize User Experience: We may use information in the aggregate to understand how our users as a group use the services and resources provided.\n'
                          '• For Research and Analysis: Anonymized and aggregated data may be used for research to advance the field of AI-assisted healthcare, subject to strict privacy controls.',
                        ),
                        _buildSectionTitle('4. Data Security'),
                        _buildParagraph(
                          'We adopt appropriate data collection, storage, and processing practices and security measures to protect against unauthorized access, alteration, disclosure, or destruction of your personal information and patient data. All data is encrypted in transit and at rest.',
                        ),
                        _buildSectionTitle('5. Your Rights'),
                        _buildParagraph(
                          'You have the right to access, update, or delete your personal information. You can manage your profile information within the app or contact us for assistance. You also have control over patient data as governed by your institution and HIPAA.',
                        ),
                        _buildSectionTitle('6. Changes to This Privacy Policy'),
                        _buildParagraph(
                          'We have the discretion to update this privacy policy at any time. We encourage you to frequently check this page for any changes. You acknowledge and agree that it is your responsibility to review this privacy policy periodically.',
                        ),
                        _buildSectionTitle('7. Contacting Us'),
                        _buildParagraph(
                          'If you have any questions about this Privacy Policy, the practices of this site, or your dealings with this site, please contact us at: privacy@emoglasses.com',
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
          'Our Commitment to Your Privacy',
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
