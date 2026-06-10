import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_management_provider.dart';
import '../../models/user_model.dart';
import '../widgets/base_layout.dart';
import '../../providers/package_provider.dart';
import '../widgets/neon_loading.dart';

class UserDetailPage extends ConsumerWidget {
  final UserModel user;

  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersStreamProvider);
    final currentUser = usersAsync.value?.firstWhere(
      (u) => u.uid == user.uid,
      orElse: () => user,
    ) ?? user;

    return BaseLayout(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neonGreen, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "USER DETAILS",
            style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("ACCOUNT INFO"),
              _buildInfoCard(currentUser),
              const SizedBox(height: 24),
              _buildSectionTitle("PACKAGE SUBSCRIPTION"),
              _buildPackageControl(context, ref, currentUser),
              const SizedBox(height: 24),
              _buildSectionTitle("FINANCE & PAYMENT"),
              _buildPaymentControl(context, ref, currentUser),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 2, height: 12, color: AppColors.neonGreen),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withOpacity(0.03),
            blurRadius: 20,
          ),
          ...AppColors.cardShadow(),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("EMAIL", user.email),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.border.withOpacity(0.5)),
          ),
          _infoRow("UID", user.uid),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.border.withOpacity(0.5)),
          ),
          _infoRow("HARDWARE ID", user.deviceId.isEmpty ? "Not Bounded" : user.deviceId),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPackageControl(BuildContext context, WidgetRef ref, UserModel user) {
    final pkgAsync = ref.watch(packageStreamProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow(),
      ),
      child: pkgAsync.when(
        data: (packages) {
          if (packages.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                "Belum ada data paket.",
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
              ),
            );
          }
          return Column(
            children: packages.asMap().entries.map((entry) {
              int index = entry.key;
              var pkg = entry.value;
              return Column(
                children: [
                  _buildRadioOption(ref, pkg.name, pkg.name, user.statusVip, user.uid),
                  if (index < packages.length - 1) Divider(color: AppColors.border.withOpacity(0.5), height: 1),
                ],
              );
            }).toList(),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: NeonLoading(),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(18),
          child: Text("Error: $e", style: TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _buildRadioOption(WidgetRef ref, String title, String value, String groupValue, String uid) {
    bool isSelected = value == groupValue;
    return RadioListTile<String>(
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: isSelected ? AppColors.neonGreen : AppColors.textWhite,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
      ),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.neonGreen,
      onChanged: (val) {
        if (val != null) {
          ref.read(userActionProvider.notifier).updateVipStatus(uid, val);
        }
      },
    );
  }

  Widget _buildPaymentControl(BuildContext context, WidgetRef ref, UserModel user) {
    bool isPaid = user.paymentStatus == 'paid';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPaid ? AppColors.neonGreen.withOpacity(0.2) : AppColors.border),
        boxShadow: isPaid
            ? [BoxShadow(color: AppColors.neonGreen.withOpacity(0.04), blurRadius: 20)]
            : AppColors.cardShadow(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "PAYMENT STATUS",
                style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPaid ? AppColors.neonGreen : Colors.redAccent,
                      boxShadow: isPaid
                          ? [BoxShadow(color: AppColors.neonGreen.withOpacity(0.5), blurRadius: 6)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPaid ? "Confirmed" : "Waiting",
                    style: GoogleFonts.inter(
                      color: isPaid ? AppColors.neonGreen : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: isPaid,
            activeColor: AppColors.background,
            activeTrackColor: AppColors.neonGreen,
            inactiveThumbColor: Colors.redAccent,
            onChanged: (val) {
              ref.read(userActionProvider.notifier).updatePaymentStatus(user.uid, val ? 'paid' : 'unpaid');
            },
          ),
        ],
      ),
    );
  }
}
