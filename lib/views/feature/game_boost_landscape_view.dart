import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

class GameBoostLandscapeView extends StatefulWidget {
  final String appName;
  final String packageName;
  final String durationStr;

  const GameBoostLandscapeView({
    super.key,
    required this.appName,
    required this.packageName,
    required this.durationStr,
  });

  @override
  State<GameBoostLandscapeView> createState() => _GameBoostLandscapeViewState();
}

class _GameBoostLandscapeViewState extends State<GameBoostLandscapeView> with SingleTickerProviderStateMixin {
  bool _isLaunching = false;
  String? _bgImagePath;
  late AnimationController _loadingController;
  static const MethodChannel _overlayChannel = MethodChannel('com.mfw.sensi_booster/overlay');

  List<Map<String, dynamic>> _addedGames = [];
  late Map<String, dynamic> _selectedGame;

  @override
  void initState() {
    super.initState();
    // Force Landscape & Immersive
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _selectedGame = {
      "name": widget.appName,
      "package": widget.packageName,
    };

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadData();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    // Revert to Portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bgImagePath = prefs.getString('game_space_bg');
    });

    final String? savedData = prefs.getString('saved_games');
    if (savedData != null) {
      final List<dynamic> decoded = jsonDecode(savedData);
      setState(() {
        _addedGames = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('game_space_bg', pickedFile.path);
      setState(() {
        _bgImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _deleteBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('game_space_bg');
    setState(() {
      _bgImagePath = null;
    });
  }

  Future<void> _launchGame() async {
    final bool hasPerm = await _overlayChannel.invokeMethod('checkPermission') ?? false;
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Meminta Izin Floating Overlay..."), backgroundColor: Colors.orange)
        );
      }
      await _overlayChannel.invokeMethod('requestPermission');
      return;
    }

    setState(() => _isLaunching = true);

    await Future.delayed(const Duration(seconds: 3));

    await _overlayChannel.invokeMethod('startOverlay', {
      'showRam': true,
      'showBattery': true,
      'showSuhu': true,
      'showClock': true,
    });

    InstalledApps.startApp(_selectedGame['package']);
    
    if (mounted) {
      setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: _bgImagePath != null
                ? ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Transform.translate(
                      offset: const Offset(30, 30), // Geser sedikit ke kanan bawah
                      child: Transform.scale(
                        scale: 1.15, // Di-scale sedikit agar ujungnya tidak kosong setelah digeser
                        child: Image.file(
                          File(_bgImagePath!), 
                          fit: BoxFit.cover,
                          alignment: const Alignment(0.5, 0.5), // Fokus sedikit ke kanan bawah
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0A0F16), Color(0xFF101C26)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
          ),
          
          // 2. Blurred App Logo Overlay (Removed as requested)
          // ...

          // 3. Green Gradient Effect on the right
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.8), // Dark on the left for list readability
                    Colors.black.withOpacity(0.2), 
                    AppColors.neonGreen.withOpacity(0.15), // Green tint on the right
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 4. Main Layout
          SafeArea(
            child: Row(
              children: [
                // LEFT PANEL: Scrollable Game List
                Container(
                  width: MediaQuery.of(context).size.width * 0.35,
                  padding: const EdgeInsets.fromLTRB(20, 20, 10, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text("MFW CENTER", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 20),
                      
                      // Scrollable List (Only Game Names)
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _addedGames.length,
                          itemBuilder: (context, index) {
                            final game = _addedGames[index];
                            final isSelected = game['package'] == _selectedGame['package'];

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedGame = {
                                    "name": game['name'],
                                    "package": game['package'],
                                  };
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.neonGreen.withOpacity(0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.neonGreen.withOpacity(0.5) : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Small HD Icon
                                    FutureBuilder<AppInfo?>(
                                      future: InstalledApps.getAppInfo(game['package']),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData && snapshot.data?.icon != null) {
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.memory(snapshot.data!.icon!, width: 35, height: 35, fit: BoxFit.cover),
                                          );
                                        }
                                        return Container(
                                          width: 35,
                                          height: 35,
                                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.android, color: Colors.white54, size: 20),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    // App Name
                                    Expanded(
                                      child: Text(
                                        game['name'],
                                        style: TextStyle(
                                          color: isSelected ? AppColors.neonGreen : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // RIGHT PANEL: Details & Buttons
                Expanded(
                  child: Stack(
                    children: [
                      // Close Button Top Right
                      Positioned(
                        top: 20,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      
                      // App Details Bottom Right
                      Positioned(
                        bottom: 30,
                        right: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _selectedGame['name'],
                              style: GoogleFonts.orbitron(
                                color: Colors.white, 
                                fontSize: 24, 
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: AppColors.neonGreen.withOpacity(0.5), blurRadius: 10)]
                              ),
                            ),
                            const SizedBox(height: 15),
                            
                            // Start Button
                            GestureDetector(
                              onTap: _launchGame,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B3D2E).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.neonGreen, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(color: AppColors.neonGreen.withOpacity(0.4), blurRadius: 15, spreadRadius: -2)
                                  ]
                                ),
                                child: Text("START GAME", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_bgImagePath != null) ...[
                                  _buildActionBtn(Icons.hide_image, _deleteBackgroundImage, "Hapus Background"),
                                  const SizedBox(width: 15),
                                ],
                                _buildActionBtn(Icons.image, _pickBackgroundImage, "Ganti Background"),
                                const SizedBox(width: 15),
                                _buildActionBtn(Icons.track_changes, () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Crosshair Settings akan segera hadir!")));
                                }, "Crosshair"),
                                const SizedBox(width: 15),
                                _buildActionBtn(Icons.settings, () {
                                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Floating Tools Settings akan segera hadir!")));
                                }, "Floating Tools"),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. Loading Screen Overlay
          if (_isLaunching)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RotationTransition(
                        turns: _loadingController,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.neonGreen, width: 4, style: BorderStyle.solid),
                            boxShadow: [
                              BoxShadow(color: AppColors.neonGreen.withOpacity(0.5), blurRadius: 20)
                            ]
                          ),
                          child: const Icon(Icons.rocket_launch, color: AppColors.neonGreen, size: 40),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text("SYSTEM OPTIMIZATION IN PROGRESS...", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 16, letterSpacing: 2)),
                      const SizedBox(height: 10),
                      const Text("Injecting Performance Modules", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.6),
            border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
            boxShadow: [
               BoxShadow(color: AppColors.neonGreen.withOpacity(0.2), blurRadius: 8)
            ]
          ),
          child: Icon(icon, color: AppColors.neonGreen, size: 18),
        ),
      ),
    );
  }
}
