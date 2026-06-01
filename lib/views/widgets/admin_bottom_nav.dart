import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // Base Bottom Nav (Background Hitam)
        Container(
          height: 70,
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.speed, "Dashboard", 0),
              _buildNavItem(Icons.group, "Users", 1),
              const SizedBox(width: 50), // Spasi kosong untuk tombol tengah
              _buildNavItem(Icons.account_balance_wallet, "Finance", 2),
              _buildNavItem(Icons.settings_suggest, "Config", 3),
            ],
          ),
        ),
        
        // Floating Action Button (Pengganti AX-MODE)
        Positioned(
          top: -25, // Mengangkat tombol agar overlap
          child: GestureDetector(
            onTap: () {
              // Aksi untuk tombol Quick Action (Misal memunculkan modal)
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.neonGreen,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonGreen.withOpacity(0.4), 
                    blurRadius: 20, 
                    spreadRadius: 2
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Colors.black, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "QUICK\nACTION",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      color: Colors.black, 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      height: 1.2
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            color: isActive ? AppColors.neonGreen : AppColors.textMuted, 
            size: 22
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isActive ? AppColors.neonGreen : AppColors.textMuted, 
              fontSize: 10, 
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal
            ),
          ),
        ],
      ),
    );
  }
}