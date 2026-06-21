import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import 'game_boost_landscape_view.dart';
import 'game_intro_video_view.dart';

class GameLauncherView extends ConsumerStatefulWidget {
  const GameLauncherView({super.key});

  @override
  ConsumerState<GameLauncherView> createState() => _GameLauncherViewState();
}

class _GameLauncherViewState extends ConsumerState<GameLauncherView> {
  static const MethodChannel _gameChannel = MethodChannel('com.mfw.sensi_booster/game');

  List<Map<String, dynamic>> _installedGames = [];
  List<Map<String, dynamic>> _addedGames = [];
  bool _isLoading = true;
  bool _scanningGames = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadAddedGames();
    await _scanInstalledGames();
    setState(() => _isLoading = false);
  }

  Future<void> _loadAddedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('saved_games');
    if (savedData != null) {
      final List<dynamic> decoded = jsonDecode(savedData);
      _addedGames = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  Future<void> _saveAddedGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_games', jsonEncode(_addedGames));
  }

  Future<void> _scanInstalledGames() async {
    setState(() => _scanningGames = true);
    try {
      final List<dynamic>? result = await _gameChannel.invokeMethod('getInstalledGames');
      if (result != null) {
        _installedGames = result
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _installedGames.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      }
    } catch (e) {
      debugPrint("getInstalledGames error: $e");
    }
    setState(() => _scanningGames = false);
  }

  void _addGame(Map<String, dynamic> game) {
    if (!_addedGames.any((g) => g['package'] == game['package'])) {
      setState(() {
        _addedGames.add({"name": game['name'], "package": game['package']});
      });
      _saveAddedGames();
    }
  }

  void _removeGame(int index) {
    setState(() => _addedGames.removeAt(index));
    _saveAddedGames();
  }

  // Feature definitions with icons and keys
  static const List<Map<String, dynamic>> _featureDefs = [
    {'key': 'floating_game', 'icon': FontAwesomeIcons.layerGroup, 'label': 'Floating'},
    {'key': 'crosshair', 'icon': FontAwesomeIcons.crosshairs, 'label': 'Crosshair'},
    {'key': 'cpu_tweak', 'icon': FontAwesomeIcons.microchip, 'label': 'CPU'},
    {'key': 'graphics_tweak', 'icon': FontAwesomeIcons.cogs, 'label': 'GPU'},
    {'key': 'latency_mode', 'icon': FontAwesomeIcons.wifi, 'label': 'Latency'},
    {'key': 'speed_test', 'icon': FontAwesomeIcons.tachometerAlt, 'label': 'Speed'},
    {'key': 'auto_clicker', 'icon': FontAwesomeIcons.bolt, 'label': 'Auto'},
    {'key': 'rog_monitor', 'icon': FontAwesomeIcons.chartBar, 'label': 'Monitor'},
  ];

  @override
  Widget build(BuildContext context) {
    final pkgAsync = ref.watch(currentPackageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text("GAME SPACE", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        actions: [
          if (_scanningGames)
            const Padding(
              padding: EdgeInsets.only(right: 15),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonGreen),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.neonGreen),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.neonGreen, size: 20),
                onPressed: _scanInstalledGames,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
          : Column(
              children: [
                // Added games section
                if (_addedGames.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "MY GAMES (${_addedGames.length})",
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      itemCount: _addedGames.length,
                      itemBuilder: (context, index) {
                        final game = _addedGames[index];
                        return _buildGameCard(game, index, pkgAsync);
                      },
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                ],

                // Available installed games section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
                        child: Text(
                          "INSTALLED GAMES (${_installedGames.length})",
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                        ),
                      ),
                      Expanded(
                        child: _installedGames.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.videogame_asset_off, color: AppColors.textMuted, size: 48),
                                    const SizedBox(height: 12),
                                    Text("Tidak ada game terdeteksi", style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                                    const SizedBox(height: 8),
                                    Text("Pastikan game sudah terinstall", style: TextStyle(color: AppColors.textMuted.withOpacity(0.5), fontSize: 12)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                itemCount: _installedGames.length,
                                itemBuilder: (context, index) {
                                  final game = _installedGames[index];
                                  final isAdded = _addedGames.any((g) => g['package'] == game['package']);
                                  return _buildInstalledGameTile(game, isAdded, pkgAsync);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game, int index, AsyncValue pkgAsync) {
    return GestureDetector(
      onTap: () => _navigateToBoostLandscape(game['name'], game['package']),
      onLongPress: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text("Hapus Game?", style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 14)),
            content: Text("Hapus ${game['name']} dari daftar?", style: const TextStyle(color: AppColors.textMuted)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: AppColors.textMuted))),
              TextButton(onPressed: () { _removeGame(index); Navigator.pop(ctx); }, child: const Text("Hapus", style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: AppColors.neonGreen.withOpacity(0.1), blurRadius: 15, spreadRadius: -5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game icon
            FutureBuilder<AppInfo?>(
              future: InstalledApps.getAppInfo(game['package']),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data?.icon != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(snapshot.data!.icon!, width: 42, height: 42, fit: BoxFit.cover),
                  );
                }
                return Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.videogame_asset, color: AppColors.textMuted, size: 22),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              game['name'],
              style: const TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(flex: 1),
            // Feature icons row
            _buildFeatureIcons(pkgAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildInstalledGameTile(Map<String, dynamic> game, bool isAdded, AsyncValue pkgAsync) {
    final String pkgName = game['package'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAdded ? AppColors.neonGreen.withOpacity(0.3) : Colors.white10),
      ),
      child: Row(
        children: [
          // Game icon
          FutureBuilder<AppInfo?>(
            future: InstalledApps.getAppInfo(pkgName),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data?.icon != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(snapshot.data!.icon!, width: 40, height: 40, fit: BoxFit.cover),
                );
              }
              return Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.videogame_asset, color: AppColors.textMuted, size: 20),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game['name'],
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(pkgName, style: const TextStyle(color: AppColors.textMuted, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (isAdded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
              ),
              child: const Text("ADDED", style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          else
            GestureDetector(
              onTap: () => _addGame(game),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
                ),
                child: const Icon(Icons.add, color: AppColors.neonGreen, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcons(AsyncValue pkgAsync) {
    return pkgAsync.when(
      data: (pkg) {
        final features = pkg?.features ?? {};
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: _featureDefs.take(5).map((def) {
            final bool isAllowed = features[def['key']] == true;
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAllowed
                      ? AppColors.neonGreen.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: isAllowed
                        ? AppColors.neonGreen.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                    width: 0.8,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FaIcon(
                      def['icon'] as FaIconData,
                      color: isAllowed ? AppColors.neonGreen : AppColors.textMuted.withOpacity(0.4),
                      size: 8,
                    ),
                    if (!isAllowed)
                      const FaIcon(FontAwesomeIcons.lock, color: Colors.white24, size: 5),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _navigateToBoostLandscape(String name, String packageName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameIntroVideoView(
          appName: name,
          packageName: packageName,
        ),
      ),
    );
  }
}
