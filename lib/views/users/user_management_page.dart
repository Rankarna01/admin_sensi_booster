import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_management_provider.dart';
import '../../models/user_model.dart';
import '../../providers/package_provider.dart';
import '../../models/package_model.dart';
import 'user_detail_page.dart'; // Import halaman detail

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersStreamProvider);
    final actionState = ref.watch(userActionProvider);
    final packages = ref.watch(packageStreamProvider).value ?? [];

    ref.listen(userActionProvider, (previous, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Aksi Gagal: $err"), backgroundColor: Colors.redAccent),
        ),
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
                  Text("USER DATABASE", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              // Tombol Register User Baru
              GestureDetector(
                onTap: () => _showRegisterModal(context, ref, packages),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: Colors.black, size: 14),
                      const SizedBox(width: 4),
                      Text("NEW USER", style: GoogleFonts.orbitron(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
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
          child: usersAsync.when(
            data: (users) {
              if (users.isEmpty) return const Center(child: Text("Belum ada user", style: TextStyle(color: AppColors.textMuted)));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: users.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildUserListItem(context, users[index]);
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

  // Desain List Item Sederhana
  Widget _buildUserListItem(BuildContext context, UserModel user) {
    Color tierColor = AppColors.textMuted;
    if (user.statusVip == 'standard') tierColor = Colors.lightBlueAccent;
    if (user.statusVip == 'super_vip') tierColor = AppColors.neonGreen;

    return GestureDetector(
      onTap: () {
        // Navigasi ke Halaman Detail
        Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailPage(user: user)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text("TIER: ${user.statusVip.toUpperCase()}", style: GoogleFonts.orbitron(color: tierColor, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text(
                      user.paymentStatus == 'paid' ? "• PAID" : "• UNPAID", 
                      style: GoogleFonts.inter(color: user.paymentStatus == 'paid' ? AppColors.neonGreen : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  // Modal Pop-Up Registrasi
  void _showRegisterModal(BuildContext context, WidgetRef ref, List<PackageModel> packages) {
    final TextEditingController emailC = TextEditingController();
    final TextEditingController passC = TextEditingController();
    PackageModel? selectedPackage = packages.isNotEmpty ? packages.first : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("REGISTER CLIENT ACCOUNT", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailC,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Client Email", labelStyle: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passC,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Password", labelStyle: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<PackageModel>(
                    value: selectedPackage,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Package Tier", labelStyle: TextStyle(color: AppColors.textMuted)),
                    items: packages.map((pkg) {
                      return DropdownMenuItem<PackageModel>(
                        value: pkg,
                        child: Text(pkg.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedPackage = val),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedPackage == null ? null : () {
                        ref.read(userActionProvider.notifier).registerNewUser(
                          emailC.text, 
                          passC.text, 
                          selectedPackage!.name.toLowerCase(),
                          selectedPackage!.durationDays,
                          selectedPackage!.price
                        );
                        Navigator.pop(context); // Tutup modal
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedPackage != null ? AppColors.neonGreen : AppColors.textMuted
                      ),
                      child: Text("CREATE ACCOUNT", style: GoogleFonts.orbitron(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      },
    );
  }
}