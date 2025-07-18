import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';
import '../theme.dart';

class AccessibilityWidgets {
  static final AudioService _audioService = AudioService();

  // Accessible button with audio feedback
  static Widget accessibleButton({
    required String label,
    required VoidCallback onPressed,
    required Widget child,
    String? audioLabel,
    bool announceOnPress = true,
    ButtonStyle? style,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: ElevatedButton(
        onPressed: () async {
          if (announceOnPress) {
            await _audioService.announceButtonPress(audioLabel ?? label);
          }
          onPressed();
        },
        style: style,
        child: child,
      ),
    );
  }

  // Accessible icon button with audio feedback
  static Widget accessibleIconButton({
    required String label,
    required VoidCallback onPressed,
    required Icon icon,
    String? audioLabel,
    bool announceOnPress = true,
    IconButton? iconButton,
  }) {
    return Semantics(
      label: label,
      button: true,
      child:
          iconButton ??
          IconButton(
            onPressed: () async {
              if (announceOnPress) {
                await _audioService.announceButtonPress(audioLabel ?? label);
              }
              onPressed();
            },
            icon: icon,
          ),
    );
  }

  // Accessible switch with audio feedback
  static Widget accessibleSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? audioLabel,
    bool announceOnChange = true,
    Switch? switchWidget,
  }) {
    return Semantics(
      label: label,
      value: value.toString(),
      onTap: () async {
        if (announceOnChange) {
          await _audioService.announceSwitchState(audioLabel ?? label, !value);
        }
        onChanged(!value);
      },
      child:
          switchWidget ??
          Switch(
            value: value,
            onChanged: (newValue) async {
              if (announceOnChange) {
                await _audioService.announceSwitchState(
                  audioLabel ?? label,
                  newValue,
                );
              }
              onChanged(newValue);
            },
            activeColor: AppColors.primary,
            inactiveThumbColor: AppColors.disabled,
            inactiveTrackColor: AppColors.disabled.withOpacity(0.3),
          ),
    );
  }

  // Accessible slider with audio feedback
  static Widget accessibleSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
    int? divisions,
    String? audioLabel,
    bool announceOnChange = true,
  }) {
    return Semantics(
      label: label,
      value: value.toStringAsFixed(1),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: value.toStringAsFixed(1),
        onChanged: (newValue) async {
          if (announceOnChange) {
            await _audioService.announceSliderValue(
              audioLabel ?? label,
              newValue,
            );
          }
          onChanged(newValue);
        },
        activeColor: AppColors.primary,
        inactiveColor: AppColors.disabled.withOpacity(0.3),
      ),
    );
  }

  // Accessible text field with audio feedback
  static Widget accessibleTextField({
    required String label,
    required TextEditingController controller,
    required String semanticLabel,
    String? hintText,
    TextInputType? keyboardType,
    bool enabled = true,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool announceOnTap = true,
    InputDecoration? decoration,
  }) {
    return Semantics(
      label: semanticLabel,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        onTap:
            onTap != null
                ? () async {
                  if (announceOnTap) {
                    await _audioService.announceFormField(semanticLabel, '');
                  }
                  onTap();
                }
                : null,
        decoration:
            decoration ??
            InputDecoration(
              labelText: label,
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
        style: GoogleFonts.inter(fontSize: 16.sp),
      ),
    );
  }

  // Accessible list tile with audio feedback
  static Widget accessibleListTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? audioLabel,
    bool announceOnTap = true,
    Widget? leading,
    Widget? trailing,
    ListTile? listTile,
  }) {
    return Semantics(
      label: '$title, $subtitle',
      button: true,
      child:
          listTile ??
          ListTile(
            leading: leading,
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
            trailing: trailing,
            onTap: () async {
              if (announceOnTap) {
                await _audioService.announceButtonPress(audioLabel ?? title);
              }
              onTap();
            },
          ),
    );
  }

  // Accessible card with audio feedback
  static Widget accessibleCard({
    required String label,
    required Widget child,
    String? audioLabel,
    bool announceOnTap = false,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BoxDecoration? decoration,
  }) {
    Widget cardContent = Container(
      padding: padding ?? EdgeInsets.all(16.w),
      margin: margin,
      decoration:
          decoration ??
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: AppTheme.cardShadow,
          ),
      child: child,
    );

    if (onTap != null) {
      cardContent = GestureDetector(
        onTap: () async {
          if (announceOnTap) {
            await _audioService.announceButtonPress(audioLabel ?? label);
          }
          onTap();
        },
        child: cardContent,
      );
    }

    return Semantics(label: label, child: cardContent);
  }

  // Accessible section header
  static Widget accessibleSectionHeader({
    required String title,
    String? subtitle,
  }) {
    return Semantics(
      label: subtitle != null ? '$title, $subtitle' : title,
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppColors.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Announce screen change
  static Future<void> announceScreenChange(String screenName) async {
    await _audioService.announceScreenChange(screenName);
  }

  // Announce success message
  static Future<void> announceSuccess(String message) async {
    await _audioService.announceSuccess(message);
  }

  // Announce error message
  static Future<void> announceError(String message) async {
    await _audioService.announceError(message);
  }

  // Announce warning message
  static Future<void> announceWarning(String message) async {
    await _audioService.announceWarning(message);
  }

  // Announce info message
  static Future<void> announceInfo(String message) async {
    await _audioService.announceInfo(message);
  }

  // Announce loading message
  static Future<void> announceLoading(String message) async {
    await _audioService.announceLoading(message);
  }
}
 