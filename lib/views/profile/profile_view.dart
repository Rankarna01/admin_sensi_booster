import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../login/login_page.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final pkgAsync = ref.watch(currentPackageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "USER PROFILE",
                style: GoogleFonts.orbitron(
                  color: AppColors.neonGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                tooltip: "Logout",
              )
            ],
          ),
          const SizedBox(height: 20),

          // User Info Card
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox();
              
              // Calculate remaining days
              final now = DateTime.now();
              final remainingDays = user.activeUntil?.difference(now).inDays ?? 0;
              final isExpired = remainingDays <= 0;

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.email, "EMAIL", user.email),
                        const Divider(color: AppColors.border, height: 30),
                        _buildInfoRow(Icons.confirmation_number, "REFERRAL CODE", user.referralCode),
                        const Divider(color: AppColors.border, height: 30),
                        _buildInfoRow(
                          Icons.timer, 
                          "SUBSCRIPTION", 
                          isExpired ? "EXPIRED" : "$remainingDays Days Left",
                          valueColor: isExpired ? Colors.redAccent : AppColors.neonGreen,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Package Info Card
                  pkgAsync.when(
                    data: (pkg) {
                      if (pkg == null) return const SizedBox();
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.orangeAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "ACTIVE PACKAGE",
                                  style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            _buildInfoRow(Icons.layers, "TIER NAME", pkg.name),
                            const SizedBox(height: 15),
                            _buildInfoRow(Icons.attach_money, "PRICE", "Rp ${pkg.price.toStringAsFixed(0)}"),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),
                    error: (e, _) => const SizedBox(),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),
            error: (e, _) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.redAccent))),
          ),
          
          const SizedBox(height: 40),
          
          // Logout Button (Large)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.power_settings_new, color: Colors.white),
              label: Text("LOGOUT SYSTEM", style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: valueColor ?? AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
