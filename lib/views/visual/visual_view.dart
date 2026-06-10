import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../widgets/feature_card.dart';
import '../widgets/neon_loading.dart';
import 'crosshair_overlay_page.dart';

class VisualView extends ConsumerStatefulWidget {
  const VisualView({super.key});

  @override
  ConsumerState<VisualView> createState() => _VisualViewState();
}

class _VisualViewState extends ConsumerState<VisualView> {
  final Map<String, bool> _activeFeatures = {};
  static const MethodChannel _channel = MethodChannel('com.mfw.sensi_booster/crosshair');

  bool _crosshairActive = false;

  Future<void> _handleCrosshairToggle(bool isActive) async {
    setState(() => _activeFeatures['crosshair'] = isActive);

    if (isActive) {
      // Navigate to crosshair customization page
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const CrosshairOverlayPage()),
      );
      // Update state based on what happened in the crosshair page
      if (mounted) {
        setState(() {
          _crosshairActive = result == true;
          // If user didn't activate, reset the feature toggle
          if (result != true) {
            _activeFeatures['crosshair'] = false;
          }
        });
      }
    } else {
      // Stop the crosshair overlay
      try {
        await _channel.invokeMethod('stopCrosshair');
      } catch (_) {}
      setState(() {
        _crosshairActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkgAsync = ref.watch(currentPackageProvider);

    return Scaffold(
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
                      isActive: _activeFeatures['crosshair'] ?? false,
                      isAllowed: features['crosshair'] == true,
                      onChanged: _handleCrosshairToggle,
                      extraContent: _buildCrosshairExtra(),
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

  Widget _buildCrosshairExtra() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_crosshairActive) ...[
          // Active status with customize button
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonGreen,
                  boxShadow: [BoxShadow(color: AppColors.neonGreen.withOpacity(0.5), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 6),
              Text("Crosshair is active", style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 11, fontWeight: FontWeight.w500)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CrosshairOverlayPage()),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, color: AppColors.neonGreen, size: 12),
                      const SizedBox(width: 4),
                      Text("Customize", style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Quick preview of available shapes
          Text("Crosshair Styles", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _crosshairShapesPreview.map((shape) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(shape.icon, color: AppColors.textMuted.withOpacity(0.6), size: 18),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Text("Toggle ON to customize shape, color & size", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w400)),
        ],
      ],
    );
  }
}

final _crosshairShapesPreview = [
  _ShapePreview(Icons.add_circle_outline, "Cross+Dot"),
  _ShapePreview(Icons.add, "Cross"),
  _ShapePreview(Icons.circle, "Dot"),
  _ShapePreview(Icons.circle_outlined, "Circle"),
  _ShapePreview(Icons.text_fields, "T-Shape"),
  _ShapePreview(Icons.diamond_outlined, "Diamond"),
  _ShapePreview(Icons.add_circle, "Plus"),
  _ShapePreview(Icons.gps_fixed, "Scope"),
];

class _ShapePreview {
  final IconData icon;
  final String label;
  const _ShapePreview(this.icon, this.label);
}
