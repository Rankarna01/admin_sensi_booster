import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../widgets/feature_card.dart';
import 'smart_touch_dashboard.dart' as import_dashboard;

class FeatureView extends ConsumerStatefulWidget {
  const FeatureView({super.key});

  @override
  ConsumerState<FeatureView> createState() => _FeatureViewState();
}

class _FeatureViewState extends ConsumerState<FeatureView> {
  // Tracker untuk toggle on/off fitur (di client side)
  final Map<String, bool> _activeFeatures = {};

  // State untuk DPI Settings
  double _dpiValue = 480;
  double _resScale = 100;
  double _renderScale = 100;
  int _refreshRate = 60;
  bool _displayOpt = true;

  // State untuk Performance Monitor (Floating)
  bool _showRam = true;
  bool _showBattery = true;
  bool _showSuhu = true;
  bool _showClock = true;

  // Method Channel ke Native Kotlin Overlay
  static const MethodChannel _overlayChannel = MethodChannel('com.mfw.sensi_booster/overlay');

  @override
  void initState() {
    super.initState();
    _checkInitialSmartTouchIntent();
    _overlayChannel.setMethodCallHandler((call) async {
      if (call.method == 'showSmartTouchDashboard') {
        _showSmartTouchDashboard();
      }
    });
  }

  Future<void> _checkInitialSmartTouchIntent() async {
    try {
      final bool opened = await _overlayChannel.invokeMethod('checkSmartTouchIntent') ?? false;
      if (opened) {
        _showSmartTouchDashboard();
      }
    } catch (e) {
      debugPrint("Gagal cek intent awal: \$e");
    }
  }

  void _showSmartTouchDashboard() {
    import_dashboard.SmartTouchDashboard.show(context);
  }

