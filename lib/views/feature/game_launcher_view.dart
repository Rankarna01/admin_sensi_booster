import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:app_usage/app_usage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import 'game_boost_landscape_view.dart';

class GameLauncherView extends StatefulWidget {
  const GameLauncherView({super.key});

  @override
  State<GameLauncherView> createState() => _GameLauncherViewState();
}

class _GameLauncherViewState extends State<GameLauncherView> {
  List<Map<String, dynamic>> _addedGames = [];
  Map<String, Duration> _usageStats = {};
  bool _isLoading = true;

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
      _addedGames = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      // Default mock data if none added
      _addedGames = [
        {"name": "Free Fire", "package": "com.dts.freefireth"},
        {"name": "Mobile Legends: Bang Bang", "package": "com.mobile.legends"},
      ];
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

  void _navigateToBoostLandscape(String name, String packageName, String durationStr) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameBoostLandscapeView(
          appName: name,
          packageName: packageName,
          durationStr: durationStr,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours}j ${duration.inMinutes.remainder(60)}m";
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
        title: Text("GAME SPACE", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.neonGreen),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: AppColors.neonGreen, size: 20),
              onPressed: _addGame,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
        : _addedGames.isEmpty 
          ? const Center(child: Text("Belum ada game ditambahkan", style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _addedGames.length,
              itemBuilder: (context, index) {
                final game = _addedGames[index];
                final String pkgName = game["package"]!;
                final duration = _usageStats[pkgName];
                final String durationStr = duration != null ? _formatDuration(duration) : "0 Menit";

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      // App Icon
                      FutureBuilder<AppInfo?>(
                        future: InstalledApps.getAppInfo(pkgName),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data?.icon != null) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  snapshot.data!.icon!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.videogame_asset, color: AppColors.textMuted),
                          );
                        },
                      ),
                      const SizedBox(width: 15),
                      // App Name & Duration
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(game["name"]!, style: const TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: AppColors.neonGreen, size: 12),
                                const SizedBox(width: 4),
                                Text(durationStr, style: const TextStyle(color: AppColors.neonGreen, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Boost Button
                      GestureDetector(
                        onTap: () => _navigateToBoostLandscape(game["name"]!, pkgName, durationStr),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.neonGreen),
                            boxShadow: [
                              BoxShadow(color: AppColors.neonGreen.withOpacity(0.3), blurRadius: 10, spreadRadius: -2)
                            ]
                          ),
                          child: Text("BOOST", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
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
    List<AppInfo> apps = await InstalledApps.getInstalledApps(excludeSystemApps: true, withIcon: true);
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
          Text("Pilih Game", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 18, fontWeight: FontWeight.bold)),
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
                        : const Icon(Icons.android, color: Colors.white),
                      title: Text(app.name ?? "Unknown", style: const TextStyle(color: Colors.white)),
                      subtitle: Text(app.packageName, style: const TextStyle(color: Colors.white54, fontSize: 10)),
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
