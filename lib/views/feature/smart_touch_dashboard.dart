import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import 'dart:io';

class SmartTouchDashboard extends StatefulWidget {
  const SmartTouchDashboard({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SmartTouchDashboard(),
    );
  }

  @override
  State<SmartTouchDashboard> createState() => _SmartTouchDashboardState();
}

class _SmartTouchDashboardState extends State<SmartTouchDashboard> {
  double _tapSpeed = 50;
  double _transparency = 80;
  int _multiTouch = 1;
  
  // Track status fitur
  final Map<String, bool> _activeTools = {};

  Future<void> _handleMediaFeature(String toolName, bool isActive) async {
    if (!isActive) {
      setState(() => _activeTools[toolName] = false);
      return;
    }

    // Simulasi minta permission storage
    bool granted = await _requestStoragePermission(toolName);
    if (granted) {
      setState(() => _activeTools[toolName] = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("\$toolName Aktif! Hasil akan disimpan ke Galeri.", style: GoogleFonts.orbitron()),
          backgroundColor: AppColors.neonGreen,
        )
      );
      
      // Simulasi eksekusi perintah root untuk record/screenshot
      if (toolName == "Quick Screenshot") {
        Process.run('su', ['-c', 'screencap -p /sdcard/Pictures/SensiBooster_Screenshot_\${DateTime.now().millisecondsSinceEpoch}.png']);
      } else if (toolName == "Screen Recorder") {
        // Dummy command
        Process.run('su', ['-c', 'screenrecord --time-limit 10 /sdcard/Pictures/SensiBooster_Record_\${DateTime.now().millisecondsSinceEpoch}.mp4']);
      }
    } else {
      setState(() => _activeTools[toolName] = false);
    }
  }

  Future<bool> _requestStoragePermission(String featureName) async {
    // Menampilkan dialog permission palsu/UI untuk simulasi
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(side: const BorderSide(color: AppColors.neonGreen), borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.security, color: AppColors.neonGreen),
            const SizedBox(width: 10),
            Expanded(child: Text("Permission Required", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 16))),
          ],
        ),
        content: Text("Fitur \$featureName membutuhkan akses ke Media & Penyimpanan (Storage) untuk menyimpan gambar/video ke Galeri. Izinkan?", style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("TOLAK", style: GoogleFonts.orbitron(color: Colors.redAccent))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGreen, foregroundColor: AppColors.background),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("IZINKAN", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
          ),
        ],
      )
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 50, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.touch_app, color: AppColors.neonGreen, size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SMART TOUCH", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  Text("FLOATING GAME TOOLS", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 12, letterSpacing: 2)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          Text("SETTINGS DASHBOARD", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildToolCard("Smart Tap Assistant", Icons.ads_click, "Smart Tap", false),
                _buildToolCard("Rapid Touch Mode", Icons.swipe, "Rapid Touch", false),
                _buildToolCard("Floating Overlay", Icons.layers, "Floating Overlay", false),
                _buildToolCard("FPS & Ping Monitor", Icons.monitor_heart, "FPS Monitor", false),
                _buildToolCard("Quick Screenshot", Icons.camera_alt, "Quick Screenshot", true),
                _buildToolCard("Screen Recorder", Icons.videocam, "Screen Recorder", true),
                _buildToolCard("Crosshair Overlay", Icons.gps_fixed, "Crosshair Overlay", false),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          Text("CUSTOMIZATION", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TAP SPEED", style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 10)),
                    Slider(value: _tapSpeed, min: 10, max: 100, activeColor: AppColors.neonGreen, onChanged: (v) => setState(() => _tapSpeed = v)),
                    Text("PANEL TRANSPARENCY", style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 10)),
                    Slider(value: _transparency, min: 20, max: 100, activeColor: AppColors.neonGreen, onChanged: (v) => setState(() => _transparency = v)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("MULTI-TOUCH POINTS", style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        bool isSel = _multiTouch == index + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _multiTouch = index + 1),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.neonGreen.withOpacity(0.2) : Colors.transparent,
                              border: Border.all(color: isSel ? AppColors.neonGreen : AppColors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text("\${index + 1}", style: TextStyle(color: isSel ? AppColors.neonGreen : AppColors.textMuted)),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Text("OVERLAY POSITION", style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.align_horizontal_left, color: AppColors.textMuted, size: 20),
                        Icon(Icons.align_horizontal_center, color: AppColors.neonGreen, size: 20),
                        Icon(Icons.align_horizontal_right, color: AppColors.textMuted, size: 20),
                      ],
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildToolCard(String title, IconData icon, String key, bool requiresMediaPerm) {
    bool isActive = _activeTools[key] ?? false;
    return GestureDetector(
      onTap: () {
        if (requiresMediaPerm) {
          _handleMediaFeature(key, !isActive);
        } else {
          setState(() => _activeTools[key] = !isActive);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.neonGreen.withOpacity(0.15) : AppColors.card,
          border: Border.all(color: isActive ? AppColors.neonGreen : AppColors.border),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive ? [BoxShadow(color: AppColors.neonGreen.withOpacity(0.3), blurRadius: 10)] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? AppColors.neonGreen : AppColors.textWhite, size: 32),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.orbitron(color: isActive ? AppColors.neonGreen : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
