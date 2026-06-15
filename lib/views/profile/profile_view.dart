import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../login/login_page.dart';
import '../widgets/neon_loading.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final pkgAsync = ref.watch(currentPackageProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 120, // Adjust for top/bottom padding
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "USER PROFILE",
                style: GoogleFonts.inter(
                  color: AppColors.neonGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 16),
                ),
              )
            ],
          ),
          const SizedBox(height: 18),

          // User Info Card
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox();
              
              final now = DateTime.now();
              final remainingDays = user.activeUntil?.difference(now).inDays ?? 0;
              final isExpired = remainingDays <= 0;

              return Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(color: AppColors.neonGreen.withOpacity(0.03), blurRadius: 20),
                            ...AppColors.cardShadow(),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(Icons.email_outlined, "EMAIL", user.email),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: AppColors.border.withOpacity(0.5)),
                            ),
                            _buildInfoRow(Icons.confirmation_number_outlined, "REFERRAL", user.referralCode),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: AppColors.border.withOpacity(0.5)),
                            ),
                            _buildInfoRow(
                              Icons.timer_outlined,
                              "SUBSCRIPTION",
                              isExpired ? "EXPIRED" : "$remainingDays Days Left",
                              valueColor: isExpired ? Colors.redAccent : AppColors.neonGreen,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 32,
                        child: Container(
                          width: 3,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonGreen,
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Package Info Card
                  pkgAsync.when(
                    data: (pkg) {
                      if (pkg == null) return const SizedBox();
                      return Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.neonGreen.withOpacity(0.2)),
                              boxShadow: [
                                BoxShadow(color: AppColors.neonGreen.withOpacity(0.04), blurRadius: 24),
                                ...AppColors.cardShadow(),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "ACTIVE PACKAGE",
                                      style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(Icons.layers_outlined, "TIER", pkg.name),
                                const SizedBox(height: 8),
                                _buildInfoRow(Icons.payments_outlined, "PRICE", "Rp ${pkg.price.toStringAsFixed(0)}"),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 32,
                            child: Container(
                              width: 3,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.neonGreen,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.neonGreen,
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Padding(padding: EdgeInsets.all(20), child: NeonLoading()),
                    error: (e, _) => const SizedBox(),
                  ),
                ],
              );
            },
            loading: () => const NeonLoading(message: "Memuat profil..."),
            error: (e, _) => Center(child: Text("Error: $e", style: TextStyle(color: Colors.redAccent))),
          ),
          
          const Spacer(),
          const SizedBox(height: 30),
          
          // Logout Button
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
              icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 16),
              label: Text(
                "LOGOUT",
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.12),
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                ),
                elevation: 0,
              ),
            ),
          )
        ],
      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.textMuted, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(color: valueColor ?? AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
