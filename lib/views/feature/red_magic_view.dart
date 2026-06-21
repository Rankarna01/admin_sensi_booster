import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';

class RedMagicView extends ConsumerStatefulWidget {
  const RedMagicView({super.key});

  @override
  ConsumerState<RedMagicView> createState() => _RedMagicViewState();
}

class _RedMagicViewState extends ConsumerState<RedMagicView> with TickerProviderStateMixin {
  static const MethodChannel _gameChannel   = MethodChannel('com.mfw.sensi_booster/game');
  static const MethodChannel _cornerChannel = MethodChannel('com.mfw.sensi_booster/redmagic_corner');

  List<Map<String, dynamic>> _games = [];
  bool _isLoading   = true;
  int  _currentIndex = 0;
  bool _isLaunching  = false;
  bool _cornerActive = false;

  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    // Force Landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _loadGames();
  }

  @override
  void dispose() {
    _stopCorner();
    _scanController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ─── Load saved games ───────────────────────────────────
  Future<void> _loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('saved_games');

    if (savedData != null) {
      final List<dynamic> decoded = jsonDecode(savedData);
      _games = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    if (_games.isEmpty) {
      try {
        final List<dynamic>? result =
            await _gameChannel.invokeMethod('getInstalledGames');
        if (result != null) {
          _games = result.map((e) => Map<String, dynamic>.from(e)).toList();
          _games.sort((a, b) =>
              (a['name'] as String).compareTo(b['name'] as String));
        }
      } catch (e) {
        debugPrint('Error loading games: $e');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ─── Native Corner Service ───────────────────────────────
  Future<void> _startCorner(Map<String, dynamic> features) async {
    // Build comma-separated list of allowed feature keys
    final allowed = features.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .join(',');
    try {
      // Check overlay permission first
      final bool hasPerm =
          await _cornerChannel.invokeMethod('checkOverlayPermission') ?? false;
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin Overlay dibutuhkan. Berikan izin lalu coba lagi.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        await _cornerChannel.invokeMethod('checkOverlayPermission');
        return;
      }
      final bool started = await _cornerChannel.invokeMethod('startCorner', {
        'allowedFeatures': allowed,
      }) ?? false;
      if (started && mounted) setState(() => _cornerActive = true);
    } catch (e) {
      debugPrint('Corner start error: $e');
    }
  }

  Future<void> _stopCorner() async {
    try {
      await _cornerChannel.invokeMethod('stopCorner');
    } catch (_) {}
    if (mounted) setState(() => _cornerActive = false);
  }

  // ─── Launch game + show native corner ───────────────────
  Future<void> _launchGame(
      String packageName, Map<String, dynamic> features) async {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);

    // 1. Start native corner BEFORE launching game
    await _startCorner(features);

    await Future.delayed(const Duration(milliseconds: 600));

    // 2. Launch game (Flutter goes to background)
    try {
      final bool launched = await _gameChannel.invokeMethod('launchGame', {
        'packageName': packageName,
      }) ?? false;

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka game.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLaunching = false);
  }

  // ─── Time format helper ──────────────────────────────────
  String _formatInfo(int index) {
    final int totalMinutes = (index + 1) * 350 + (index * 5000);
    String timeStr;
    if (totalMinutes < 60) {
      timeStr = '${totalMinutes}m';
    } else {
      final int hours = totalMinutes ~/ 60;
      if (hours < 24) {
        timeStr = '${hours}h';
      } else {
        final int days = hours ~/ 24;
        final int rem  = hours % 24;
        timeStr = '${days}d ${rem > 0 ? '${rem}h' : ''}';
      }
    }
    final double sizeGB = (1.2 + index * 2.3).clamp(0, 50);
    return '$timeStr  •  ${sizeGB.toStringAsFixed(2)} GB';
  }

  // ─── Add game bottom sheet ───────────────────────────────
  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0000).withOpacity(0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text('Tambah Game',
                style: GoogleFonts.orbitron(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Pergi ke tab Game Space → Tambah game ke daftar.',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pkgAsync = ref.watch(currentPackageProvider);
    final Map<String, dynamic>? selectedGame =
        _games.isNotEmpty ? _games[_currentIndex] : null;

    return pkgAsync.when(
      data: (pkg) {
        final features = pkg?.features ?? {};
        return _buildScaffold(context, selectedGame, features);
      },
      loading: () => _buildScaffold(context, selectedGame, {}),
      error: (_, __) => _buildScaffold(context, selectedGame, {}),
    );
  }

  Widget _buildScaffold(BuildContext context,
      Map<String, dynamic>? selectedGame, Map<String, dynamic> features) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Background image ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/redmagic.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFF3A0000), Colors.black],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ──
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          else if (_games.isEmpty)
            Center(
              child: Text(
                'TIDAK ADA GAME TERDETEKSI',
                style: GoogleFonts.orbitron(
                    color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          else
            SafeArea(
              child: Row(
                children: [
                  // ─ Left Panel: game list ─
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 64, 8, 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _games.length + 1,
                      itemBuilder: (ctx, i) {
                        // + Add button
                        if (i == _games.length) {
                          return GestureDetector(
                            onTap: _showAddSheet,
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Icon(Icons.add, color: Colors.white70, size: 28),
                            ),
                          );
                        }

                        final game       = _games[i];
                        final isSelected = i == _currentIndex;

                        return GestureDetector(
                          onTap: () => setState(() => _currentIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: isSelected
                                ? const EdgeInsets.all(7)
                                : EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.black.withOpacity(0.45)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                // Icon
                                FutureBuilder<AppInfo?>(
                                  future: InstalledApps.getAppInfo(game['package']),
                                  builder: (_, snap) {
                                    Widget img;
                                    if (snap.hasData && snap.data?.icon != null) {
                                      img = Image.memory(snap.data!.icon!, fit: BoxFit.cover);
                                    } else {
                                      img = const Icon(Icons.videogame_asset, color: Colors.white54, size: 28);
                                    }
                                    return Container(
                                      width:  isSelected ? 62 : 52,
                                      height: isSelected ? 62 : 52,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.redAccent
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                        boxShadow: isSelected
                                            ? [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 10)]
                                            : [],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: img,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        game['name'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSelected ? 14 : 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatInfo(i),
                                          style: const TextStyle(
                                              color: Colors.white54, fontSize: 9),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ─ Right Panel: selected game details ─
                  Expanded(
                    child: Stack(
                      children: [
                        if (selectedGame != null)
                          Positioned(
                            bottom: 40,
                            right: 36,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Game name
                                Text(
                                  selectedGame['name'].toString().toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black.withOpacity(0.6),
                                          blurRadius: 6),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Buttons row
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // START GAME
                                    GestureDetector(
                                      onTap: () => _launchGame(
                                          selectedGame['package'], features),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        height: 48,
                                        padding: const EdgeInsets.symmetric(horizontal: 22),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF5A0000), Color(0xFF8A0000)],
                                          ),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                              color: Colors.redAccent.withOpacity(0.5)),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.red.withOpacity(0.25),
                                                blurRadius: 12,
                                                spreadRadius: 1),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons.keyboard_double_arrow_right_rounded,
                                                color: Colors.white54,
                                                size: 16),
                                            const SizedBox(width: 12),
                                            _isLaunching
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2),
                                                  )
                                                : Text(
                                                    'Start Game',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                            const SizedBox(width: 12),
                                            const Icon(
                                                Icons.keyboard_double_arrow_left_rounded,
                                                color: Colors.white54,
                                                size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Corner toggle button
                                    GestureDetector(
                                      onTap: () => _cornerActive
                                          ? _stopCorner()
                                          : _startCorner(features),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _cornerActive
                                              ? Colors.red.withOpacity(0.25)
                                              : Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                              color: _cornerActive
                                                  ? Colors.redAccent
                                                  : Colors.redAccent.withOpacity(0.3)),
                                        ),
                                        child: Center(
                                          child: Image.asset(
                                            'assets/images/logo.png',
                                            width: 28,
                                            height: 28,
                                            errorBuilder: (_, __, ___) => const Icon(
                                                Icons.sports_esports,
                                                color: Colors.redAccent,
                                                size: 22),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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

          // ── Back button ──
          Positioned(
            top: 0,
            left: 0,
            child: Builder(
              builder: (ctx) {
                final topPad  = MediaQuery.of(ctx).padding.top;
                final leftPad = MediaQuery.of(ctx).padding.left;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: EdgeInsets.only(
                      top:  topPad  + 12,
                      left: leftPad + 12,
                    ),
                    width: 44,
                    height: 44,
                    color: Colors.transparent, // kotak transparan tanpa shadow/lingkaran
                    child: const Center(
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Corner active badge ──
          if (_cornerActive)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.radio_button_checked, color: Colors.redAccent, size: 10),
                    const SizedBox(width: 5),
                    Text('CORNER ACTIVE',
                        style: GoogleFonts.orbitron(
                            color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
