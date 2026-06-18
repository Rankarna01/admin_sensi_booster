import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

class ResolutionChangerView extends StatefulWidget {
  const ResolutionChangerView({super.key});

  @override
  State<ResolutionChangerView> createState() => _ResolutionChangerViewState();
}

class _ResolutionChangerViewState extends State<ResolutionChangerView> {
  static const MethodChannel _shizukuChannel = MethodChannel('com.mfw.sensi_booster/shizuku');

  String _selectedMode = "Mode Biasa";
  final List<String> _displayModes = ["Mode Biasa", "Mode Ultrawide (21:9)", "Mode iPad (4:3)", "Mode Custom"];
  
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _dpiController = TextEditingController();

  List<AppInfo> _addedGamesInfo = [];
  bool _isLoadingGames = true;
  
  int _nativeWidth = 1080;
  int _nativeHeight = 2400;

  String _shizukuStatus = "loading";
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNativeResolution();
      _calculateResolution();
    });
    _loadAddedGames();
    
    _checkStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkStatus());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      final status = await _shizukuChannel.invokeMethod('checkShizukuStatus');
      if (mounted && status != null) {
        setState(() => _shizukuStatus = status as String);
      }
    } catch (e) {
      // ignore
    }
  }

  void _initNativeResolution() {
    final logicalSize = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final physicalSize = logicalSize * pixelRatio;
    
    // We assume portrait orientation for the native physical size
    if (physicalSize.width < physicalSize.height) {
      _nativeWidth = physicalSize.width.toInt();
      _nativeHeight = physicalSize.height.toInt();
    } else {
      _nativeWidth = physicalSize.height.toInt();
      _nativeHeight = physicalSize.width.toInt();
    }
  }

  void _calculateResolution() {
    if (_selectedMode == "Mode Biasa") {
      _widthController.text = _nativeWidth.toString();
      _heightController.text = _nativeHeight.toString();
    } else if (_selectedMode == "Mode Ultrawide (21:9)") {
      _widthController.text = _nativeWidth.toString();
      _heightController.text = (_nativeWidth * 21 ~/ 9).toString();
    } else if (_selectedMode == "Mode iPad (4:3)") {
      _widthController.text = _nativeWidth.toString();
      _heightController.text = (_nativeWidth * 4 ~/ 3).toString();
    } else if (_selectedMode == "Mode Custom") {
      // Biarkan user isi manual
    }
  }

  Future<void> _loadAddedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final packages = prefs.getStringList('added_games') ?? [];
    
    try {
      final allApps = await InstalledApps.getInstalledApps(excludeSystemApps: true, withIcon: true);
      final List<AppInfo> added = [];
      for (String pkg in packages) {
        final idx = allApps.indexWhere((a) => a.packageName == pkg);
        if (idx != -1) {
          added.add(allApps[idx]);
        }
      }
      if (mounted) {
        setState(() {
          _addedGamesInfo = added;
          _isLoadingGames = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGames = false);
      }
    }
  }

  Future<void> _applyChanges() async {
    if (_shizukuStatus == "not_running") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap jalankan Shizuku terlebih dahulu.")));
      return;
    }

    final w = _widthController.text.trim();
    final h = _heightController.text.trim();
    final d = _dpiController.text.trim();

    String cmds = "";
    if (w.isNotEmpty && h.isNotEmpty) {
      cmds += "wm size ${w}x$h";
    }
    if (d.isNotEmpty) {
      if (cmds.isNotEmpty) cmds += " && ";
      cmds += "wm density $d";
    }

    if (cmds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada yang diubah.")));
      return;
    }

    await _runCommand(cmds);
  }

  Future<void> _resetChanges() async {
    if (_shizukuStatus == "not_running") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap jalankan Shizuku terlebih dahulu.")));
      return;
    }

    await _runCommand("wm size reset && wm density reset");
    setState(() {
      _selectedMode = "Mode Biasa";
      _dpiController.clear();
      _calculateResolution();
    });
  }

  Future<void> _runCommand(String command) async {
    try {
      final hasPerm = await _shizukuChannel.invokeMethod('checkPermission') ?? false;
      if (!hasPerm) {
        await _shizukuChannel.invokeMethod('requestPermission');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menunggu izin Shizuku...")));
        return;
      }
      final success = await _shizukuChannel.invokeMethod('runCommand', {'command': command}) ?? false;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil diterapkan!", style: GoogleFonts.inter()), backgroundColor: AppColors.neonGreen));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menerapkan perintah.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildShizukuStatus() {
    Color bgColor = Colors.white10;
    Color iconColor = Colors.white54;
    IconData icon = Icons.info_outline;
    String title = "Mengecek Shizuku...";
    String desc = "Harap tunggu sebentar.";

    if (_shizukuStatus == "running_granted") {
      bgColor = AppColors.neonGreen.withAlpha(25); // ~0.1 opacity
      iconColor = AppColors.neonGreen;
      icon = Icons.check_circle;
      title = "Shizuku Aktif";
      desc = "Sistem telah siap digunakan.";
    } else if (_shizukuStatus == "running_not_granted") {
      bgColor = Colors.orange.withAlpha(25);
      iconColor = Colors.orange;
      icon = Icons.warning_amber;
      title = "Izin Diperlukan";
      desc = "Shizuku berjalan, tap APPLY untuk minta izin.";
    } else if (_shizukuStatus == "not_running") {
      bgColor = Colors.redAccent.withAlpha(25);
      iconColor = Colors.redAccent;
      icon = Icons.error_outline;
      title = "Shizuku Belum Aktif";
      desc = "Jalankan Shizuku lewat Wireless Debugging.";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withAlpha(128)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Resolution Changer", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShizukuStatus(),

            Text("DISPLAY MODE", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMode,
                  isExpanded: true,
                  dropdownColor: AppColors.card,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                  items: _displayModes.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedMode = val;
                        _calculateResolution();
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text("RESOLUTION", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_widthController, "Width", keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(_heightController, "Height", keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text("DENSITY", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTextField(_dpiController, "DPI", keyboardType: TextInputType.number),
            const SizedBox(height: 24),

            Expanded(
              child: _isLoadingGames
                  ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
                  : _addedGamesInfo.isEmpty
                      ? Center(child: Text("Belum ada game", style: GoogleFonts.inter(color: Colors.white54)))
                      : ListView.builder(
                          itemCount: _addedGamesInfo.length,
                          itemBuilder: (context, index) {
                            final app = _addedGamesInfo[index];
                            return _buildGameItem(app);
                          },
                        ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _resetChanges,
                    child: Text("RESET", style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _applyChanges,
                    child: Text("APPLY", style: GoogleFonts.inter(color: AppColors.background, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool readOnly = false, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
        onChanged: (_) {
          if (_selectedMode != "Mode Custom") {
            setState(() {
              _selectedMode = "Mode Custom";
            });
          }
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGameItem(AppInfo app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          if (app.icon != null)
            Image.memory(app.icon!, width: 32, height: 32)
          else
            const Icon(Icons.gamepad, color: AppColors.neonGreen, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name ?? "Game", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(app.packageName ?? "", style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(app.versionName ?? "", style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 2),
              Text("Installed", style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
}
