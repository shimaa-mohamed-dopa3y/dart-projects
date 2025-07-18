import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF7BA7B3); // Teal blue for buttons and branding
  static const Color primaryLight = Color(0xFF9CC4CE);
  static const Color primaryDark = Color(0xFF5A8B95);

  static const Color background = Color(0xFFB8D4DB); // Soft teal gradient top
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure white cards
  static const Color surface = Color(0xFFF8FAFB);

  static const Color text = Color(0xFF2D3748); // Dark gray/black for main text
  static const Color textSecondary = Color(0xFF4A5568); // Medium gray
  static const Color textLight = Color(0xFF718096); // Light gray text
  static const Color subtitle = Color(0xFF9CA3AF); // Subtitle gray

  static const Color accent = Color(0xFF7BA7B3);
  static const Color success = Color(0xFF48BB78); // Green for "Stable"
  static const Color warning = Color(0xFFED8936); // Orange for "Needs Attention"
  static const Color error = Color(0xFFE53E3E); // Red for emergency/sign out
  static const Color info = Color(0xFF4299E1); // Blue for "Improving"

  static const Color emergency = Color(0xFFE53E3E); // Red emergency button
  static const Color recording = Color(0xFF48BB78);
  static const Color disabled = Color(0xFFBDBDBD);

  static const Color inputBackground = Color(0xFFFFFFFF); // Pure white input fields
  static const Color inputFocused = Color(0xFF7BA7B3);
  static const Color textOnPrimary = Colors.white;

  static const Color stable = Color(0xFF48BB78); // Green
  static const Color improving = Color(0xFF4299E1); // Blue
  static const Color needsAttention = Color(0xFFED8936); // Orange

  static const Color helpSupport = Color(0xFF805AD5); // Purple for Help & Support
  static const Color about = Color(0xFF805AD5); // Purple for About

  static const Color card = Color(0xFFFFFFFF); // Pure white cards
  static const Color secondary = Color(0xFF9CC4CE);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.interTextTheme(),
    useMaterial3: true,
  );

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFB8D4DB), // Soft teal at top
      Color(0xFFC4D9E0), // Medium teal-blue
      Color(0xFFD0DEE5), // Lighter blue-gray at bottom
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7BA7B3), Color(0xFF6A96A2)],
  );

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.25),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  static InputDecoration inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        color: AppColors.textLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    shadowColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.primary,
    shadowColor: AppColors.primary.withOpacity(0.2),
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
    ),
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
  );

  static ButtonStyle emergencyButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.emergency,
    foregroundColor: Colors.white,
    shadowColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
  );

  static ButtonStyle helpSupportButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.helpSupport,
    foregroundColor: Colors.white,
    shadowColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
  );
}
