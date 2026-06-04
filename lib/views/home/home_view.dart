import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
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
                // Efek Glow Hijau di belakang
                Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.neonGreen.withOpacity(0.15), blurRadius: 40, spreadRadius: 10),
                    ],
                  ),
                ),
                // Lingkaran Progress
                SizedBox(
                  width: 220, height: 220,
                  child: CircularProgressIndicator(
                    value: 0.85, // Mockup nilai (85%)
                    strokeWidth: 12,
                    color: AppColors.neonGreen,
                    backgroundColor: AppColors.card,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Teks Angka Ping di Tengah
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
          const SizedBox(height: 50),

          // --- NETWORK METRICS (DL / UL) ---
          Row(
            children: [
              Expanded(child: _buildNetworkStat(Icons.arrow_downward, "DOWNLOAD", "45.2", "MB/s", Colors.lightBlueAccent)),
              const SizedBox(width: 15),
              Expanded(child: _buildNetworkStat(Icons.arrow_upward, "UPLOAD", "12.8", "MB/s", Colors.orangeAccent)),
            ],
          ),
          const SizedBox(height: 30),

          // --- TOMBOL OPTIMIZE NETWORK ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Aksi animasi ping nanti
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.card,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.neonGreen, width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch, color: AppColors.neonGreen, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    "OPTIMIZE NETWORK",
                    style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Pembantu untuk Kartu Metrik Jaringan Bawah
  Widget _buildNetworkStat(IconData icon, String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(color: AppColors.textWhite, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}