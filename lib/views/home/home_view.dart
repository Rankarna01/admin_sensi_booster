import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../widgets/feature_card.dart';
import '../feature/game_launcher_view.dart';
import '../feature/smart_touch_dashboard.dart' as import_dashboard;
import '../widgets/neon_loading.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> with SingleTickerProviderStateMixin {
  final Map<String, bool> _activeFeatures = {};

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
      if (opened) _showSmartTouchDashboard();
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
        if (mounted) setState(() => _activeFeatures['rog_monitor'] = false);
      });
    }
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
    setState(() => _activeFeatures['latency_mode'] = isActive);
    if (!isActive) { await _vpnChannel.invokeMethod('stopVpn'); return; }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mengaktifkan VPN...", style: GoogleFonts.inter(fontWeight: FontWeight.w500)), backgroundColor: AppColors.neonGreen.withOpacity(0.8)),
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
        padding: const EdgeInsets.only(left: 20, right: 20, top: 36, bottom: 100),
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
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.rocket_launch_rounded, color: AppColors.neonGreen, size: 12),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "MFW ENGINE",
                          style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    userAsync.when(
                      data: (user) => Text(
                        "Welcome, ${user?.email?.split('@').first ?? 'Player'}",
                        style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      loading: () => const Text("...", style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                      error: (_, __) => const Text("Welcome", style: TextStyle(color: AppColors.textWhite, fontSize: 14)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow(),
                  ),
                  child: const Icon(Icons.speed_rounded, color: AppColors.neonGreen, size: 18),
                )
              ],
            ),
            const SizedBox(height: 24),

            pkgAsync.when(
              data: (pkg) {
                final features = pkg?.features ?? {};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 2, height: 14, color: AppColors.neonGreen),
                        const SizedBox(width: 8),
                        Text(
                          "GAME ENHANCERS",
                          style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    FeatureCard(
                      title: "Monitoring ROG",
                      description: "FPS, Suhu CPU, RAM real-time monitoring.",
                      isActive: _activeFeatures['rog_monitor'] ?? false,
                      isAllowed: features['rog_monitor'] == true,
                      onChanged: _handleRogMonitorToggle,
                    ),
                    FeatureCard(
                      title: "Game Lab Sensi",
                      description: "Sensitivitas layar khusus game.",
                      isActive: _activeFeatures['game_lab_sensi'] ?? false,
                      isAllowed: features['game_lab_sensi'] == true,
                      onChanged: (val) => setState(() => _activeFeatures['game_lab_sensi'] = val),
                    ),
                    FeatureCard(
                      title: "CPU & RAM Tweaks",
                      description: "CPU Governor, Core Priority, Memory Cache.",
                      isActive: _activeFeatures['cpu_tweak'] ?? false,
                      isAllowed: features['cpu_tweak'] == true,
                      onChanged: (val) => setState(() => _activeFeatures['cpu_tweak'] = val),
                    ),
                    FeatureCard(
                      title: "Latency Mode",
                      description: "Stabilisasi ping & optimasi jaringan.",
                      isActive: _activeFeatures['latency_mode'] ?? false,
                      isAllowed: features['latency_mode'] == true,
                      onChanged: (val) => _executeLatencyMode(val),
                      extraContent: _buildLatencySettings(),
                    ),
                    FeatureCard(
                      title: "Ping Overlay",
                      description: "Widget ping real-time di layar.",
                      isActive: _activeFeatures['speed_test'] ?? false,
                      isAllowed: features['speed_test'] == true,
                      onChanged: (val) => setState(() => _activeFeatures['speed_test'] = val),
                    ),
                    FeatureCard(
                      title: "Smart Switch DPI",
                      description: "Resolusi & DPI Android untuk grafis optimal.",
                      isActive: _activeFeatures['set_dpi'] ?? false,
                      isAllowed: features['set_dpi'] == true,
                      onChanged: (val) => setState(() => _activeFeatures['set_dpi'] = val),
                      extraContent: _buildDpiSettings(),
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
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDpiSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldSetting("DPI", _dpiController, "dpi", (val) {
          double? parsed = double.tryParse(val);
          if (parsed != null) setState(() => _dpiValue = parsed);
        }),
        const SizedBox(height: 10),
        _buildTextFieldSetting("Resolution", _resController, "%", (val) {
          double? parsed = double.tryParse(val);
          if (parsed != null) setState(() => _resScale = parsed);
        }),
        const SizedBox(height: 10),
        _buildSliderSetting("Render Scale", _renderScale, 50, 100, "%", (val) => setState(() => _renderScale = val)),
        const SizedBox(height: 14),
        Text("Refresh Rate", style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRateButton(60),
            _buildRateButton(90),
            _buildRateButton(120),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Display Opt.", style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600)),
                Text("Auto-adjust per device", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9)),
              ],
            ),
            Switch(
              value: _displayOpt,
              onChanged: (val) => setState(() => _displayOpt = val),
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
            Text(title, style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600)),
            Text("${value.toInt()}$unit", style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Widget _buildTextFieldSetting(String title, TextEditingController controller, String unit, ValueChanged<String> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600)),
        SizedBox(
          width: 85,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              suffixText: unit,
              suffixStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.neonGreen), borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: AppColors.surface,
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonGreen.withOpacity(0.12) : AppColors.surface,
          border: Border.all(color: isSelected ? AppColors.neonGreen.withOpacity(0.5) : AppColors.border),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? AppColors.glowGreen(blur: 10, opacity: 0.06) : null,
        ),
        child: Text(
          "${rate}Hz",
          style: GoogleFonts.inter(color: isSelected ? AppColors.neonGreen : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
