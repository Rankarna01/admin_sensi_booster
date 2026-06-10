import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.neonGreen,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonGreen,
        secondary: AppColors.neonGreenDark,
        surface: AppColors.surface,
      ),

      // Global Font: Inter untuk body (clean, modern, highly readable)
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
        displayMedium: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 28, fontWeight: FontWeight.w600, height: 1.2),
        displaySmall: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 24, fontWeight: FontWeight.w600, height: 1.3),
        headlineMedium: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
        headlineSmall: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.w500, height: 1.4),
        titleLarge: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
        titleMedium: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
        bodyLarge: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.w400, height: 1.6),
        bodyMedium: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w400, height: 1.5),
        labelLarge: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        labelMedium: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3),
        labelSmall: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.8),
      ),

      // Global Style untuk TextField (Kolom Input)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.neonGreen, width: 1.5),
        ),
        prefixIconColor: AppColors.textMuted,
      ),

      // Global Style untuk ElevatedButton (Tombol Utama)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          shadowColor: AppColors.neonGreen.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Global Style untuk Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 18, fontWeight: FontWeight.w600),
        contentTextStyle: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w400),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: AppColors.neonGreen, size: 22),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.background;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.neonGreen;
          return AppColors.border;
        }),
      ),

      // Slider
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.neonGreen,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.neonGreen,
        trackHeight: 4.0,
      ),

      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Utility: Orbitron font for display/heading only
  static TextStyle orbitronHeading({double size = 18, Color color = AppColors.neonGreen}) {
    return GoogleFonts.orbitron(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
  }

  static TextStyle orbitronLabel({double size = 10, Color color = AppColors.textMuted}) {
    return GoogleFonts.orbitron(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
      height: 1.4,
    );
  }

  static TextStyle orbitronValue({double size = 22, Color color = AppColors.textWhite}) {
    return GoogleFonts.orbitron(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.1,
    );
  }
}
