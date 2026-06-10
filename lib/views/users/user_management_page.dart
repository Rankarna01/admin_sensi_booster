import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_management_provider.dart';
import '../../models/user_model.dart';
import '../../providers/package_provider.dart';
import '../../models/package_model.dart';
import 'user_detail_page.dart';
import '../widgets/neon_loading.dart';

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
                  Container(width: 2, height: 14, color: AppColors.neonGreen),
                  const SizedBox(width: 8),
                  Text(
                    "USER DATABASE",
                    style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showRegisterModal(context, ref, packages),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: AppColors.glowGreen(blur: 16, opacity: 0.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.black, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "NEW USER",
                        style: GoogleFonts.inter(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3),
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
            child: LinearProgressIndicator(
              color: AppColors.neonGreen,
              backgroundColor: AppColors.surface,
              minHeight: 2,
            ),
          ),

        Expanded(
          child: usersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const Center(child: NeonLoading(message: "Belum ada user terdaftar"));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: users.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildUserListItem(context, users[index]);
                },
              );
            },
            loading: () => const NeonLoading(message: "Memuat data..."),
            error: (err, _) => Center(child: Text("Error: $err", style: TextStyle(color: Colors.redAccent))),
          ),
        ),
      ],
    );
  }

  Widget _buildUserListItem(BuildContext context, UserModel user) {
    Color tierColor = AppColors.textMuted;
    if (user.statusVip == 'standard') tierColor = Colors.lightBlueAccent;
    if (user.statusVip == 'super_vip') tierColor = AppColors.neonGreen;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailPage(user: user)));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.email,
                    style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tierColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.statusVip.toUpperCase(),
                          style: GoogleFonts.inter(color: tierColor, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 4, height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: user.paymentStatus == 'paid' ? AppColors.neonGreen : Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.paymentStatus.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: user.paymentStatus == 'paid' ? AppColors.neonGreen : Colors.redAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  void _showRegisterModal(BuildContext context, WidgetRef ref, List<PackageModel> packages) {
    final TextEditingController emailC = TextEditingController();
    final TextEditingController passC = TextEditingController();
    PackageModel? selectedPackage = packages.isNotEmpty ? packages.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "REGISTER CLIENT",
                    style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: emailC,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Client Email",
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passC,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PackageModel>(
                    value: selectedPackage,
                    dropdownColor: AppColors.card,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Package Tier",
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                    ),
                    items: packages.map((pkg) {
                      return DropdownMenuItem<PackageModel>(
                        value: pkg,
                        child: Text(pkg.name.toUpperCase(), style: GoogleFonts.inter(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedPackage = val),
                  ),
                  const SizedBox(height: 24),
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
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedPackage != null ? AppColors.neonGreen : AppColors.textMuted,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        "CREATE ACCOUNT",
                        style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            );
          }
        );
      },
    );
  }
}
