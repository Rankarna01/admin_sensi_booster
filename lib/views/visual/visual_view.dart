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
import 'crosshair_settings_panel.dart';

class VisualView extends ConsumerStatefulWidget {
  const VisualView({super.key});

  @override
  ConsumerState<VisualView> createState() => _VisualViewState();
}

class _VisualViewState extends ConsumerState<VisualView> with WidgetsBindingObserver {
  final Map<String, bool> _activeFeatures = {};
  bool _isLoading = false;
  static const MethodChannel _channel = MethodChannel('com.mfw.sensi_booster/crosshair');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncCrosshairState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncCrosshairState();
    }
  }

  // Sync Flutter toggle state with the actual native service state
  Future<void> _syncCrosshairState() async {
    if (kIsWeb) return;
    try {
      final bool running = await _channel.invokeMethod('isRunning') ?? false;
      if (mounted) {
        setState(() {
          _activeFeatures['crosshair'] = running;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleCrosshairToggle(bool isActive) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      _isLoading = false;
      _activeFeatures['crosshair'] = isActive;
    });

    if (isActive) {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Web Mode: Crosshair preview only", style: GoogleFonts.inter(fontWeight: FontWeight.w500)), backgroundColor: AppColors.neonGreenDark),
          );
        }
        return;
      }

      try {
        final bool hasPerm = await _channel.invokeMethod('checkPermission') ?? false;
        if (!hasPerm) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Memerlukan izin overlay..."), backgroundColor: Colors.orange));
          }
          await _channel.invokeMethod('requestPermission');
          setState(() => _activeFeatures['crosshair'] = false);
          return;
        }

        await _channel.invokeMethod('startCrosshair', {
          'shape': 'cross_dot',
          'color': '#FF0000',
          'size': 40,
          'opacity': 255,
          'offsetX': 0,
          'offsetY': 0,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Crosshair Active - Double tap to toggle off", style: GoogleFonts.inter(fontWeight: FontWeight.w500)), backgroundColor: AppColors.neonGreenDark),
          );
        }
      } catch (e) {
        setState(() => _activeFeatures['crosshair'] = false);
        debugPrint("Start error: $e");
      }
    } else {
      if (kIsWeb) return;
      try {
        await _channel.invokeMethod('stopCrosshair');
      } catch (_) {}
      // Verify it actually stopped
      _syncCrosshairState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkgAsync = ref.watch(currentPackageProvider);
    final isCrosshairActive = _activeFeatures['crosshair'] ?? false;

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
                  "VISUAL ENGINE",
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
                    "ACTIVE",
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
                      title: "Crosshair Overlay",
                      description: "Custom crosshair for precision aiming in games.",
                      iconWidget: const FaIcon(FontAwesomeIcons.crosshairs),
                      isActive: isCrosshairActive,
                      isAllowed: features['crosshair'] == true,
                      onChanged: _handleCrosshairToggle,
                      extraContent: isCrosshairActive ? const CrosshairSettingsPanel() : null,
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
}
