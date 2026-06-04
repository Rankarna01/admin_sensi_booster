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
    final actionState = ref.watch(packageActionProvider);

    // Listener untuk notifikasi sukses/gagal
    ref.listen(packageActionProvider, (previous, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $err"), backgroundColor: Colors.redAccent),
        ),
        data: (_) {
          if (previous is AsyncLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Data Paket Tersimpan!"), backgroundColor: AppColors.neonGreenDark),
            );
          }
        },
      );
    });

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
              // Tombol Tambah Paket Baru
              GestureDetector(
                onTap: () => _showPackageForm(context, ref),
                child: Container(
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
                ),
              )
            ],
          ),
        ),
        
        if (actionState is AsyncLoading)
          const LinearProgressIndicator(color: AppColors.neonGreen, backgroundColor: AppColors.background),

        Expanded(
          child: packageAsync.when(
            data: (packages) {
              if (packages.isEmpty) {
                return Center(
                  child: Text(
                    "Belum ada data paket.\nKlik tombol ADD untuk menambahkan.", 
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
                  return _buildPackageCard(context, ref, packages[index]);
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

  // --- WIDGET KARTU PAKET ---
  Widget _buildPackageCard(BuildContext context, WidgetRef ref, PackageModel pkg) {
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
              // Tombol Edit Paket
              GestureDetector(
                onTap: () => _showPackageForm(context, ref, existingPkg: pkg),
                child: const Icon(Icons.edit, color: AppColors.textMuted, size: 18),
              ),
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
          const SizedBox(height: 15),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          Text("FEATURES INCLUDED:", style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: pkg.features.entries
                .where((entry) => entry.value) // Hanya tampilkan yang True
                .map((entry) => _buildFeatureBadge(entry.key))
                .toList(),
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

  Widget _buildFeatureBadge(String featureKey) {
    String label = featureKey.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
      ),
      child: Text(label, style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 8)),
    );
  }

  // --- MODAL FORMULIR PAKET ---
  void _showPackageForm(BuildContext context, WidgetRef ref, {PackageModel? existingPkg}) {
    // Controller Text
    final nameC = TextEditingController(text: existingPkg?.name ?? '');
    final priceC = TextEditingController(text: existingPkg?.price.toStringAsFixed(0) ?? '0');
    final durationC = TextEditingController(text: existingPkg?.durationDays.toString() ?? '30');
    final refBonusC = TextEditingController(text: existingPkg?.referralRewardDays.toString() ?? '1');

    // Local State untuk 9 Fitur
    Map<String, bool> featureState = {
      'speed_test': existingPkg?.features['speed_test'] ?? false,
      'latency_mode': existingPkg?.features['latency_mode'] ?? false,
      'game_lab_sensi': existingPkg?.features['game_lab_sensi'] ?? false,
      'cpu_tweak': existingPkg?.features['cpu_tweak'] ?? false,
      'set_dpi': existingPkg?.features['set_dpi'] ?? false,
      'floating_game': existingPkg?.features['floating_game'] ?? false,
      'crosshair': existingPkg?.features['crosshair'] ?? false,
      'rog_monitor': existingPkg?.features['rog_monitor'] ?? false,
      'graphics_tweak': existingPkg?.features['graphics_tweak'] ?? false,
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.9, // Memakan 90% layar agar muat banyak scroll
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom, 
                  left: 20, right: 20, top: 20
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingPkg == null ? "CREATE PACKAGE" : "EDIT PACKAGE", 
                          style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- BAGIAN INPUT TEXT ---
                            TextField(
                              controller: nameC,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: "Package Name (e.g. VIP Booster)", labelStyle: TextStyle(color: AppColors.textMuted)),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: priceC,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: "Price (Rp)", labelStyle: TextStyle(color: AppColors.textMuted)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: durationC,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(labelText: "Active Duration (Days)", labelStyle: TextStyle(color: AppColors.textMuted)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: refBonusC,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(labelText: "Referral Bonus (Days)", labelStyle: TextStyle(color: AppColors.textMuted)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // --- BAGIAN SAKLAR 9 FITUR ---
                            Text("FEATURE ACCESS CONTROL", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ...featureState.keys.map((key) {
                              return SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.neonGreen,
                                inactiveTrackColor: AppColors.card,
                                title: Text(
                                  key.replaceAll('_', ' ').toUpperCase(), 
                                  style: GoogleFonts.orbitron(color: featureState[key]! ? AppColors.neonGreen : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)
                                ),
                                value: featureState[key]!,
                                onChanged: (val) {
                                  setModalState(() {
                                    featureState[key] = val;
                                  });
                                },
                              );
                            }).toList(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    
                    // --- TOMBOL SAVE ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Validasi angka
                          final price = double.tryParse(priceC.text) ?? 0;
                          final duration = int.tryParse(durationC.text) ?? 0;
                          final refBonus = int.tryParse(refBonusC.text) ?? 0;

                          // Bentuk model
                          PackageModel newPkg = PackageModel(
                            id: existingPkg?.id ?? '', // Jika baru, id kosong
                            name: nameC.text,
                            price: price,
                            durationDays: duration,
                            referralRewardDays: refBonus,
                            features: featureState,
                          );

                          // Panggil provider untuk save
                          ref.read(packageActionProvider.notifier).savePackage(newPkg);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGreen),
                        child: Text("SAVE CONFIGURATION", style: GoogleFonts.orbitron(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
}