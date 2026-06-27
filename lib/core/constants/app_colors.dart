import 'package:flutter/material.dart';

class AppColors {
  // Warna MFW Design System
  static const Color background = Color(0xFF0A0B0D); // Hitam lebih dalam
  static const Color surface = Color(0xFF111215); // Surface layer di atas background
  static const Color card = Color(0xFF151619); // Warna kartu (sedikit lebih terang)
  static const Color cardElevated = Color(0xFF1A1B1F); // Kartu yang di-hover/aktif
  
  // Neon Green Palette
  static const Color neonGreen = Color(0xFF4ADE80); // Hijau utama
  static const Color neonGreenDark = Color(0xFF22C55E); // Hijau lebih gelap (pressed state)
  static const Color neonGreenSoft = Color(0xFF166534); // Hijau sangat redup (background glow)

  // Neon Orange Palette (Game Corner "AX-MODE" style panel)
  static const Color neonOrange = Color(0xFFFF7A1A); // Oranye utama
  static const Color neonOrangeDark = Color(0xFFE85D04); // Oranye lebih gelap (pressed state)

  // RGB accent gradient untuk CPU/RAM level bar, urut dari ujung bawah ke atas
  static const List<Color> rgbAccentGradient = [
    Color(0xFF4E6BFF), // biru (ujung bawah)
    Color(0xFFB14EFF), // ungu
    Color(0xFFFF4FA3), // pink
    Color(0xFFFF5757), // merah karang
    Color(0xFFFF8C00), // oranye
    Color(0xFFFFA500), // oranye terang (dekat header)
  ];
  
  // Teks & Garis
  static const Color textWhite = Color(0xFFF1F5F9); // Putih lembut (tidak terlalu menyilaukan)
  static const Color textSecondary = Color(0xFF94A3B8); // Abu-abu terang (subteks)
  static const Color textMuted = Color(0xFF64748B); // Abu-abu redup (placeholder)
  static const Color border = Color(0xFF1E293B); // Garis tipis (lebih subtle)
  static const Color borderLight = Color(0xFF334155); // Garis lebih terang (active state)

  // Glow Utility
  static List<BoxShadow> glowGreen({double blur = 20, double spread = 0, double opacity = 0.15}) {
    return [
      BoxShadow(
        color: neonGreen.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static List<BoxShadow> glowGreenSoft() {
    return [
      BoxShadow(
        color: neonGreen.withOpacity(0.08),
        blurRadius: 30,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: neonGreen.withOpacity(0.04),
        blurRadius: 60,
        spreadRadius: 0,
      ),
    ];
  }

  static List<BoxShadow> cardShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
