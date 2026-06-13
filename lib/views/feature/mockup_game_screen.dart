import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import 'game_corner_panel.dart';

class MockupGameScreen extends StatefulWidget {
  final String appName;

  const MockupGameScreen({super.key, required this.appName});

  @override
  State<MockupGameScreen> createState() => _MockupGameScreenState();
}

class _MockupGameScreenState extends State<MockupGameScreen> {
  Offset _floatingButtonPos = const Offset(20, 100);
  bool _isPanelOpen = false;

  @override
  void initState() {
    super.initState();
    // Ensure Landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _togglePanel() {
    setState(() {
      _isPanelOpen = !_isPanelOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          
          Widget content = Stack(
            children: [
              // Simulated Game Background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=2070&auto=format&fit=crop'), // Placeholder Game Background
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Text(
                        "Playing ${widget.appName}...",
                        style: const TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),

              // Exit Button
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("Exit Game", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

              // Floating Edge Button
              if (!_isPanelOpen)
                Positioned(
                  left: _floatingButtonPos.dx,
                  top: _floatingButtonPos.dy,
                  child: Draggable(
                    feedback: _buildFloatingButton(isDragging: true),
                    childWhenDragging: const SizedBox.shrink(),
                    onDragEnd: (details) {
                      setState(() {
                        // Handle rotated coordinates if needed
                        _floatingButtonPos = details.offset;
                      });
                    },
                    child: GestureDetector(
                      onTap: _togglePanel,
                      child: _buildFloatingButton(),
                    ),
                  ),
                ),

              // The ROG Panel Overlay
              if (_isPanelOpen)
                Positioned.fill(
                  child: GameCornerPanel(
                    onClose: _togglePanel,
                  ),
                ),
            ],
          );

          if (isPortrait) {
            // Force Landscape rendering
            return RotatedBox(
              quarterTurns: 1,
              child: content,
            );
          }

          return content;
        },
      ),
    );
  }

  Widget _buildFloatingButton({bool isDragging = false}) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.neonGreen.withOpacity(isDragging ? 0.3 : 1.0), width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.neonGreen.withOpacity(isDragging ? 0.2 : 0.5), blurRadius: 10)
        ]
      ),
      child: const Center(
        child: Icon(Icons.gamepad_outlined, color: AppColors.neonGreen, size: 24),
      ),
    );
  }
}
