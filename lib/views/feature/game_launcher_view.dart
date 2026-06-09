import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:app_usage/app_usage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';

class GameLauncherView extends StatefulWidget {
  const GameLauncherView({super.key});

  @override
  State<GameLauncherView> createState() => _GameLauncherViewState();
}

class _GameLauncherViewState extends State<GameLauncherView> {
  List<Map<String, dynamic>> _addedGames = [];
  Map<String, Duration> _usageStats = {};
  bool _isLoading = true;

  static const MethodChannel _overlayChannel = MethodChannel('com.mfw.sensi_booster/overlay');

  @override
  void initState() {
    super.initState();
    _loadAddedGames();
  }

  Future<void> _loadAddedGames() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('saved_games');
    
    if (savedData != null) {
      final List<dynamic> decoded = jsonDecode(savedData);
      List<Map<String, dynamic>> tempGames = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      
      List<Map<String, dynamic>> validGames = [];
      for (var game in tempGames) {
        try {
          final info = await InstalledApps.getAppInfo(game['package']);
          if (info != null) validGames.add(game);
        } catch (e) {
          // Ignore app not found
        }
      }
      _addedGames = validGames;
      await _saveGames();
    } else {
      _addedGames = [];
      await _saveGames();
    }
    
    await _fetchUsageStats();
    setState(() => _isLoading = false);
  }

  Future<void> _saveGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_games', jsonEncode(_addedGames));
  }

  Future<void> _fetchUsageStats() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(days: 7));
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(startDate, endDate);
      
      Map<String, Duration> stats = {};
      for (var info in infoList) {
        stats[info.packageName] = info.usage;
      }
      setState(() {
        _usageStats = stats;
      });
    } on Exception catch (exception) {
      debugPrint("AppUsage Error: \$exception");
    }
  }

  Future<void> _addGame() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AppSelector(
        onAppSelected: (AppInfo app) async {
          Navigator.pop(context);
          if (!_addedGames.any((g) => g['package'] == app.packageName)) {
            setState(() {
              _addedGames.add({"name": app.name, "package": app.packageName});
            });
            await _saveGames();
          }
        },
      ),
    );
  }

  Future<void> _launchGame(String name, String packageName) async {
    // 1. Cek Permission Overlay
    final bool hasPerm = await _overlayChannel.invokeMethod('checkPermission') ?? false;
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Meminta Izin Floating Overlay..."), backgroundColor: Colors.orange)
        );
      }
      await _overlayChannel.invokeMethod('requestPermission');
      return; // Tunggu user berikan izin dulu
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Memulai Boost untuk \$name...", style: GoogleFonts.orbitron()),
          backgroundColor: AppColors.neonGreen,
        )
      );
    }

    // 2. Tampilkan Overlay
    await _overlayChannel.invokeMethod('startOverlay', {
      'showRam': true,
      'showBattery': true,
      'showSuhu': true,
      'showClock': true,
    });

    // 3. Buka Aplikasi Game
    InstalledApps.startApp(packageName);
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours} Jam ${duration.inMinutes.remainder(60)} Menit";
    }
    return "${duration.inMinutes} Menit";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text("GAME SPACE", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: InkWell(
                onTap: _addGame,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.2),
                    border: Border.all(color: AppColors.neonGreen, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: AppColors.neonGreen, size: 20),
                ),
              ),
            ),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
        : _addedGames.isEmpty 
          ? Center(child: Text("Belum ada game ditambahkan", style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _addedGames.length,
              itemBuilder: (context, index) {
                final game = _addedGames[index];
                final String pkgName = game["package"]!;
                final duration = _usageStats[pkgName];
                final String durationStr = duration != null ? _formatDuration(duration) : "0m (7 Hari Terakhir)";

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      FutureBuilder<AppInfo?>(
                        future: InstalledApps.getAppInfo(pkgName),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return _buildPlaceholderIcon();
                          }
                          if (snapshot.hasData && snapshot.data?.icon != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                snapshot.data!.icon!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return _buildPlaceholderIcon();
                        },
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(game["name"]!, style: const TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: AppColors.neonGreen, size: 14),
                                const SizedBox(width: 4),
                                Text(durationStr, style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _launchGame(game["name"]!, pkgName),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.neonGreen.withOpacity(0.9), AppColors.neonGreen.withOpacity(0.4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.neonGreen, width: 1.5),
                            boxShadow: [
                              BoxShadow(color: AppColors.neonGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                            ]
                          ),
                          child: Text("BOOST", style: GoogleFonts.orbitron(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.videogame_asset, color: AppColors.textMuted),
    );
  }
}

class _AppSelector extends StatefulWidget {
  final Function(AppInfo) onAppSelected;
  const _AppSelector({required this.onAppSelected});

  @override
  State<_AppSelector> createState() => _AppSelectorState();
}

class _AppSelectorState extends State<_AppSelector> {
  List<AppInfo> _apps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    // getInstalledApps(excludeSystemApps, withIcon)
    List<AppInfo> apps = await InstalledApps.getInstalledApps(excludeSystemApps: true, withIcon: true);
    // Filter basic
    apps.sort((a, b) => (a.name ?? "").compareTo(b.name ?? ""));
    setState(() {
      _apps = apps;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text("Pilih Game / Aplikasi", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
              : ListView.builder(
                  itemCount: _apps.length,
                  itemBuilder: (context, index) {
                    final app = _apps[index];
                    return ListTile(
                      leading: app.icon != null 
                        ? Image.memory(app.icon!, width: 40, height: 40)
                        : const Icon(Icons.android, color: AppColors.textWhite),
                      title: Text(app.name ?? "Unknown", style: const TextStyle(color: AppColors.textWhite)),
                      subtitle: Text(app.packageName, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      onTap: () => widget.onAppSelected(app),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }
}
