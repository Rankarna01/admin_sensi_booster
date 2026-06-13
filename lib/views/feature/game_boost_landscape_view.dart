import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import 'game_corner_panel.dart';

class GameBoostLandscapeView extends ConsumerStatefulWidget {
  final String appName;
  final String packageName;

  const GameBoostLandscapeView({
    super.key,
    required this.appName,
    required this.packageName,
  });

  @override
  ConsumerState<GameBoostLandscapeView> createState() => _GameBoostLandscapeViewState();
}

class _GameBoostLandscapeViewState extends ConsumerState<GameBoostLandscapeView> with SingleTickerProviderStateMixin {
  static const MethodChannel _gameChannel = MethodChannel('com.mfw.sensi_booster/game');
  static const MethodChannel _overlayChannel = MethodChannel('com.mfw.sensi_booster/overlay');

  bool _isLaunching = false;
  double _boostProgress = 0.0;
  String _boostStatus = "";
  bool _showGameCorner = false;
  late AnimationController _loadingController;

  List<Map<String, dynamic>> _addedGames = [];
  late Map<String, dynamic> _selectedGame;

  static const List<Map<String, dynamic>> _featureDefs = [
    {'key': 'floating_game', 'icon': FontAwesomeIcons.layerGroup, 'label': 'Floating'},
    {'key': 'crosshair', 'icon': FontAwesomeIcons.crosshairs, 'label': 'Crosshair'},
    {'key': 'cpu_tweak', 'icon': FontAwesomeIcons.microchip, 'label': 'CPU Tweak'},
    {'key': 'graphics_tweak', 'icon': FontAwesomeIcons.cogs, 'label': 'GPU Boost'},
    {'key': 'latency_mode', 'icon': FontAwesomeIcons.wifi, 'label': 'Low Latency'},
    {'key': 'speed_test', 'icon': FontAwesomeIcons.tachometerAlt, 'label': 'Speed'},
    {'key': 'auto_clicker', 'icon': FontAwesomeIcons.bolt, 'label': 'Auto Click'},
    {'key': 'rog_monitor', 'icon': FontAwesomeIcons.chartBar, 'label': 'ROG Monitor'},
  ];

