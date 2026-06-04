import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../widgets/feature_card.dart';

class FeatureView extends ConsumerWidget {
  const FeatureView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    isActive: false,
                    isAllowed: features['rog_monitor'] == true,
                    onChanged: (val) {},
                  ),
                  FeatureCard(
                    title: "Game Lab Sensi",
                    description: "Runtime intervention configs parameter sensitivitas layar khusus game.",
                    isActive: false,
                    isAllowed: features['game_lab_sensi'] == true,
                    onChanged: (val) {},
                  ),
                  FeatureCard(
                    title: "CPU & RAM Tweaks",
                    description: "Mengubah CPU Governor (Perf/Balance), Core Priority, dan Limit Memory Cache.",
                    isActive: false,
                    isAllowed: features['cpu_tweak'] == true,
                    onChanged: (val) {},
                  ),
                  FeatureCard(
                    title: "Smart Switch DPI",
                    description: "Mengubah resolusi dan DPI Android paksa agar grafis game lebih tajam atau lebih lancar.",
                    isActive: false,
                    isAllowed: features['set_dpi'] == true,
                    onChanged: (val) {},
                  ),
                  FeatureCard(
                    title: "Floating Game",
                    description: "Akses pintasan sistem booster pop-up mini di atas layar saat game berjalan.",
                    isActive: false,
                    isAllowed: features['floating_game'] == true,
                    onChanged: (val) {},
                  ),
                  FeatureCard(
                    title: "Graphics Engine Tweak",
                    description: "Memaksa Anti-Aliasing (MSAA), Vsync, dan akselerasi GPU pada rendering game.",
                    isActive: false,
                    isAllowed: features['graphics_tweak'] == true,
                    onChanged: (val) {},
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
}