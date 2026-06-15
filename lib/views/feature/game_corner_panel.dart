import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';

class GameCornerPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Map<String, dynamic> features;

  const GameCornerPanel({super.key, required this.onClose, this.features = const {}});

  @override
  State<GameCornerPanel> createState() => _GameCornerPanelState();
}

class _GameCornerPanelState extends State<GameCornerPanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideUpAnimation;
  Timer? _animTimer;
  final Random _rng = Random();

  int _cpuLevel = 3;
  int _ramLevel = 4;
  bool _isTouching = false;

  // Feature definitions matching the panel buttons
  static const List<Map<String, dynamic>> _leftFeatures = [
    {'key': 'speed_test', 'icon': FontAwesomeIcons.tachometerAlt, 'label': 'Speed'},
    {'key': 'latency_mode', 'icon': FontAwesomeIcons.wifi, 'label': 'Latency'},
    {'key': 'crosshair', 'icon': FontAwesomeIcons.crosshairs, 'label': 'Crosshair'},
    {'key': 'cpu_tweak', 'icon': FontAwesomeIcons.microchip, 'label': 'CPU Tweak'},
    {'key': 'graphics_tweak', 'icon': FontAwesomeIcons.cogs, 'label': 'GPU Boost'},
    {'key': 'rog_monitor', 'icon': FontAwesomeIcons.chartBar, 'label': 'Clean RAM'},
  ];

  static const List<Map<String, dynamic>> _rightFeatures = [
    {'key': 'floating_game', 'icon': FontAwesomeIcons.layerGroup, 'label': 'Floating'},
    {'key': 'auto_clicker', 'icon': FontAwesomeIcons.bolt, 'label': 'Auto Click'},
    {'key': 'set_dpi', 'icon': FontAwesomeIcons.expandArrowsAlt, 'label': 'Set DPI'},
    {'key': 'game_lab_sensi', 'icon': FontAwesomeIcons.gamepad, 'label': 'Sensi'},
    {'key': 'crosshair', 'icon': FontAwesomeIcons.bullseye, 'label': 'Aim'},
    {'key': 'speed_test', 'icon': FontAwesomeIcons.bolt, 'label': 'Turbo'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Start ambient animation
    _startAmbientAnimation();
  }

  void _startAmbientAnimation() {
    _animTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      setState(() {
        if (_isTouching) {
          // More aggressive animation when touched
          _cpuLevel = _rng.nextInt(3) + 4; // 4-6
          _ramLevel = _rng.nextInt(3) + 4; // 4-6
        } else {
          // Subtle ambient animation
          _cpuLevel = _rng.nextInt(3) + 2; // 2-4
          _ramLevel = _rng.nextInt(3) + 3; // 3-5
        }
      });
    });
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _closePanel() async {
    _animTimer?.cancel();
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

    Widget fullUI = GestureDetector(
      onTapDown: (_) => setState(() => _isTouching = true),
      onTapUp: (_) => setState(() => _isTouching = false),
      onTapCancel: () => setState(() => _isTouching = false),
      child: SizedBox(
        width: panelWidth,
        height: panelHeight,
        child: Stack(
          children: [
            // Background Painter with animated levels
            Positioned.fill(
              child: CustomPaint(
                painter: GameCornerPainter(
                  cpuLevel: _cpuLevel,
                  ramLevel: _ramLevel,
                  glowIntensity: _isTouching ? 1.0 : 0.5,
                ),
              ),
            ),

            // HEADER
            Positioned(
              top: panelHeight * 0.05,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "ADVANCED",
                  style: GoogleFonts.orbitron(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                ),
              ),
            ),

            // CENTER HUB
            Positioned(
              top: panelHeight * 0.40,
              left: panelWidth * 0.35,
              right: panelWidth * 0.35,
              child: Column(
                children: [
                  Text(
                    "ROG THEME",
                    style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 3.0),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "MFW SENSI",
                    style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
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

            // LEFT WING - Features
            Positioned(
              left: panelWidth * 0.10,
              top: panelHeight * 0.25,
              bottom: 0,
              width: panelWidth * 0.28,
              child: Row(
                children: [
                  Text("CPU", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _leftFeatures.take(3).map((f) => _buildTechBtn(f)).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _leftFeatures.skip(3).take(3).map((f) => _buildTechBtn(f)).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // RIGHT WING - Features
            Positioned(
              right: panelWidth * 0.10,
              top: panelHeight * 0.25,
              bottom: 0,
              width: panelWidth * 0.28,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _rightFeatures.take(3).map((f) => _buildTechBtn(f)).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _rightFeatures.skip(3).take(3).map((f) => _buildTechBtn(f)).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text("RAM", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      children: [
        GestureDetector(
          onTap: _closePanel,
          child: Container(color: Colors.black.withAlpha(120)),
        ),
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

  Widget _buildTechBtn(Map<String, dynamic> featureDef) {
    final String key = featureDef['key'] as String;
    final bool isAllowed = widget.features[key] == true;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isAllowed
                    ? (_isTouching ? AppColors.neonGreen : Colors.white.withAlpha(150))
                    : Colors.white.withAlpha(40),
                width: 1.2,
              ),
              color: isAllowed
                  ? (_isTouching ? AppColors.neonGreen.withOpacity(0.2) : Colors.white.withAlpha(15))
                  : Colors.white.withAlpha(5),
              boxShadow: isAllowed && _isTouching
                  ? [BoxShadow(color: AppColors.neonGreen.withOpacity(0.3), blurRadius: 8)]
                  : null,
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FaIcon(
                    featureDef['icon'] as FaIconData,
                    color: isAllowed ? Colors.white : Colors.white.withOpacity(0.2),
                    size: 13,
                  ),
                  if (!isAllowed)
                    FaIcon(FontAwesomeIcons.lock, color: Colors.white.withOpacity(0.3), size: 7),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            featureDef['label'] as String,
            style: GoogleFonts.inter(
              color: isAllowed ? Colors.white : Colors.white.withOpacity(0.25),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
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
  final double glowIntensity;

  GameCornerPainter({
    required this.cpuLevel,
    required this.ramLevel,
    this.glowIntensity = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wingTop = h * 0.25;
    final double radius = 20.0;

    final path = Path();
    path.moveTo(w * 0.04 + radius, h);
    path.quadraticBezierTo(w * 0.04, h, w * 0.04 + 2, h - radius);
    path.lineTo(w * 0.12, wingTop);
    path.lineTo(w * 0.40, wingTop);
    path.lineTo(w * 0.43, 0);
    path.lineTo(w * 0.57, 0);
    path.lineTo(w * 0.60, wingTop);
    path.lineTo(w * 0.88, wingTop);
    path.lineTo(w * 0.96 - 2, h - radius);
    path.quadraticBezierTo(w * 0.96, h, w * 0.96 - radius, h);
    path.close();

    // Dark Background Fill
    final paintFill = Paint()
      ..color = const Color(0xFF070B0A).withAlpha(245)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paintFill);

    // Glowing Neon Green Stroke (dynamic intensity)
    final glowAlpha = (90 * glowIntensity).toInt().clamp(0, 255);
    final paintStrokeGlow = Paint()
      ..color = AppColors.neonGreen.withAlpha(glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * glowIntensity
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, paintStrokeGlow);

    // Solid border
    final strokeAlpha = (200 * glowIntensity).toInt().clamp(100, 255);
    final paintStroke = Paint()
      ..color = AppColors.neonGreen.withAlpha(strokeAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(path, paintStroke);

    // ADVANCED header fill
    final headerPath = Path();
    headerPath.moveTo(w * 0.40, wingTop);
    headerPath.lineTo(w * 0.43, 0);
    headerPath.lineTo(w * 0.57, 0);
    headerPath.lineTo(w * 0.60, wingTop);
    headerPath.close();

    final headerFill = Paint()..color = AppColors.neonGreen..style = PaintingStyle.fill;
    canvas.drawPath(headerPath, headerFill);

    // Dynamic CPU & RAM blocks
    final edgeHeight = h - wingTop;
    final numBlocks = 6;
    final blockHeight = (edgeHeight / numBlocks) - 3.0;
    final blockWidth = w * 0.035;

    // CPU Blocks (Left)
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

      final isActive = i < cpuLevel;
      final blockAlpha = isActive ? (255 * glowIntensity).toInt().clamp(150, 255) : 40;
      final paint = Paint()
        ..color = AppColors.neonGreen.withAlpha(blockAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawPath(blockPath, paint);

      // Add glow for active blocks
      if (isActive && glowIntensity > 0.7) {
        final glowPaint = Paint()
          ..color = AppColors.neonGreen.withAlpha(30)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(blockPath, glowPaint);
      }
    }

    // RAM Blocks (Right)
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

      final isActive = i < ramLevel;
      final blockAlpha = isActive ? (255 * glowIntensity).toInt().clamp(150, 255) : 40;
      final paint = Paint()
        ..color = AppColors.neonGreen.withAlpha(blockAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawPath(blockPath, paint);

      if (isActive && glowIntensity > 0.7) {
        final glowPaint = Paint()
          ..color = AppColors.neonGreen.withAlpha(30)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(blockPath, glowPaint);
      }
    }

    // Center brackets
    final bracketAlpha = (180 * glowIntensity).toInt().clamp(100, 255);
    final bracketPaint = Paint()
      ..color = AppColors.neonGreen.withAlpha(bracketAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(w * 0.39, h * 0.7), Offset(w * 0.42, h * 0.45), bracketPaint);
    canvas.drawLine(Offset(w * 0.61, h * 0.45), Offset(w * 0.64, h * 0.7), bracketPaint);

    // Dividers
    final dividerAlpha = (50 * glowIntensity).toInt().clamp(20, 100);
    final dividerPaint = Paint()
      ..color = AppColors.neonGreen.withAlpha(dividerAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(w * 0.35, wingTop), Offset(w * 0.32, h * 0.9), dividerPaint);
    canvas.drawLine(Offset(w * 0.65, wingTop), Offset(w * 0.68, h * 0.9), dividerPaint);
  }

  @override
  bool shouldRepaint(covariant GameCornerPainter oldDelegate) {
    return oldDelegate.cpuLevel != cpuLevel ||
        oldDelegate.ramLevel != ramLevel ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}
