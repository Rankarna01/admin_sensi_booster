import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/finance_provider.dart';
import '../../models/transaction_model.dart';
import '../widgets/neon_loading.dart';

class FinancePage extends ConsumerWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsStreamProvider);
    final actionState = ref.watch(financeActionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- TOTAL REVENUE ---
        txAsync.when(
          data: (transactions) {
            final totalIncome = transactions
                .where((tx) => tx.status == 'paid')
                .fold<double>(0, (sum, tx) => sum + tx.amount);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildTotalRevenueCard(totalIncome),
            );
          },
          loading: () => const SizedBox(height: 100, child: NeonLoading()),
          error: (_, __) => const SizedBox(),
        ),

        // --- CHART MOCKUP ---
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _FinanceChartMockup(),
        ),

        // --- SECTION HEADER ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(width: 2, height: 14, color: AppColors.neonGreen),
              const SizedBox(width: 8),
              Text(
                "TRANSACTION LOGS",
                style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ],
          ),
        ),

        if (actionState is AsyncLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: LinearProgressIndicator(color: AppColors.neonGreen, backgroundColor: AppColors.surface, minHeight: 2),
          ),

        // --- LIST TRANSAKSI ---
        Expanded(
          child: txAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Center(child: NeonLoading(message: "Belum ada transaksi"));
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
            loading: () => const NeonLoading(message: "Memuat transaksi..."),
            error: (err, _) => Center(child: Text("Error: $err", style: TextStyle(color: Colors.redAccent))),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRevenueCard(double total) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.neonGreen.withOpacity(0.04), blurRadius: 24),
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
                "TOTAL CASH INFLOW",
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.neonGreen, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatter.format(total),
            style: GoogleFonts.orbitron(
              color: AppColors.textWhite,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: AppColors.neonGreen.withOpacity(0.2), blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, WidgetRef ref, TransactionModel tx) {
    bool isPaid = tx.status == 'paid';
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPaid ? AppColors.neonGreen.withOpacity(0.15) : AppColors.border),
        boxShadow: AppColors.cardShadow(),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.userEmail,
                      style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w600, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${tx.packageName.toUpperCase()} PACKAGE",
                      style: GoogleFonts.inter(
                        color: isPaid ? AppColors.neonGreen : Colors.amberAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(tx.amount),
                    style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('dd MMM yyyy').format(tx.createdAt),
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w400),
                  ),
                ],
              )
            ],
          ),
          if (!isPaid) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: AppColors.border.withOpacity(0.5)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amberAccent,
                        boxShadow: [BoxShadow(color: Colors.amberAccent.withOpacity(0.5), blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "WAITING",
                      style: GoogleFonts.inter(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => ref.read(financeActionProvider.notifier).confirmTransaction(tx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: AppColors.glowGreen(blur: 12, opacity: 0.15),
                    ),
                    child: Text(
                      "CONFIRM",
                      style: GoogleFonts.inter(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                    ),
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

class _FinanceChartMockup extends StatelessWidget {
  const _FinanceChartMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "WEEKLY OVERVIEW",
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(35, "Mon"),
              _bar(65, "Tue"),
              _bar(50, "Wed"),
              _bar(100, "Thu", isHighest: true),
              _bar(75, "Fri"),
              _bar(40, "Sat"),
              _bar(28, "Sun"),
            ],
          )
        ],
      ),
    );
  }

  Widget _bar(double height, String day, {bool isHighest = false}) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 12,
          height: height,
          decoration: BoxDecoration(
            color: isHighest ? AppColors.neonGreen : AppColors.border.withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isHighest
                ? [BoxShadow(color: AppColors.neonGreen.withOpacity(0.3), blurRadius: 10)]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}
