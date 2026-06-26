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
import 'auto_clicker_page.dart';
import 'smart_touch_dashboard.dart';
import 'resolution_changer_view.dart';

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

  String _latencyMode = "Normal";
  bool _pingOverlay = false;
  bool _wifiBoost = false;
  bool _smartRoute = false;

  double _dpiValue = 480;
  double _resScale = 100;
  double _renderScale = 100;
  int _refreshRate = 60;
  bool _displayOpt = true;

  final TextEditingController _dpiController = TextEditingController(text: "480");
  final TextEditingController _resController = TextEditingController(text: "100");

  static const MethodChannel _overlayChannel = MethodChannel('com.mfw.sensi_booster/overlay');
  static const MethodChannel _vpnChannel = MethodChannel('com.mfw.sensi_booster/vpn');

  @override
  void dispose() {
    _dpiController.dispose();
    _resController.dispose();
    super.dispose();
  }

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

  void _applySpecificLatencyMode(String mode) async {
    try {
      await _vpnChannel.invokeMethod('startVpn', {'mode': mode});
      if (mounted) {
        String extra = _wifiBoost ? " + WiFi Boost" : "";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mode VPN $mode aktif$extra"), backgroundColor: AppColors.neonGreenDark),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _executeLatencyMode(bool isActive) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      _isLoading = false;
      _activeFeatures['latency_mode'] = isActive;
    });

    if (!isActive) { await _vpnChannel.invokeMethod('stopVpn'); return; }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mengaktifkan VPN...", style: GoogleFonts.inter(fontWeight: FontWeight.w500)), backgroundColor: AppColors.neonGreen.withOpacity(0.8)),
      );
    }
    _applySpecificLatencyMode(_latencyMode);
  }

  Future<void> _handleAutoClickerToggle(bool isActive) async {
    setState(() => _activeFeatures['auto_clicker'] = isActive);
    if (isActive) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AutoClickerPage()),
      );
      if (mounted) {
        setState(() {
          if (result != true) {
            _activeFeatures['auto_clicker'] = false;
          }
        });
      }
    }
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
                  style: GoogleFonts.orbitron(
                    color: AppColors.neonGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
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
                    FeatureCard(
                      title: "Macro Auto Clicker",
                      description: "Auto tap dengan speed & multi-point.",
                      iconWidget: const FaIcon(FontAwesomeIcons.bolt),
                      isActive: _activeFeatures['auto_clicker'] ?? false,
                      isAllowed: features['auto_clicker'] == true,
                      onChanged: _handleAutoClickerToggle,
                    ),
                    FeatureCard(
                      title: "Game Lab Sensi",
                      description: "Sensitivitas layar khusus game.",
                      iconWidget: const FaIcon(FontAwesomeIcons.crosshairs),
                      isActive: _activeFeatures['game_lab_sensi'] ?? false,
                      isAllowed: features['game_lab_sensi'] == true,
                      onChanged: (val) => _handleGenericToggle('game_lab_sensi', val),
                    ),
                    FeatureCard(
                      title: "CPU & RAM Tweaks",
                      description: "CPU Governor, Core Priority, Memory Cache.",
                      iconWidget: const FaIcon(FontAwesomeIcons.memory),
                      isActive: _activeFeatures['cpu_tweak'] ?? false,
                      isAllowed: features['cpu_tweak'] == true,
                      onChanged: (val) => _handleGenericToggle('cpu_tweak', val),
                    ),
                    FeatureCard(
                      title: "Latency Mode",
                      description: "Stabilisasi ping & optimasi jaringan.",
                      iconWidget: const FaIcon(FontAwesomeIcons.wifi),
                      isActive: _activeFeatures['latency_mode'] ?? false,
                      isAllowed: features['latency_mode'] == true,
                      onChanged: (val) => _executeLatencyMode(val),
                      extraContent: _buildLatencySettings(),
                    ),
                    FeatureCard(
                      title: "Ping Overlay",
                      description: "Widget ping real-time di layar.",
                      iconWidget: const FaIcon(FontAwesomeIcons.tachometerAlt),
                      isActive: _activeFeatures['speed_test'] ?? false,
                      isAllowed: features['speed_test'] == true,
                      onChanged: (val) => _handleGenericToggle('speed_test', val),
                    ),
                    FeatureCard(
                      title: "Smart Switch DPI",
                      description: "Resolusi & DPI Android untuk grafis optimal.",
                      iconWidget: const FaIcon(FontAwesomeIcons.mobileAlt),
                      isActive: _activeFeatures['set_dpi'] ?? false,
                      isAllowed: features['set_dpi'] == true,
                      onChanged: (val) {
                        _handleGenericToggle('set_dpi', val);
                        if (val) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ResolutionChangerView()),
                          ).then((_) {
                            // Turn toggle off when returning, or keep it on depending on preference.
                            // We can keep it on if we assume they applied something, or just leave it.
                          });
                        }
                      },
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

  Widget _buildLatencySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Network Mode", style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildLatencyButton("Normal", "Stabil")),
            const SizedBox(width: 6),
            Expanded(child: _buildLatencyButton("Low", "Cepat")),
            const SizedBox(width: 6),
            Expanded(child: _buildLatencyButton("Ultra", "Max")),
          ],
        ),
        const SizedBox(height: 14),
        _buildToggleSetting("Ping Overlay", "Tampilkan ping di layar", _pingOverlay, (val) => setState(() => _pingOverlay = val)),
        _buildToggleSetting("WiFi Boost", "Prioritas jaringan WiFi", _wifiBoost, (val) => setState(() => _wifiBoost = val)),
        _buildToggleSetting("Smart Route", "DNS Fast otomatis", _smartRoute, (val) => setState(() => _smartRoute = val)),
      ],
    );
  }

  Widget _buildLatencyButton(String mode, String sub) {
    bool isSelected = _latencyMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _latencyMode = mode);
        if (_activeFeatures['latency_mode'] == true) _applySpecificLatencyMode(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonGreen.withOpacity(0.12) : AppColors.surface,
          border: Border.all(color: isSelected ? AppColors.neonGreen.withOpacity(0.5) : AppColors.border),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? AppColors.glowGreen(blur: 12, opacity: 0.08) : null,
        ),
        child: Column(
          children: [
            Text(mode, style: GoogleFonts.inter(color: isSelected ? AppColors.neonGreen : AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600)),
            Text(sub, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSetting(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          SciFiSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

}