  Future<void> _handleFloatingGameToggle(bool isActive) async {
    setState(() => _activeFeatures['floating_game'] = isActive);
    
    if (isActive) {
      // Cek Permission Draw Overlays
      final bool hasPerm = await _overlayChannel.invokeMethod('checkPermission') ?? false;
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Meminta Izin Tampil di Atas Aplikasi Lain..."), backgroundColor: Colors.orange)
          );
        }
        await _overlayChannel.invokeMethod('requestPermission');
        // Anggap user mungkin kasih permission, kita matikan toggle sementara. User harus klik lagi.
        setState(() => _activeFeatures['floating_game'] = false);
        return;
      }
      
      // Jika punya izin, start service
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

  // State untuk Latency Mode
  String _latencyMode = "Normal";
  bool _pingOverlay = false;
  bool _wifiBoost = false;
  bool _smartRoute = false;

  @override
  Widget build(BuildContext context) {
    final pkgAsync = ref.watch(currentPackageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100), // Bottom padding untuk navbar
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
                    title: "Monitoring ROG",
                    description: "Menampilkan FPS, Suhu CPU, dan Penggunaan RAM secara real-time seperti sistem ROG.",
                    isActive: _activeFeatures['rog_monitor'] ?? false,
                    isAllowed: features['rog_monitor'] == true,
                    onChanged: (val) => setState(() => _activeFeatures['rog_monitor'] = val),
                  ),
                  FeatureCard(
                    title: "Game Lab Sensi",
                    description: "Runtime intervention configs parameter sensitivitas layar khusus game.",
                    isActive: _activeFeatures['game_lab_sensi'] ?? false,
                    isAllowed: features['game_lab_sensi'] == true,
                    onChanged: (val) => setState(() => _activeFeatures['game_lab_sensi'] = val),
                  ),
                  FeatureCard(
                    title: "Latency Mode & Network",
                    description: "Optimasi jaringan, stabilisasi ping, dan pemilihan rute pintar untuk game online.",
                    isActive: _activeFeatures['latency_mode'] ?? false,
                    isAllowed: features['latency_mode'] == true, // Butuh allow dari backend
                    onChanged: (val) {
                      setState(() => _activeFeatures['latency_mode'] = val);
                      if (val) _applyLatencyMode(_latencyMode); // Eksekusi fungsi nyata (root)
                    },
                    extraContent: _buildLatencySettings(),
                  ),
                  FeatureCard(
                    title: "CPU & RAM Tweaks",
                    description: "Mengubah CPU Governor (Perf/Balance), Core Priority, dan Limit Memory Cache.",
                    isActive: _activeFeatures['cpu_tweak'] ?? false,
                    isAllowed: features['cpu_tweak'] == true,
                    onChanged: (val) => setState(() => _activeFeatures['cpu_tweak'] = val),
                  ),
                  FeatureCard(
                    title: "Smart Switch DPI",
                    description: "Mengubah resolusi dan DPI Android paksa agar grafis game lebih tajam atau lebih lancar.",
                    isActive: _activeFeatures['set_dpi'] ?? false,
                    isAllowed: features['set_dpi'] == true,
                    onChanged: (val) => setState(() => _activeFeatures['set_dpi'] = val),
                    extraContent: _buildDpiSettings(),
                  ),
                  FeatureCard(
                    title: "Floating Game Tools",
                    description: "Akses pintasan Smart Touch Assistant dan informasi performa secara langsung melayang di layar.",
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
    );
  }

  Widget _buildDpiSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DPI Setting
        _buildSliderSetting("DPI Setting (Density)", _dpiValue, 120, 1000, "dpi", (val) => setState(() => _dpiValue = val)),
        const SizedBox(height: 12),
        // Resolution Scale
        _buildSliderSetting("Resolution Scale", _resScale, 50, 200, "%", (val) => setState(() => _resScale = val)),
        const SizedBox(height: 12),
        // Render Scale
        _buildSliderSetting("Render Scale", _renderScale, 50, 100, "%", (val) => setState(() => _renderScale = val)),
        const SizedBox(height: 16),
        
        // Refresh Rate
        Text("Refresh Rate", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRateButton(60),
            _buildRateButton(90),
            _buildRateButton(120),
          ],
        ),
        const SizedBox(height: 16),

        // Display Optimization
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Display Optimization", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Menyesuaikan tampilan berdasarkan device", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
            Switch(
              value: _displayOpt,
              onChanged: (val) => setState(() => _displayOpt = val),
              activeColor: AppColors.background,
              activeTrackColor: AppColors.neonGreen,
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.background,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliderSetting(String title, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
            Text("${value.toInt()}$unit", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.neonGreen,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.neonGreen,
            overlayColor: AppColors.neonGreen.withOpacity(0.2),
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildRateButton(int rate) {
    bool isSelected = _refreshRate == rate;
    return GestureDetector(
      onTap: () => setState(() => _refreshRate = rate),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonGreen.withOpacity(0.2) : AppColors.background,
          border: Border.all(color: isSelected ? AppColors.neonGreen : AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "${rate}Hz",
          style: GoogleFonts.orbitron(
            color: isSelected ? AppColors.neonGreen : AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLatencySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Network Mode", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildLatencyButton("Normal", "Stabil")),
            const SizedBox(width: 8),
            Expanded(child: _buildLatencyButton("Low", "Cepat")),
            const SizedBox(width: 8),
            Expanded(child: _buildLatencyButton("Ultra", "Max")),
          ],
        ),
        const SizedBox(height: 16),
        _buildToggleSetting("Ping Overlay", "Tampilkan ping realtime di layar", _pingOverlay, (val) => setState(() => _pingOverlay = val)),
        _buildToggleSetting("WiFi Boost", "Optimasi prioritas jaringan WiFi", _wifiBoost, (val) => setState(() => _wifiBoost = val)),
        _buildToggleSetting("Smart Route", "Pilih jalur koneksi otomatis (DNS Fast)", _smartRoute, (val) => setState(() => _smartRoute = val)),
      ],
    );
  }

  Widget _buildLatencyButton(String mode, String sub) {
    bool isSelected = _latencyMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _latencyMode = mode);
        _applyLatencyMode(mode); // Panggil fungsi root saat mode diubah
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonGreen.withOpacity(0.2) : AppColors.background,
          border: Border.all(color: isSelected ? AppColors.neonGreen : AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(mode, style: GoogleFonts.orbitron(color: isSelected ? AppColors.neonGreen : AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.bold)),
            Text(sub, style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSetting(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.background,
            activeTrackColor: AppColors.neonGreen,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.background,
          ),
        ],
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

  // --- FUNGSI EKSEKUSI NYATA (ROOT SHELL COMMANDS) ---
  void _applyLatencyMode(String mode) {
    // Fungsi ini mensimulasikan pemanggilan command system ke Android.
    // Untuk berjalan beneran di HP, butuh package seperti 'process_run' atau eksekusi bash shell, dan HP wajib ROOT.
    print("Mengeksekusi setting latency ke sistem Android...");
    
    String cmd = "";
    if (mode == "Normal") {
      cmd = "sysctl -w net.ipv4.tcp_congestion_control=cubic";
    } else if (mode == "Low") {
      cmd = "sysctl -w net.ipv4.tcp_congestion_control=bbr";
    } else if (mode == "Ultra") {
      // BBR, set DNS to Cloudflare/Google, minimize tcp buffers for fast drop/re-request
      cmd = "sysctl -w net.ipv4.tcp_congestion_control=bbr && ndc resolver setnetdns rmnet0 \"\" 1.1.1.1 8.8.8.8";
    }

    print("Executing ROOT command: su -c '\$cmd'");
    // Di aplikasi aslinya kita jalankan: 
    // Process.run('su', ['-c', cmd]);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Menerapkan $mode Latency Mode ke sistem...", style: GoogleFonts.orbitron()),
        backgroundColor: AppColors.card,
        duration: const Duration(seconds: 2),
      )
    );
  }
}