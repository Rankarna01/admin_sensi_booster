import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BaseLayout extends StatelessWidget {
  final Widget child;

  const BaseLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background: softer dot grid + ambient green glow
          Positioned.fill(
            child: CustomPaint(
              painter: _SoftGridPainter(),
            ),
          ),
          // Ambient green glow di pojok atas-kanan
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.neonGreen.withOpacity(0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          // Ambient green glow di pojok bawah-kiri
          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.neonGreen.withOpacity(0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          // Konten Utama
          SafeArea(child: child),
        ],
      ),
    );
  }
}

/// Softer, more subtle dot grid pattern
class _SoftGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.04)
      ..strokeWidth = 1.2;

    const double spacing = 32.0;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Exported GridPainter for backward compatibility (used in admin dashboard)
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.035)
      ..strokeWidth = 1.2;

    const double spacing = 28.0;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
