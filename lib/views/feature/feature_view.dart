import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../widgets/feature_card.dart';

class FeatureView extends ConsumerStatefulWidget {
  const FeatureView({super.key});

  @override
  ConsumerState<FeatureView> createState() => _FeatureViewState();
}

class _FeatureViewState extends ConsumerState<FeatureView> {
  final Map<String, bool> _activeFeatures = {};

  // State untuk Performance Monitor (Floating)
  bool _showRam = true;
  bool _showBattery = true;
  bool _showSuhu = true;
  bool _showClock = true;

  // Method Channel ke Native Kotlin Overlay
  static const MethodChannel _overlayChannel = MethodChannel('com.mfw.sensi_booster/overlay');

  Future<void> _handleFloatingGameToggle(bool isActive) async {
    setState(() => _activeFeatures['floating_game'] = isActive);
    
    if (isActive) {
      final bool hasPerm = await _overlayChannel.invokeMethod('checkPermission') ?? false;
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Meminta Izin Tampil di Atas Aplikasi Lain..."), backgroundColor: Colors.orange)
          );
        }
        await _overlayChannel.invokeMethod('requestPermission');
        setState(() => _activeFeatures['floating_game'] = false);
        return;
      }
      
      await _overlayChannel.invokeMethod('startOverlay', {
        'showRam': _showRam,
        'showBattery': _showBattery,
        'showSuhu': _showSuhu,
        'showClock': _showClock,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Floating Game Tools Melayang Aktif!", style: GoogleFonts.orbitron()), backgroundColor: AppColors.neonGreen)
        );
      }
    } else {
      await _overlayChannel.invokeMethod('stopOverlay');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkgAsync = ref.watch(currentPackageProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 100),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ADVANCED TWEAKS",
                  style: GoogleFonts.orbitron(
                    color: AppColors.neonGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.neonGreen),
                  ),
                  child: Text("VIP ACTIVE", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 20),

            pkgAsync.when(
              data: (pkg) {
                final features = pkg?.features ?? {};
                return Column(
                  children: [
                    FeatureCard(
                      title: "Floating Game Tools",
                      description: "Akses informasi performa secara langsung melayang di layar.",
                      isActive: _activeFeatures['floating_game'] ?? false,
                      isAllowed: features['floating_game'] == true,
                      onChanged: _handleFloatingGameToggle,
                      extraContent: _buildPerformanceMonitorSettings(),
                    ),
                    FeatureCard(
                      title: "Graphics Engine Tweak",
                      description: "Memaksa Anti-Aliasing (MSAA), Vsync, dan akselerasi GPU pada rendering game.",
                      isActive: _activeFeatures['graphics_tweak'] ?? false,
                      isAllowed: features['graphics_tweak'] == true,
                      onChanged: (val) => setState(() => _activeFeatures['graphics_tweak'] = val),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),
              error: (e, _) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.redAccent))),
            ),
          ],
        ),
      ),
    );
  }

  // --- PERFORMANCE MONITOR SETTINGS ---
  Widget _buildPerformanceMonitorSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Monitor", style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildMonitorChip("Monitor RAM", Icons.memory, _showRam, (v) {
              setState(() => _showRam = v);
              if (_activeFeatures['floating_game'] == true) _handleFloatingGameToggle(true);
            }),
            _buildMonitorChip("Monitor Battery", Icons.battery_charging_full, _showBattery, (v) {
              setState(() => _showBattery = v);
              if (_activeFeatures['floating_game'] == true) _handleFloatingGameToggle(true);
            }),
            _buildMonitorChip("Monitor Suhu", Icons.thermostat, _showSuhu, (v) {
              setState(() => _showSuhu = v);
              if (_activeFeatures['floating_game'] == true) _handleFloatingGameToggle(true);
            }),
            _buildMonitorChip("Monitor Jam", Icons.access_time, _showClock, (v) {
              setState(() => _showClock = v);
              if (_activeFeatures['floating_game'] == true) _handleFloatingGameToggle(true);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMonitorChip(String label, IconData icon, bool isSelected, ValueChanged<bool> onSelected) {
    return GestureDetector(
      onTap: () => onSelected(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonGreen.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.neonGreen : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? AppColors.neonGreen : AppColors.textWhite),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.orbitron(fontSize: 10, color: isSelected ? AppColors.neonGreen : AppColors.textWhite)),
          ],
        ),
      ),
    );
  }
}
