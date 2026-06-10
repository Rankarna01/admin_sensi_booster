import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/admin_bottom_nav.dart';
import '../users/user_management_page.dart';
import '../finance/finance_page.dart';
import '../config/config_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login/login_page.dart';
import '../widgets/base_layout.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);

    final List<Widget> adminMenus = [
      _buildHomeView(stats),
      const UserManagementPage(),
      const FinancePage(),
      const ConfigPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
          
          // Ambient glow top-right
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.neonGreen.withOpacity(0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    child: IndexedStack(
                      key: ValueKey<int>(_currentIndex),
                      index: _currentIndex,
                      children: adminMenus,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AdminBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView(DashboardStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildMainAnalyticCard(stats.conversionRate),
          const SizedBox(height: 12),
          _buildStatsGrid(stats),
          const SizedBox(height: 22),
          _buildActionCenter(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow(),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.textMuted, size: 18),
          ),
          Text(
            "MFW ADMIN",
            style: GoogleFonts.orbitron(
              color: AppColors.neonGreen,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              shadows: [
                Shadow(color: AppColors.neonGreen.withOpacity(0.3), blurRadius: 12),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow(),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: AppColors.textMuted, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAnalyticCard(double rate) {
    double progressValue = (rate / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withOpacity(0.04),
            blurRadius: 30,
            spreadRadius: 0,
          ),
          ...AppColors.cardShadow(),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140, height: 140,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progressValue),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    color: AppColors.neonGreen,
                    backgroundColor: AppColors.border.withOpacity(0.3),
                    strokeCap: StrokeCap.round,
                  );
                },
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rate.toStringAsFixed(0),
                      style: GoogleFonts.orbitron(
                        color: AppColors.neonGreen,
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: AppColors.neonGreen.withOpacity(0.3), blurRadius: 10)],
                      ),
                    ),
                    Text(
                      "%",
                      style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  "VIP CONVERSION",
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildMiniStatCard(Icons.people_outline_rounded, "TOTAL USERS", "${stats.totalUsers}", Colors.lightBlueAccent),
              const SizedBox(height: 12),
              _buildMiniStatCard(Icons.workspace_premium_rounded, "ACTIVE VIP", "${stats.activeVip}", AppColors.neonGreen),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.attach_money_rounded, color: AppColors.textMuted, size: 18),
                    Text(
                      "REVENUE",
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rp ${(stats.totalRevenue / 1000000).toStringAsFixed(1)}M",
                      style: GoogleFonts.orbitron(
                        color: AppColors.textWhite,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "ESTIMATED VALUE",
                      style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(IconData icon, String title, String value, Color color) {
    return Container(
      height: 94,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 16),
              Text(
                title,
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCenter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 2, height: 14, color: AppColors.neonGreen),
                const SizedBox(width: 8),
                Text(
                  "ACTION CENTER",
                  style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            GestureDetector(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      "LOGOUT",
                      style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionIcon(Icons.person_add_alt_rounded, "ADD USER", Colors.blueAccent),
            _buildActionIcon(Icons.qr_code_2_rounded, "REFERRAL", Colors.orangeAccent),
            _buildActionIcon(Icons.settings_outlined, "CONFIG", Colors.purpleAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String name, Color bgColor) {
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bgColor.withOpacity(0.3)),
          ),
          child: Icon(icon, color: bgColor, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w500, letterSpacing: 0.3),
        ),
      ],
    );
  }
}
