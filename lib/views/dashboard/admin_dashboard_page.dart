import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/admin_bottom_nav.dart';
import '../users/user_management_page.dart'; // Import halaman user mgmt
import '../finance/finance_page.dart'; // Import halaman finance
import '../config/config_page.dart'; // Import config page

import 'package:firebase_auth/firebase_auth.dart';
import '../login/login_page.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Dengar kalkulasi data dinamis dari provider
    final stats = ref.watch(dashboardStatsProvider);

    final List<Widget> adminMenus = [
      _buildHomeView(stats),           // Index 0: Dashboard Home
      const UserManagementPage(),       // Index 1: Manajemen User (Dinamis)
      const FinancePage(),              // Index 2: Keuangan (Sudah Terhubung)
      const ConfigPage(),               // Index 3: Config Fitur
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: adminMenus,
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

  // --- VIEW KONTEN UTAMA HOME ---
  Widget _buildHomeView(DashboardStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildMainAnalyticCard(stats.conversionRate),
          const SizedBox(height: 15),
          _buildStatsGrid(stats),
          const SizedBox(height: 25),
          _buildActionCenter(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.admin_panel_settings, color: AppColors.textWhite, size: 20),
          ),
          Text(
            "MFW ADMIN PANEL",
            style: GoogleFonts.orbitron(
              color: AppColors.neonGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              shadows: [Shadow(color: AppColors.neonGreen.withOpacity(0.5), blurRadius: 10)],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.notifications_active, color: AppColors.textWhite, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAnalyticCard(double rate) {
    // Normalisasi nilai double untuk lingkaran progress (0.0 sampai 1.0)
    double progressValue = (rate / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 160, height: 160,
              child: CircularProgressIndicator(
                value: progressValue,
                strokeWidth: 8,
                color: AppColors.neonGreen,
                backgroundColor: AppColors.border,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rate.toStringAsFixed(0), style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 42, fontWeight: FontWeight.bold)),
                    Text("%", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text("VIP CONVERSION", style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1.5)),
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
              _buildMiniStatCard(Icons.group, "TOTAL USERS", "${stats.totalUsers}", "Acct", Colors.lightBlueAccent),
              const SizedBox(height: 15),
              _buildMiniStatCard(Icons.workspace_premium, "ACTIVE VIP", "${stats.activeVip}", "Acct", AppColors.neonGreen),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            height: 215, 
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.attach_money, color: AppColors.textMuted, size: 20),
                    Text("REVENUE", style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Rp ${(stats.totalRevenue / 1000000).toStringAsFixed(1)}M", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 32, fontWeight: FontWeight.bold)),
                    Text("ESTIMATED VALUE", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(IconData icon, String title, String value, String unit, Color color) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Text(title, style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
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
                Container(width: 3, height: 16, color: AppColors.neonGreen),
                const SizedBox(width: 8),
                Text("ACTION CENTER", style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
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
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 4),
                    Text("LOGOUT", style: GoogleFonts.orbitron(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionIcon(Icons.person_add, "ADD USER", Colors.blueAccent),
            _buildActionIcon(Icons.qr_code, "GEN REFERRAL", Colors.orangeAccent),
            _buildActionIcon(Icons.settings_applications, "GLOBAL CONFIG", Colors.purpleAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String name, Color bgColor) {
    return Column(
      children: [
        Container(
          width: 65, height: 65,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(name, style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.5;
    const double spacing = 25.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1.5, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}