import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class RogDashboardPanel extends StatefulWidget {
  final VoidCallback onClose;

  const RogDashboardPanel({super.key, required this.onClose});

  @override
  State<RogDashboardPanel> createState() => _RogDashboardPanelState();
}

class _RogDashboardPanelState extends State<RogDashboardPanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _expandLeftAnimation;
  late Animation<double> _expandRightAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Slide in from bottom
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Staggered fade in for contents
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      )
    );

    // Staggered slide out for left wing
    _expandLeftAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      )
    );

    // Staggered slide out for right wing
    _expandRightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      )
    );

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
    // Determine size to guarantee landscape dimensions
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;
    final screenWidth = isPortrait ? size.height : size.width;
    final screenHeight = isPortrait ? size.width : size.height;

    // Constrain panel height so it doesn't overflow screenHeight
    final maxPanelHeight = screenHeight * 0.8; 
    double panelWidth = screenWidth * 0.9;
    double panelHeight = panelWidth * (887 / 1774); // Aspect ratio of the image is roughly 2:1

    if (panelHeight > maxPanelHeight) {
      panelHeight = maxPanelHeight;
      panelWidth = panelHeight * (1774 / 887);
    }

    return Stack(
      children: [
        // Darken background slightly
        GestureDetector(
          onTap: _closePanel,
          child: Container(
            color: Colors.black.withOpacity(0.4),
          ),
        ),
        
        // Panel
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: panelWidth,
              height: panelHeight,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/floating-rog.png'),
                  fit: BoxFit.contain,
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        // Mockup Content for Center
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: panelHeight * 0.15),
                            child: Text(
                              "X-MODE ACTIVE",
                              style: GoogleFonts.orbitron(
                                color: AppColors.neonGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: AppColors.neonGreen, blurRadius: 10)],
                              ),
                            ),
                          ),
                        ),
                    
                    // Close Button Area
                    Positioned(
                      top: panelHeight * 0.05,
                      right: panelWidth * 0.25,
                      child: GestureDetector(
                        onTap: _closePanel,
                        child: const Icon(Icons.close, color: AppColors.neonGreen, size: 20),
                      ),
                    ),

                    // Left Wing Content (Metrics) sliding from right to left
                    Positioned(
                      left: panelWidth * 0.05,
                      top: panelHeight * 0.35,
                      bottom: panelHeight * 0.1,
                      width: panelWidth * 0.25, // wider to fit text nicely
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerRight,
                          widthFactor: _expandLeftAnimation.value,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildMetricItem("CPU", "68%"),
                                _buildMetricItem("RAM", "72%"),
                                _buildMetricItem("PING", "24ms"),
                                _buildMetricItem("FPS", "90"),
                                _buildMetricItem("TEMP", "36°C"),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right Wing Content (Buttons) sliding from left to right
                    Positioned(
                      right: panelWidth * 0.05,
                      top: panelHeight * 0.35,
                      bottom: panelHeight * 0.1,
                      width: panelWidth * 0.3, // wider to fit buttons
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: _expandRightAnimation.value,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFeatureBtn(Icons.speed, "SPEED TEST"),
                                _buildFeatureBtn(Icons.wifi, "LATENCY MODE"),
                                _buildFeatureBtn(Icons.track_changes, "CROSSHAIR"),
                                _buildFeatureBtn(Icons.memory, "CPU TWEAK"),
                                _buildFeatureBtn(Icons.layers, "FLOATING GAME"),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  ],
);
  }

  Widget _buildMetricItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFeatureBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 14),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