  final List<String> _boostSteps = [
    "Cleaning RAM...",
    "Optimizing CPU cores...",
    "Boosting GPU clock...",
    "Reducing network latency...",
    "Allocating resources...",
    "Launching game...",
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _selectedGame = {"name": widget.appName, "package": widget.packageName};

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadData();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadData() async {
    final String? savedData = (await SharedPreferences.getInstance()).getString('saved_games');
    if (savedData != null) {
      final List<dynamic> decoded = jsonDecode(savedData);
      setState(() {
        _addedGames = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _launchGame() async {
    if (_isLaunching) return;
    setState(() {
      _isLaunching = true;
      _boostProgress = 0.0;
      _boostStatus = _boostSteps[0];
    });

    // Animate through boost steps
    for (int i = 0; i < _boostSteps.length; i++) {
      if (!mounted) return;
      setState(() => _boostStatus = _boostSteps[i]);

      // Animate progress within this step
      final startProgress = i / _boostSteps.length;
      final endProgress = (i + 1) / _boostSteps.length;
      final stepDuration = Duration(milliseconds: i == _boostSteps.length - 1 ? 300 : 500);

      final startTime = DateTime.now();
      Timer.periodic(const Duration(milliseconds: 30), (timer) {
        if (!mounted) { timer.cancel(); return; }
        final elapsed = DateTime.now().difference(startTime).inMilliseconds / stepDuration.inMilliseconds;
        if (elapsed >= 1.0) {
          timer.cancel();
          return;
        }
        setState(() {
          _boostProgress = startProgress + (endProgress - startProgress) * elapsed;
        });
      });

      await Future.delayed(stepDuration);
    }

    if (!mounted) return;
    setState(() => _boostProgress = 1.0);

    // Launch the real game via native
    try {
      final bool launched = await _gameChannel.invokeMethod('launchGame', {
        'packageName': _selectedGame['package'],
      }) ?? false;

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuka ${_selectedGame['name']}. Pastikan game terinstall.", style: GoogleFonts.inter()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e", style: GoogleFonts.inter()), backgroundColor: Colors.redAccent),
        );
      }
    }

    if (mounted) {
      setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkgAsync = ref.watch(currentPackageProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A0F16), Color(0xFF101C26)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Green gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.2),
                    AppColors.neonGreen.withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Main Layout
          SafeArea(
            child: Row(
              children: [
                // LEFT PANEL: Game List
                Container(
                  width: MediaQuery.of(context).size.width * 0.35,
                  padding: const EdgeInsets.fromLTRB(20, 20, 10, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("MFW CENTER", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 20),
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
                                  _selectedGame = {"name": game['name'], "package": game['package']};
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
                                  ),
                                ),
                                child: Row(
                                  children: [
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
                                          width: 35, height: 35,
                                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.android, color: Colors.white54, size: 20),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
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

                // RIGHT PANEL: Game Details & Launch
                Expanded(
                  child: Stack(
                    children: [
                      // Close Button
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

                      // Game Details
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
                                shadows: [Shadow(color: AppColors.neonGreen.withOpacity(0.5), blurRadius: 10)],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Feature icons based on account type
                            pkgAsync.when(
                              data: (pkg) => _buildFeatureRow(pkg?.features ?? {}),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 20),

                            // Boost progress bar
                            if (_isLaunching) ...[
                              Container(
                                width: 250,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _boostStatus,
                                          style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 10, letterSpacing: 1),
                                        ),
                                        Text(
                                          "${(_boostProgress * 100).toInt()}%",
                                          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: _boostProgress,
                                      backgroundColor: Colors.white10,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonGreen),
                                      minHeight: 3,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                            ],

                            // Start Button
                            GestureDetector(
                              onTap: _isLaunching ? null : _launchGame,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isLaunching
                                      ? AppColors.neonGreen.withOpacity(0.1)
                                      : const Color(0xFF0B3D2E).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.neonGreen, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.neonGreen.withOpacity(_isLaunching ? 0.2 : 0.4),
                                      blurRadius: 15,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _isLaunching ? "BOOSTING..." : "START GAME",
                                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Game Corner Button
                            GestureDetector(
                              onTap: () => setState(() => _showGameCorner = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.gamepad, color: AppColors.neonGreen, size: 16),
                                    const SizedBox(width: 6),
                                    Text("GAME CORNER", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 10, letterSpacing: 1)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading spinner overlay (during initial load only)
          if (_isLaunching)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: RotationTransition(
                      turns: _loadingController,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.neonGreen, width: 3),
                          boxShadow: [BoxShadow(color: AppColors.neonGreen.withOpacity(0.5), blurRadius: 20)],
                        ),
                        child: const Icon(Icons.rocket_launch, color: AppColors.neonGreen, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Game Corner Panel Overlay
          if (_showGameCorner)
            Positioned.fill(
              child: pkgAsync.when(
                data: (pkg) => GameCornerPanel(
                  onClose: () => setState(() => _showGameCorner = false),
                  features: pkg?.features ?? {},
                ),
                loading: () => GameCornerPanel(
                  onClose: () => setState(() => _showGameCorner = false),
                ),
                error: (_, __) => GameCornerPanel(
                  onClose: () => setState(() => _showGameCorner = false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(Map<String, dynamic> features) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: _featureDefs.map((def) {
        final bool isAllowed = features[def['key']] == true;
        return Container(
          margin: const EdgeInsets.only(left: 6),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAllowed ? AppColors.neonGreen.withOpacity(0.15) : Colors.white.withOpacity(0.05),
            border: Border.all(
              color: isAllowed ? AppColors.neonGreen.withOpacity(0.5) : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              FaIcon(
                def['icon'] as FaIconData,
                color: isAllowed ? AppColors.neonGreen : Colors.white24,
                size: 12,
              ),
              if (!isAllowed)
                const FaIcon(FontAwesomeIcons.lock, color: Colors.white24, size: 7),
            ],
          ),
        );
      }).toList(),
    );
  }
}
