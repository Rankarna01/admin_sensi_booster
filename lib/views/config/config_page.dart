import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/package_provider.dart';
import '../../models/package_model.dart';
import '../widgets/neon_loading.dart';

class ConfigPage extends ConsumerWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageAsync = ref.watch(packageStreamProvider);
    final actionState = ref.watch(packageActionProvider);

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
                  Container(width: 2, height: 14, color: AppColors.neonGreen),
                  const SizedBox(width: 8),
                  Text(
                    "MASTER DATA PAKET",
                    style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showPackageForm(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded, color: AppColors.neonGreen, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "ADD",
                        style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        
        if (actionState is AsyncLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: LinearProgressIndicator(color: AppColors.neonGreen, backgroundColor: AppColors.surface, minHeight: 2),
          ),

        Expanded(
          child: packageAsync.when(
            data: (packages) {
              if (packages.isEmpty) {
                return const Center(child: NeonLoading(message: "Belum ada data paket"));
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
            loading: () => const NeonLoading(message: "Memuat paket..."),
            error: (err, _) => Center(child: Text("Error: $err", style: TextStyle(color: Colors.redAccent))),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(BuildContext context, WidgetRef ref, PackageModel pkg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.neonGreen.withOpacity(0.03), blurRadius: 16),
          ...AppColors.cardShadow(),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pkg.name.toUpperCase(),
                style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: () => _showPackageForm(context, ref, existingPkg: pkg),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.edit_rounded, color: AppColors.textMuted, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildConfigDetail("PRICE", "Rp ${pkg.price.toStringAsFixed(0)}"),
              _buildConfigDetail("DURATION", "${pkg.durationDays} Days"),
              _buildConfigDetail("REF. BONUS", "+${pkg.referralRewardDays} Days"),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(
            "FEATURES",
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: pkg.features.entries
                .where((entry) => entry.value)
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
        Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 3),
        Text(value, style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildFeatureBadge(String featureKey) {
    String label = featureKey.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neonGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 8, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showPackageForm(BuildContext context, WidgetRef ref, {PackageModel? existingPkg}) {
    final nameC = TextEditingController(text: existingPkg?.name ?? '');
    final priceC = TextEditingController(text: existingPkg?.price.toStringAsFixed(0) ?? '0');
    final durationC = TextEditingController(text: existingPkg?.durationDays.toString() ?? '30');
    final refBonusC = TextEditingController(text: existingPkg?.referralRewardDays.toString() ?? '1');

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
      'auto_clicker': existingPkg?.features['auto_clicker'] ?? false,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.9,
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
                          style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField("Package Name", nameC),
                            const SizedBox(height: 10),
                            _buildInputField("Price (Rp)", priceC, isNumber: true),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildInputField("Duration (Days)", durationC, isNumber: true)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildInputField("Referral Bonus (Days)", refBonusC, isNumber: true)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "FEATURE ACCESS",
                              style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            ...featureState.keys.map((key) {
                              return SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  key.replaceAll('_', ' ').toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: featureState[key]! ? AppColors.neonGreen : AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                value: featureState[key]!,
                                onChanged: (val) {
                                  setModalState(() { featureState[key] = val; });
                                },
                              );
                            }).toList(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final price = double.tryParse(priceC.text) ?? 0;
                          final duration = int.tryParse(durationC.text) ?? 0;
                          final refBonus = int.tryParse(refBonusC.text) ?? 0;

                          PackageModel newPkg = PackageModel(
                            id: existingPkg?.id ?? '',
                            name: nameC.text,
                            price: price,
                            durationDays: duration,
                            referralRewardDays: refBonus,
                            features: featureState,
                          );

                          ref.read(packageActionProvider.notifier).savePackage(newPkg);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          "SAVE CONFIGURATION",
                          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
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

  Widget _buildInputField(String label, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
      ),
    );
  }
}
