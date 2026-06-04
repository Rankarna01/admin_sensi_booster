import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class FeatureView extends StatelessWidget {
  const FeatureView({super.key});

  @override
  Widget build(BuildContext context) {
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
                "FEATURES",
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

          // Mockup Card Fitur
          _buildFeatureCard(
            title: "Smart Switch DPI",
            description: "Mengubah DPI dan resolusi otomatis dengan system dual mode yang disediakan.",
            isActive: false,
          ),
          _buildFeatureCard(
            title: "Sensitivity GameLab",
            description: "Runtime intervention configs parameter sensitivity langsung ke game.",
            isActive: true,
            isVip: true,
          ),
          _buildFeatureCard(
            title: "Touch Accelerator",
            description: "Meningkatkan kecepatan dan responsibilitas sentuhan sesuai tingkat pengaturan.",
            isActive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required String title, required String description, required bool isActive, bool isVip = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        if (isVip) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.neonGreen, borderRadius: BorderRadius.circular(4)),
                            child: Text("VIP", style: GoogleFonts.orbitron(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                          )
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Switch Neon Green
              Switch(
                value: isActive,
                onChanged: (val) {}, // Nanti dihubungkan ke provider
                activeColor: AppColors.background,
                activeTrackColor: AppColors.neonGreen,
                inactiveThumbColor: AppColors.textMuted,
                inactiveTrackColor: AppColors.background,
              )
            ],
          ),
        ],
      ),
    );
  }
}