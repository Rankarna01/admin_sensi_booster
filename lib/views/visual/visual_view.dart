import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../widgets/feature_card.dart';

class VisualView extends ConsumerStatefulWidget {
  const VisualView({super.key});

  @override
  ConsumerState<VisualView> createState() => _VisualViewState();
}

class _VisualViewState extends ConsumerState<VisualView> {
  final Map<String, bool> _activeFeatures = {};

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
                  "VISUAL ENGINE",
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
                  child: Text("ACTIVE", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
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
              error: (e, _) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.redAccent))),
            ),
          ],
        ),
      ),
    );
  }
}
