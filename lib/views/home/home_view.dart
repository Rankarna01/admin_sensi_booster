import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../widgets/feature_card.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pkgAsync = ref.watch(currentPackageProvider);

    return SingleChildScrollView(
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
                    isActive: false,
                    isAllowed: features['speed_test'] == true,
                    onChanged: (val) {},
                  ),
                  FeatureCard(
                    title: "Latency Mode",
                    description: "Optimalisasi rute jaringan untuk mengurangi ping spike (Normal/Low).",
                    isActive: false,
                    isAllowed: features['latency_mode'] == true,
                    onChanged: (val) {},
                  ),
                  FeatureCard(
                    title: "Crosshair Overlay",
                    description: "Bantuan aim tambahan berupa titik atau crosshair di tengah layar.",
                    isActive: false,
                    isAllowed: features['crosshair'] == true,
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