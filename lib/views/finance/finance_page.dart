import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/finance_provider.dart';
import '../../models/transaction_model.dart';

class FinancePage extends ConsumerWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsStreamProvider);
    final actionState = ref.watch(financeActionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- RINGKASAN TOTAL PEMASUKAN ---
        txAsync.when(
          data: (transactions) {
            // Hitung total hanya dari transaksi yang berstatus 'paid'
            final totalIncome = transactions
                .where((tx) => tx.status == 'paid')
                .fold<double>(0, (sum, tx) => sum + tx.amount);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              // Memanfaatkan widget buatan kita sebelumnya untuk total revenue
              child: _buildTotalRevenueCard(totalIncome),
            );
          },
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppColors.neonGreen))),
          error: (_, __) => const SizedBox(),
        ),

        // --- MFW CYBERPUNK GRAPH MOCKUP ---
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _buildFinanceChartMockup(),
        ),

        // --- SECTION HEADER LIST ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Container(width: 3, height: 16, color: AppColors.neonGreen),
              const SizedBox(width: 8),
              Text("TRANSACTION LOGS", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        if (actionState is AsyncLoading)
          const LinearProgressIndicator(color: AppColors.neonGreen, backgroundColor: AppColors.background),

        // --- LIST TRANSAKSI ---
        Expanded(
          child: txAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Center(child: Text("Belum ada log transaksi masuk", style: TextStyle(color: AppColors.textMuted)));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: transactions.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildTransactionCard(context, ref, transactions[index]);
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

  // Widget Kartu Total Pendapatan
  Widget _buildTotalRevenueCard(double total) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("TOTAL CASH INFLOW", style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const Icon(Icons.account_balance_wallet, color: AppColors.neonGreen, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(formatter.format(total), style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Widget Tampilan Log Transaksi per Baris
  Widget _buildTransactionCard(BuildContext context, WidgetRef ref, TransactionModel tx) {
    bool isPaid = tx.status == 'paid';
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.userEmail, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    "${tx.packageName.toUpperCase()} PACKAGE", 
                    style: GoogleFonts.orbitron(color: isPaid ? AppColors.neonGreen : Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatter.format(tx.amount), style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt), style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
                ],
              )
            ],
          ),
          if (!isPaid) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: AppColors.border, height: 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 12),
                    const SizedBox(width: 4),
                    Text("WAITING CONFIRMATION", style: GoogleFonts.orbitron(color: Colors.amberAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
                // Tombol Konfirmasi Pembayaran Sukses
                GestureDetector(
                  onTap: () => ref.read(financeActionProvider.notifier).confirmTransaction(tx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.neonGreen, borderRadius: BorderRadius.circular(4)),
                    child: Text("CONFIRM PAID", style: GoogleFonts.orbitron(color: AppColors.background, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            )
          ]
        ],
      ),
    );
  }
}

// --- SUB WIDGET: GRAPH MOCKUP (Murni UI Container) ---
class _buildFinanceChartMockup extends StatelessWidget {
  const _buildFinanceChartMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("WEEKLY PERFORMANCE OVERVIEW", style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(40, "Mon"),
              _bar(70, "Tue"),
              _bar(55, "Wed"),
              _bar(110, "Thu", isHighest: true), // Puncak omset neon menyala
              _bar(85, "Fri"),
              _bar(45, "Sat"),
              _bar(30, "Sun"),
            ],
          )
        ],
      ),
    );
  }

  Widget _bar(double height, String day, {bool isHighest = false}) {
    return Column(
      children: [
        Container(
          width: 14,
          height: height,
          decoration: BoxDecoration(
            color: isHighest ? AppColors.neonGreen : AppColors.border,
            borderRadius: BorderRadius.circular(3),
            boxShadow: isHighest ? [BoxShadow(color: AppColors.neonGreen.withOpacity(0.3), blurRadius: 8)] : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 8)),
      ],
    );
  }
}