import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';

class SpecialistHelpSupportScreen extends StatelessWidget {
  const SpecialistHelpSupportScreen({super.key});

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
                      'Help & Support',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                  Text(
                          'How can we help?',
                                    style: GoogleFonts.inter(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Find answers to your questions and get in touch with our team.',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 32.h),
                        _buildHelpOption(
                          icon: Iconsax.message_question,
                          title: 'Frequently Asked Questions',
                          subtitle: 'Find answers to common questions',
                          onTap: () => _showFAQ(context),
                        ),
                        _buildHelpOption(
                          icon: Iconsax.document_text,
                          title: 'Documentation',
                          subtitle: 'View technical and clinical guides',
                          onTap: () => _openUrl(context, 'https://flutter.dev'),
                        ),
                        _buildHelpOption(
                          icon: Iconsax.sms,
                          title: 'Contact Support',
                          subtitle: 'Get in touch with our support team',
                          onTap:
                              () => _openUrl(
                                context,
                                'mailto:support@example.com',
                              ),
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

  Widget _buildHelpOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24.sp),
        ),
        title: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 14.sp)),
        trailing: const Icon(Iconsax.arrow_right_3, color: AppColors.primary),
        onTap: onTap,
      ),
    );
  }

  void _showFAQ(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.w),
                child: Text(
                      'Frequently Asked Questions',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      children: const [
                        ExpansionTile(
                          title: Text('How accurate is the emotion detection?'),
                          children: [
                            ListTile(
                              title: Text(
                                'Our AI model is trained on a diverse dataset and achieves over 94% accuracy in controlled clinical trials. Real-world performance may vary based on environmental factors.',
                ),
              ),
            ],
          ),
                        ExpansionTile(
            title: Text(
                            'Is the data secure and HIPAA compliant?',
                          ),
                children: [
                            ListTile(
                              title: Text(
                                'Yes, all data is encrypted both in transit and at rest. Our platform is built to be fully HIPAA compliant, ensuring patient privacy and data security.',
                ),
              ),
            ],
          ),
                        ExpansionTile(
                          title: Text('How do I manage my patients?'),
                          children: [
                            ListTile(
            title: Text(
                                'You can view, manage, and unassign patients from the "My Patients" section of the dashboard. Patient status and details can be viewed there as well.',
                ),
              ),
            ],
          ),
                        ExpansionTile(
                          title: Text(
                            'Can I integrate with my EMR/EHR system?',
                          ),
                          children: [
                            ListTile(
            title: Text(
                                'We are actively working on integrations with major EMR/EHR providers. Please contact support for more information on our current partners and roadmap.',
                ),
              ),
            ],
          ),
                      ],
            ),
          ),
        ],
      ),
    );
          },
        );
      },
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Simple print instead of trying to show snackbar on disposed widget
        print('Unable to open $url');
      }
    } catch (e) {
      // Simple print instead of trying to show snackbar on disposed widget
      print('Error opening link: $e');
    }
  }
}
