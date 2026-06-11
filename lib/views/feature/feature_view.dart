import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../widgets/feature_card.dart';
import '../widgets/neon_loading.dart';

class FeatureView extends ConsumerStatefulWidget {
  const FeatureView({super.key});

  @override
  ConsumerState<FeatureView> createState() => _FeatureViewState();
}

class _FeatureViewState extends ConsumerState<FeatureView> {
  final Map<String, bool> _activeFeatures = {};
  bool _isLoading = false;

  bool _showRam = true;
  bool _showBattery = true;
  bool _showSuhu = true;
  bool _showClock = true;
  bool _showFps = true;

  static const MethodChannel _overlayChannel = MethodChannel('com.mfw.sensi_booster/overlay');

  Future<void> _handleFloatingGameToggle(bool isActive) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      _isLoading = false;
      _activeFeatures['floating_game'] = isActive;
    });
    
    if (isActive) {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Web Mode: Floating Tools preview only", style: GoogleFonts.inter(fontWeight: FontWeight.w500)), backgroundColor: AppColors.neonGreenDark),
          );
        }
        return;
      }

      final bool hasPerm = await _overlayChannel.invokeMethod('checkPermission') ?? false;
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Memerlukan izin overlay..."), backgroundColor: Colors.orange)
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
        'showFps': _showFps,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Floating Tools Aktif", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppColors.neonGreenDark,
          ),
        );
      }
    } else {
      if (kIsWeb) return;
      await _overlayChannel.invokeMethod('stopOverlay');
    }
  }

  Future<void> _handleGenericToggle(String key, bool isActive) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _isLoading = false;
      _activeFeatures[key] = isActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pkgAsync = ref.watch(currentPackageProvider);

    return PageLoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 36, bottom: 100),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ADVANCED TWEAKS",
                  style: GoogleFonts.inter(
                    color: AppColors.neonGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    "VIP",
                    style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                )
              ],
            ),
            const SizedBox(height: 18),

            pkgAsync.when(
              data: (pkg) {
                final features = pkg?.features ?? {};
                return Column(
                  children: [
                    FeatureCard(
                      title: "Floating Game Tools",
                      description: "Info performa melayang di layar.",
                      iconWidget: const FaIcon(FontAwesomeIcons.layerGroup),
                      isActive: _activeFeatures['floating_game'] ?? false,
                      isAllowed: features['floating_game'] == true,
                      onChanged: _handleFloatingGameToggle,
                      extraContent: _buildPerformanceMonitorSettings(),
                    ),
                    FeatureCard(
                      title: "Graphics Engine Tweak",
                      description: "MSAA, Vsync, GPU akselerasi.",
                      iconWidget: const FaIcon(FontAwesomeIcons.cogs),
                      isActive: _activeFeatures['graphics_tweak'] ?? false,
                      isAllowed: features['graphics_tweak'] == true,
                      onChanged: (val) => _handleGenericToggle('graphics_tweak', val),
                    ),
                  ],
                );
              },
              loading: () => const NeonLoading(message: "Memuat fitur..."),
              error: (e, _) => Center(child: Text("Error: $e", style: TextStyle(color: Colors.redAccent))),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildPerformanceMonitorSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Monitor", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMonitorChip("FPS", Icons.speed_rounded, _showFps, (v) {
                setState(() => _showFps = v);
                if (_activeFeatures['floating_game'] == true) _handleFloatingGameToggle(true);
              }),
              const SizedBox(width: 8),
              _buildMonitorChip("RAM", Icons.memory_rounded, _showRam, (v) {
                setState(() => _showRam = v);
                if (_activeFeatures['floating_game'] == true) _handleFloatingGameToggle(true);
              }),
              const SizedBox(width: 8),
              _buildMonitorChip("Battery", Icons.battery_charging_full_rounded, _showBattery, (v) {
                setState(() => _showBattery = v);
                if (_activeFeatures['floating_game'] == true) _handleFloatingGameToggle(true);
              }),
              const SizedBox(width: 8),
              _buildMonitorChip("Suhu", Icons.thermostat_rounded, _showSuhu, (v) {
                setState(() => _showSuhu = v);
                if (_activeFeatures['floating_game'] == true) _handleFloatingGameToggle(true);
              }),
              const SizedBox(width: 8),
              _buildMonitorChip("Jam", Icons.access_time_rounded, _showClock, (v) {
                setState(() => _showClock = v);
                if (_activeFeatures['floating_game'] == true) _handleFloatingGameToggle(true);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonitorChip(String label, IconData icon, bool isSelected, ValueChanged<bool> onSelected) {
    return GestureDetector(
      onTap: () => onSelected(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonGreen.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? AppColors.neonGreen.withOpacity(0.5) : AppColors.border),
          boxShadow: isSelected ? AppColors.glowGreen(blur: 8, opacity: 0.06) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? AppColors.neonGreen : AppColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: isSelected ? AppColors.neonGreen : AppColors.textWhite, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
