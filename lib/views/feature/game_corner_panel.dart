import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class GameCornerPanel extends StatefulWidget {
  final VoidCallback onClose;

  const GameCornerPanel({super.key, required this.onClose});

  @override
  State<GameCornerPanel> createState() => _GameCornerPanelState();
}

class _GameCornerPanelState extends State<GameCornerPanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideUpAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Entire Panel: Slides up from bottom
    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closePanel() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;
    final screenWidth = isPortrait ? size.height : size.width;
    final screenHeight = isPortrait ? size.width : size.height;

    final panelWidth = screenWidth * 0.95;
    final panelHeight = screenHeight * 0.40; 

    // The FULL UI Stack
    Widget fullUI = SizedBox(
      width: panelWidth,
      height: panelHeight,
      child: Stack(
        children: [
          // Background Painter
          Positioned.fill(
            child: CustomPaint(
              painter: GameCornerPainter(cpuLevel: 4, ramLevel: 5), // Simulated dynamic levels
            ),
          ),

          // --- HEADER CONTENT ---
          Positioned(
            top: panelHeight * 0.05,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "ADVANCED",
                style: GoogleFonts.orbitron(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),

          // --- CENTER HUB CONTENT ---
          Positioned(
            top: panelHeight * 0.40,
            left: panelWidth * 0.35,
            right: panelWidth * 0.35,
            child: Column(
              children: [
                Text(
                  "AXERON",
                  style: GoogleFonts.inter(
                    color: AppColors.neonGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "GAME CORNER",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _closePanel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neonGreen.withAlpha(100)),
                    ),
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.neonGreen, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // --- LEFT WING CONTENT ---
          Positioned(
            left: panelWidth * 0.10, 
            top: panelHeight * 0.25, 
            bottom: 0, 
            width: panelWidth * 0.28, 
            child: Row(
              children: [
                // CPU Text
                Text(
                  "CPU",
                  style: GoogleFonts.orbitron(
                    color: AppColors.neonGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                // Grid of features
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTechBtn(Icons.speed, "Speed"),
                          _buildTechBtn(Icons.wifi, "Latency"),
                          _buildTechBtn(Icons.track_changes, "Crosshair"),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTechBtn(Icons.memory, "CPU Tweak"),
                          _buildTechBtn(Icons.developer_board, "GPU Boost"),
                          _buildTechBtn(Icons.cleaning_services, "Clean RAM"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- RIGHT WING CONTENT ---
          Positioned(
            right: panelWidth * 0.10, 
            top: panelHeight * 0.25,
            bottom: 0,
            width: panelWidth * 0.28,
            child: Row(
              children: [
                // Grid of features
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTechBtn(Icons.phone_disabled, "Block Call"),
                          _buildTechBtn(Icons.do_not_disturb_on, "DND"),
                          _buildTechBtn(Icons.videocam, "Record"),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTechBtn(Icons.camera_alt, "Screenshot"),
                          _buildTechBtn(Icons.layers, "Floating"),
                          _buildTechBtn(Icons.brightness_high, "Display"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // RAM Text
                Text(
                  "RAM",
                  style: GoogleFonts.orbitron(
                    color: AppColors.neonGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        // Darken background overlay
        GestureDetector(
          onTap: _closePanel,
          child: Container(
            color: Colors.black.withAlpha(120),
          ),
        ),
        
        // Assembled HUD
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: panelWidth,
            height: panelHeight,
            margin: const EdgeInsets.only(bottom: 10),
            child: SlideTransition(
              position: _slideUpAnimation,
              child: fullUI,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechBtn(IconData icon, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(150), width: 1.2),
              color: Colors.white.withAlpha(15), 
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 15),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class GameCornerPainter extends CustomPainter {
  final int cpuLevel;
  final int ramLevel;

  GameCornerPainter({required this.cpuLevel, required this.ramLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    // The top of the wings is flat across the whole panel until ADVANCED
    final wingTop = h * 0.25; 
    final double radius = 20.0; // More pronounced rounded bottom corners

    final path = Path();
    // Bottom Left Corner
    path.moveTo(w * 0.04 + radius, h);
    path.quadraticBezierTo(w * 0.04, h, w * 0.04 + 2, h - radius);
    
    // Slant up-right to wing top
    path.lineTo(w * 0.12, wingTop);
    
    // Flat across the left wing and hub
    path.lineTo(w * 0.40, wingTop);
    
    // Slant UP to ADVANCED
    path.lineTo(w * 0.43, 0);
    // Flat top of ADVANCED
    path.lineTo(w * 0.57, 0);
    // Slant DOWN from ADVANCED
    path.lineTo(w * 0.60, wingTop);
    
    // Flat across the right wing
    path.lineTo(w * 0.88, wingTop);
    
    // Slant down-right to bottom right
    path.lineTo(w * 0.96 - 2, h - radius);
    path.quadraticBezierTo(w * 0.96, h, w * 0.96 - radius, h);
    path.close();

    // Dark Background Fill
    final paintFill = Paint()
      ..color = const Color(0xFF070B0A).withAlpha(245)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paintFill);

    // Glowing Neon Green Stroke
    final paintStrokeGlow = Paint()
      ..color = AppColors.neonGreen.withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, paintStrokeGlow);

    // Solid Neon Green Border
    final paintStroke = Paint()
      ..color = AppColors.neonGreen.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(path, paintStroke);

    // --- "ADVANCED" Header Fill ---
    // Fill the raised bump with solid neon green
    final headerPath = Path();
    headerPath.moveTo(w * 0.40, wingTop);
    headerPath.lineTo(w * 0.43, 0);
    headerPath.lineTo(w * 0.57, 0);
    headerPath.lineTo(w * 0.60, wingTop);
    headerPath.close();

    final headerFill = Paint()
      ..color = AppColors.neonGreen
      ..style = PaintingStyle.fill;
    canvas.drawPath(headerPath, headerFill);

    // --- Dynamic CPU & RAM Battery Blocks ---
    final edgeHeight = h - wingTop;
    final numBlocks = 6;
    final blockHeight = (edgeHeight / numBlocks) - 3.0; // 3px vertical gap
    final blockWidth = w * 0.035;

    // Draw Left (CPU) Blocks
    for (int i = 0; i < numBlocks; i++) {
      final yBottom = h - i * (edgeHeight / numBlocks) - 1.5;
      final yTop = yBottom - blockHeight;

      final tBottom = (yBottom - wingTop) / edgeHeight;
      final tTop = (yTop - wingTop) / edgeHeight;

      final xLeftBottom = w * (0.12 - 0.08 * tBottom);
      final xLeftTop = w * (0.12 - 0.08 * tTop);

      final blockPath = Path();
      blockPath.moveTo(xLeftBottom, yBottom);
      blockPath.lineTo(xLeftTop, yTop);
      blockPath.lineTo(xLeftTop + blockWidth, yTop);
      blockPath.lineTo(xLeftBottom + blockWidth, yBottom);
      blockPath.close();

      final paint = Paint()
        ..color = AppColors.neonGreen.withAlpha(i < cpuLevel ? 255 : 40)
        ..style = PaintingStyle.fill;
      canvas.drawPath(blockPath, paint);
    }

    // Draw Right (RAM) Blocks
    for (int i = 0; i < numBlocks; i++) {
      final yBottom = h - i * (edgeHeight / numBlocks) - 1.5;
      final yTop = yBottom - blockHeight;

      final tBottom = (yBottom - wingTop) / edgeHeight;
      final tTop = (yTop - wingTop) / edgeHeight;

      final xRightBottom = w * (0.88 + 0.08 * tBottom);
      final xRightTop = w * (0.88 + 0.08 * tTop);

      final blockPath = Path();
      blockPath.moveTo(xRightBottom, yBottom);
      blockPath.lineTo(xRightTop, yTop);
      blockPath.lineTo(xRightTop - blockWidth, yTop);
      blockPath.lineTo(xRightBottom - blockWidth, yBottom);
      blockPath.close();

      final paint = Paint()
        ..color = AppColors.neonGreen.withAlpha(i < ramLevel ? 255 : 40)
        ..style = PaintingStyle.fill;
      canvas.drawPath(blockPath, paint);
    }

    // --- Center Hub Dynamic Brackets & Lines ---
    final bracketPaint = Paint()
      ..color = AppColors.neonGreen.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Left bracket `/` flanking the text
    canvas.drawLine(Offset(w * 0.39, h * 0.7), Offset(w * 0.42, h * 0.45), bracketPaint);
    // Right bracket `\` flanking the text
    canvas.drawLine(Offset(w * 0.61, h * 0.45), Offset(w * 0.64, h * 0.7), bracketPaint);

    // Subtle line separating center hub from wings
    final dividerPaint = Paint()
      ..color = AppColors.neonGreen.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    canvas.drawLine(Offset(w * 0.35, wingTop), Offset(w * 0.32, h * 0.9), dividerPaint);
    canvas.drawLine(Offset(w * 0.65, wingTop), Offset(w * 0.68, h * 0.9), dividerPaint);
  }

  @override
  bool shouldRepaint(covariant GameCornerPainter oldDelegate) {
    return oldDelegate.cpuLevel != cpuLevel || oldDelegate.ramLevel != ramLevel;
  }
}
