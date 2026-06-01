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
          // Background Grid Pattern (Titik-titik halus)
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),
          // Konten Utama (Halaman)
          SafeArea(child: child),
        ],
      ),
    );
  }
}

// Logic untuk menggambar titik-titik grid secara otomatis
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03) // Warna titik sangat transparan
      ..strokeWidth = 1.5;

    const double spacing = 30.0; // Jarak antar titik

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}