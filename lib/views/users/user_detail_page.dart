import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_management_provider.dart';
import '../../models/user_model.dart';
import '../widgets/base_layout.dart'; // Grid background
import '../../providers/package_provider.dart';

class UserDetailPage extends ConsumerWidget {
  final UserModel user;

  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 0. Ambil list user dari stream, cari user yang uid-nya sama agar tampilannya reactive!
    final usersAsync = ref.watch(usersStreamProvider);
    final currentUser = usersAsync.value?.firstWhere(
      (u) => u.uid == user.uid,
      orElse: () => user,
    ) ?? user;

    return BaseLayout(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Transparan agar BaseLayout terlihat
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.neonGreen),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("USER DETAILS", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. INFO CARD
              _buildSectionTitle("ACCOUNT INFO"),
              _buildInfoCard(currentUser),
              const SizedBox(height: 30),
              
              // 2. PACKAGE CONFIGURATION
              _buildSectionTitle("PACKAGE SUBSCRIPTION"),
              _buildPackageControl(context, ref, currentUser),
              const SizedBox(height: 30),
              
              // 3. PAYMENT CONFIRMATION
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
          Container(width: 3, height: 14, color: AppColors.neonGreen),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("EMAIL", user.email),
          const Divider(color: AppColors.border, height: 20),
          _infoRow("UID", user.uid),
          const Divider(color: AppColors.border, height: 20),
          _infoRow("HARDWARE ID", user.deviceId.isEmpty ? "Not Bounded" : user.deviceId),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 9)),
        Text(value, style: const TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPackageControl(BuildContext context, WidgetRef ref, UserModel user) {
    final pkgAsync = ref.watch(packageStreamProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: pkgAsync.when(
        data: (packages) {
          if (packages.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Belum ada data paket. Silakan tambahkan di menu Global Config.", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            );
          }
          return Column(
            children: packages.asMap().entries.map((entry) {
              int index = entry.key;
              var pkg = entry.value;
              return Column(
                children: [
                  _buildRadioOption(ref, pkg.name, pkg.name, user.statusVip, user.uid),
                  if (index < packages.length - 1) const Divider(color: AppColors.border, height: 1),
                ],
              );
            }).toList(),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Text("Error: $e", style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _buildRadioOption(WidgetRef ref, String title, String value, String groupValue, String uid) {
    bool isSelected = value == groupValue;
    return RadioListTile<String>(
      title: Text(title, style: TextStyle(color: isSelected ? AppColors.neonGreen : AppColors.textWhite, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("PAYMENT STATUS", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                isPaid ? "Payment Confirmed" : "Waiting for Payment",
                style: TextStyle(color: isPaid ? AppColors.neonGreen : Colors.redAccent, fontSize: 10),
              ),
            ],
          ),
          Switch(
            value: isPaid,
            activeColor: AppColors.neonGreen,
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