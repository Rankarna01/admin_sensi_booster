import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../widgets/feature_card.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> with SingleTickerProviderStateMixin {
  // Tracker fitur aktif
  final Map<String, bool> _activeFeatures = {};

  // State internal untuk Latency Mode Settings
  String _latencyMode = "Normal";
  bool _pingOverlay = false;
  bool _wifiBoost = false;
  bool _smartRoute = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Method Channel ke Native Kotlin VPN
  static const MethodChannel _vpnChannel = MethodChannel('com.mfw.sensi_booster/vpn');

  // Fungsi untuk eksekusi nyata shell command
  Future<void> _executeLatencyMode(bool isActive) async {
    if (!isActive) {
      await _vpnChannel.invokeMethod('stopVpn');
      return;
    }
    
    // Tampilkan notifikasi awal
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mempersiapkan Local VPN (Non-Root)...", style: GoogleFonts.orbitron()),
          backgroundColor: AppColors.neonGreen.withOpacity(0.8),
          duration: const Duration(seconds: 2),
        )
      );
    }
    _applySpecificLatencyMode(_latencyMode);
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
      print("Error starting VPN: \$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengaktifkan VPN: \$e", style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkgAsync = ref.watch(currentPackageProvider);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // --- HEADER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SYSTEM READY",
                    style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Welcome back, Player",
                    style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.wifi, color: AppColors.textWhite, size: 20),
              )
            ],
          ),
          const SizedBox(height: 40),

          // --- MAIN SPEEDOMETER (PING INDICATOR) ---
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.neonGreen.withOpacity(0.15), blurRadius: 40, spreadRadius: 10),
                    ],
                  ),
                ),
                SizedBox(
                  width: 220, height: 220,
                  child: CircularProgressIndicator(
                    value: 0.85,
                    strokeWidth: 12,
                    color: AppColors.neonGreen,
                    backgroundColor: AppColors.card,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text("24", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 56, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Text("ms", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text("CURRENT PING", style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 10, letterSpacing: 2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          Row(
            children: [
              Container(width: 3, height: 16, color: AppColors.neonGreen),
              const SizedBox(width: 8),
              Text("BASIC FEATURES", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),

          pkgAsync.when(
            data: (pkg) {
              final features = pkg?.features ?? {};
              return Column(
                children: [
                  FeatureCard(
                    title: "Ping Overlay",
                    description: "Menampilkan widget ping kecil di layar agar mudah memantau koneksi.",
                    isActive: _activeFeatures['speed_test'] ?? false,
                    isAllowed: features['speed_test'] == true,
                    onChanged: (val) => setState(() => _activeFeatures['speed_test'] = val),
                  ),
                  FeatureCard(
                    title: "Latency Mode",
                    description: "Optimalisasi rute jaringan untuk mengurangi ping spike (BBR Inject).",
                    isActive: _activeFeatures['latency_mode'] ?? false,
                    isAllowed: features['latency_mode'] == true,
                    onChanged: (val) {
                      setState(() => _activeFeatures['latency_mode'] = val);
                      _executeLatencyMode(val); // <--- Eksekusi Root Command Langsung
                    },
                  ),
                  FeatureCard(
                    title: "Crosshair Overlay",
                    description: "Bantuan aim tambahan berupa titik atau crosshair di tengah layar.",
                    isActive: _activeFeatures['crosshair'] ?? false,
                    isAllowed: features['crosshair'] == true,
                    onChanged: (val) => setState(() => _activeFeatures['crosshair'] = val),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),
            error: (e, _) => Center(child: Text("Error: \$e", style: const TextStyle(color: Colors.redAccent))),
          ),
        ],
      ),
    ),
    
    // FLOATING ICON UNTUK LATENCY MODE (Hanya Muncul Jika Aktif)
    if (_activeFeatures['latency_mode'] == true)
      Positioned(
        bottom: 100, // Di atas navbar
        right: 20,
        child: GestureDetector(
          onTap: _showLatencyBottomSheet,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neonGreen, width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.neonGreen.withOpacity(0.6), blurRadius: 15, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.speed, color: AppColors.neonGreen, size: 28),
            ),
          ),
        ),
      ),
    ]);
  }

  // --- BOTTOM SHEET UNTUK SETTING LATENCY ---
  void _showLatencyBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder( // Agar state di dalam bottom sheet bisa update real-time
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.5), width: 1),
                boxShadow: [BoxShadow(color: AppColors.neonGreen.withOpacity(0.1), blurRadius: 20, spreadRadius: 0, offset: const Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.speed, color: AppColors.neonGreen),
                      const SizedBox(width: 10),
                      Text("LATENCY ENGINE", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("Network Mode", style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildModalModeBtn("Normal", "Stabil", setModalState)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildModalModeBtn("Low", "Delay--", setModalState)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildModalModeBtn("Ultra", "Max", setModalState)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildModalToggle("Ping Overlay", "Tampilkan ping realtime di layar", _pingOverlay, (val) {
                    setModalState(() => _pingOverlay = val);
                    setState(() => _pingOverlay = val);
                  }),
                  _buildModalToggle("WiFi Boost", "Prioritaskan koneksi WiFi", _wifiBoost, (val) {
                    setModalState(() => _wifiBoost = val);
                    setState(() => _wifiBoost = val);
                    if (val) _applySpecificLatencyMode(_latencyMode);
                  }),
                  _buildModalToggle("Smart Route", "Pilih rute otomatis (Fast DNS)", _smartRoute, (val) {
                    setModalState(() => _smartRoute = val);
                    setState(() => _smartRoute = val);
                    if (val && _latencyMode != "Ultra") {
                      _applySpecificLatencyMode("Ultra");
                      setModalState(() => _latencyMode = "Ultra");
                      setState(() => _latencyMode = "Ultra");
                    }
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildModalModeBtn(String mode, String sub, StateSetter setModalState) {
    bool isSelected = _latencyMode == mode;
    return GestureDetector(
      onTap: () {
        setModalState(() => _latencyMode = mode);
        setState(() => _latencyMode = mode);
        _applySpecificLatencyMode(mode);
        Navigator.pop(context); // Tutup modal otomatis setelah pilih mode
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonGreen.withOpacity(0.2) : AppColors.background,
          border: Border.all(color: isSelected ? AppColors.neonGreen : AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(mode, style: GoogleFonts.orbitron(color: isSelected ? AppColors.neonGreen : AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(sub, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildModalToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
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
}