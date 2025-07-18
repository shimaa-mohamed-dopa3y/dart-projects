import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class SpecialistAboutScreen extends StatelessWidget {
  const SpecialistAboutScreen({super.key});

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
                      'About Emo Glasses',
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
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      const Spacer(),
                      Image.asset(
                                    'assets/images/image.png',
                        width: 100.w,
                        height: 100.w,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 24.h),
                              Text(
                                'Emo Glasses',
                                style: GoogleFonts.inter(
                                  fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                        'Empowering healthcare through AI-driven emotional insight.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                          color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                          'Version 1.0.0 (Specialist Edition)',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                      const Spacer(),
                        Text(
                        '© 2024 Emo Glasses Inc. All Rights Reserved.',
                          style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
          ),
    );
  }
}
