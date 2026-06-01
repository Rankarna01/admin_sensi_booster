import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/package_provider.dart';
import '../../models/package_model.dart';

class ConfigPage extends ConsumerWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageAsync = ref.watch(packageStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 3, height: 16, color: AppColors.neonGreen),
                  const SizedBox(width: 8),
                  Text("MASTER DATA PAKET", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              // Tombol Tambah Paket (Nantinya untuk membuka form edit/tambah)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: AppColors.neonGreen, size: 14),
                    const SizedBox(width: 4),
                    Text("ADD", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
        ),
        
        Expanded(
          child: packageAsync.when(
            data: (packages) {
              if (packages.isEmpty) {
                return Center(
                  child: Text(
                    "Belum ada data paket.\nTambahkan koleksi 'packages' di Firestore.", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: packages.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildPackageCard(packages[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),
            error: (err, _) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.redAccent))),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(PackageModel pkg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pkg.name.toUpperCase(),
                style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.edit, color: AppColors.textMuted, size: 18), // Icon Edit (Mockup)
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildConfigDetail("PRICE", "Rp ${pkg.price.toStringAsFixed(0)}"),
              _buildConfigDetail("DURATION", "${pkg.durationDays} Days"),
              _buildConfigDetail("REF. BONUS", "+${pkg.referralRewardDays} Days"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}