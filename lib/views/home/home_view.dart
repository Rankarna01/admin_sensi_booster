import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../widgets/feature_card.dart';
import '../feature/game_launcher_view.dart';
import '../feature/smart_touch_dashboard.dart' as import_dashboard;

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> with SingleTickerProviderStateMixin {
  final Map<String, bool> _activeFeatures = {};

  // Network State
  String _latencyMode = "Normal";
  bool _pingOverlay = false;
  bool _wifiBoost = false;
  bool _smartRoute = false;

  // DPI State
  double _dpiValue = 480;
  double _resScale = 100;
  double _renderScale = 100;
  int _refreshRate = 60;
  bool _displayOpt = true;

  // Performance Monitor State
  final TextEditingController _dpiController = TextEditingController(text: "480");
  final TextEditingController _resController = TextEditingController(text: "100");

  static const MethodChannel _vpnChannel = MethodChannel('com.mfw.sensi_booster/vpn');
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

  @override
  void dispose() {
    _dpiController.dispose();
    _resController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialSmartTouchIntent() async {
    try {
      final bool opened = await _overlayChannel.invokeMethod('checkSmartTouchIntent') ?? false;
      if (opened) {
        _showSmartTouchDashboard();
      }
    } catch (e) {
      debugPrint("Gagal cek intent awal: $e");
    }
  }

  void _showSmartTouchDashboard() {
    import_dashboard.SmartTouchDashboard.show(context);
  }

  Future<void> _handleRogMonitorToggle(bool isActive) async {
    setState(() => _activeFeatures['rog_monitor'] = isActive);
    
    if (isActive) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GameLauncherView()),
      ).then((_) {
        if (mounted) {
          setState(() => _activeFeatures['rog_monitor'] = false);
        }
      });
    }
  }

  void _applySpecificLatencyMode(String mode) async {
    try {
      await _vpnChannel.invokeMethod('startVpn', {'mode': mode});
      if (mounted) {
        String extra = _wifiBoost ? " + WiFi Boost" : "";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sukses: Mode VPN $mode Diaktifkan$extra", style: GoogleFonts.orbitron(color: AppColors.background, fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.neonGreen,
            duration: const Duration(seconds: 2),
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengaktifkan VPN: $e", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  Future<void> _executeLatencyMode(bool isActive) async {
    setState(() => _activeFeatures['latency_mode'] = isActive);
    if (!isActive) {
      await _vpnChannel.invokeMethod('stopVpn');
      return;
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mempersiapkan Local VPN...", style: GoogleFonts.orbitron()),
          backgroundColor: AppColors.neonGreen.withOpacity(0.8),
          duration: const Duration(seconds: 2),
        )
      );
    }
    _applySpecificLatencyMode(_latencyMode);
  }

  @override
  Widget build(BuildContext context) {
    final pkgAsync = ref.watch(currentPackageProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 100),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.rocket_launch, color: AppColors.neonGreen, size: 16),
                        const SizedBox(width: 8),
                        Text("MFW ENGINE", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    userAsync.when(
                      data: (user) => Text("Welcome back, ${user?.email ?? 'Player'}", style: const TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
                      loading: () => const Text("Loading...", style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                      error: (_, __) => const Text("Welcome back, Player", style: TextStyle(color: AppColors.textWhite, fontSize: 14)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.speed, color: AppColors.neonGreen, size: 20),
                )
              ],
            ),
            const SizedBox(height: 30),

            pkgAsync.when(
              data: (pkg) {
                final features = pkg?.features ?? {};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 3, height: 16, color: AppColors.neonGreen),
                        const SizedBox(width: 8),
                        Text("GAME ENHANCERS", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 15),

                    FeatureCard(
                      title: "Monitoring ROG",
                      description: "Buka Game Space & tampilkan FPS, Suhu CPU, RAM secara real-time.",
                      isActive: _activeFeatures['rog_monitor'] ?? false,
                      isAllowed: features['rog_monitor'] == true,
                      onChanged: _handleRogMonitorToggle,
                    ),

                    FeatureCard(
                      title: "Game Lab Sensi",
                      description: "Runtime intervention configs parameter sensitivitas layar khusus game.",
                      isActive: _activeFeatures['game_lab_sensi'] ?? false,
                      isAllowed: features['game_lab_sensi'] == true,
                      onChanged: (val) => setState(() => _activeFeatures['game_lab_sensi'] = val),
                    ),
                    FeatureCard(
                      title: "CPU & RAM Tweaks",
                      description: "Mengubah CPU Governor (Perf/Balance), Core Priority, dan Limit Memory Cache.",
                      isActive: _activeFeatures['cpu_tweak'] ?? false,
                      isAllowed: features['cpu_tweak'] == true,
                      onChanged: (val) => setState(() => _activeFeatures['cpu_tweak'] = val),
                    ),
                    FeatureCard(
                      title: "Latency Mode & Network",
                      description: "Optimasi jaringan, stabilisasi ping, dan pemilihan rute pintar untuk game online.",
                      isActive: _activeFeatures['latency_mode'] ?? false,
                      isAllowed: features['latency_mode'] == true,
                      onChanged: (val) => _executeLatencyMode(val),
                      extraContent: _buildLatencySettings(),
                    ),
                    FeatureCard(
                      title: "Ping Overlay",
                      description: "Menampilkan widget ping kecil di layar agar mudah memantau koneksi.",
                      isActive: _activeFeatures['speed_test'] ?? false,
                      isAllowed: features['speed_test'] == true,
                      onChanged: (val) => setState(() => _activeFeatures['speed_test'] = val),
                    ),
                    FeatureCard(
                      title: "Smart Switch DPI",
                      description: "Mengubah resolusi dan DPI Android paksa agar grafis game lebih tajam atau lebih lancar.",
                      isActive: _activeFeatures['set_dpi'] ?? false,
                      isAllowed: features['set_dpi'] == true,
                      onChanged: (val) => setState(() => _activeFeatures['set_dpi'] = val),
                      extraContent: _buildDpiSettings(),
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

  // --- SETTINGS WIDGETS ---

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
        if (_activeFeatures['latency_mode'] == true) _applySpecificLatencyMode(mode);
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

  Widget _buildDpiSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldSetting("DPI Setting (Density)", _dpiController, "dpi", (val) {
          double? parsed = double.tryParse(val);
          if (parsed != null) setState(() => _dpiValue = parsed);
        }),
        const SizedBox(height: 12),
        _buildTextFieldSetting("Resolution Scale", _resController, "%", (val) {
          double? parsed = double.tryParse(val);
          if (parsed != null) setState(() => _resScale = parsed);
        }),
        const SizedBox(height: 12),
        _buildSliderSetting("Render Scale", _renderScale, 50, 100, "%", (val) => setState(() => _renderScale = val)),
        const SizedBox(height: 16),
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
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildTextFieldSetting(String title, TextEditingController controller, String unit, ValueChanged<String> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
        SizedBox(
          width: 90,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              suffixText: unit,
              suffixStyle: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 10),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.neonGreen), borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: AppColors.background,
            ),
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
        child: Text("${rate}Hz", style: GoogleFonts.orbitron(color: isSelected ? AppColors.neonGreen : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
